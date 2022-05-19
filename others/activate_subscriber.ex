defmodule Provisioning.Workflow.ActivateSubscriber do
  @moduledoc """
  This module handle the logic for and activation of subscriber MiFi

  It allow, multiple activations associated to a one user.
  """
  require Logger
  alias Ecto.Multi

  alias Adm.{Inventory, Mvno, Offers, Subscriber}
  alias Adm.Inventory.Schema.Sim
  alias Adm.Offers.MvnoPackage
  alias Adm.Subscriber.Schema.{Account, Activation, Line}

  alias Altan.Commons.{Security, Utils.FormatDates}
  alias Altan.IntegrationC
  alias Notification.SMS.Service

  @defaults %{
    sms_notification: Application.get_env(:provisioning, :sms_notification, false)
  }

  def activate(
        %{
          msisdn: msisdn,
          address: address,
          package_id: package_id,
          mvno_id: mvno_id,
          name: _name,
          email: _email,
          phone: _phone,
          phone_type: _phone_type
        } = input,
        opts
      ) do
    opts = Map.merge(@defaults, opts)
    coordinates = Map.get(input, :coordinates, "")

    subscriber_line_params = %{
      msisdn: msisdn,
      coordinates: coordinates,
      address: address,
      package_id: package_id,
      mvno_id: mvno_id
    }

    Multi.new()
    |> Multi.run(:sim_card, fn data = %{msisdn: _msisdn, mvno_id: _mvno_id} ->
        assign_sim_card(data)
      end)
    |> Multi.run(:mvno_package, get_mvno_package(input))
    |> Multi.run(:account, fn repo, %{mvno_package: mvno_package} ->
        get_account(repo, mvno_package, input)
      end)
    |> Multi.run(:activation_ids_with_validity, fn %{mvno_package: mvno_package} ->
        get_activation_ids(mvno_package)
      end)
    |> Multi.run(:subscriber_line, fn repo, data = %{
                                              activation_ids_with_validity: _aids,
                                              account: _account,
                                              mvno_package: _mvno_package
                                            } ->
        activate_suscriber(repo, input, subscriber_line_params, data)
      end)
    |> Multi.run(:account_validity, fn %{account: account, subscriber_line: line} ->
        Subscriber.update_account(account, %{valid_from: line.from_date, valid_to: line.to_date})
      end)
    |> Multi.run(:activations, fn repo, data = %{
                                          activation_ids_with_validity: _ids,
                                          account: _account,
                                          subscriber_line: _subscriber_line,
                                          sim_card: _sim,
                                          mvno_package: _mvno_package
                                        }->
                                          validate_activation(repo, input, data) end)
    |> Multi.run(:altan, fn _repo, data -> altan_activation(data) end)
    |> Multi.run(:complete_activation, fn _repo , data = %{altan: _altan, activations: _activations} -> complete_altan_activation(data) end)
    |> Multi.run(:order, fn _repo, data = %{altan: _altan, subscriber_line: _line} ->
        create_order(data)
      end)
    |> Adm.Repo.transaction()
    |> response_with_sms(input, opts)
  end

  # privates
  defp existing_account(nil, input, mvno_package) do
    Account.create_changeset(%Account{}, get_account_body(input, mvno_package))
  end

  defp existing_account(%Account{} = account, _input, _mvno_package), do: account

  defp get_account_body(input, mvno_package) do
    now =
      Map.get(input, :start_date, Timex.now())
      |> DateTime.truncate(:second)

    # %{mvno_id: 9, package_id: 37}
    mvno = Mvno.get_profile!(input.mvno_id)
    address = Map.get(input, :address, "")

    %{
      address: address,
      account_name: input.name,
      account_email: input.email,
      account_phone: input.phone,
      account_phone_type: input.phone_type,
      # mvno_package.price, NOTE: in the next step I need to accept a reference_id to build the purchase process.
      balance: Money.new(0),
      mvno_package: mvno_package,
      mvno: mvno,
      valid_from: now
    }
  end

  defp get_activation_ids(nil), do: {:error, "The mvno has not an associated package"}

  defp get_activation_ids(%MvnoPackage{} = valid_package) do
    package_fill = valid_package |> Adm.Repo.preload([{:package, :modules}])
    # should add another field to identtify during the purchase maybe is the provider
    # of the plan but i'm thinking about.
    activation_ids =
      package_fill.package.modules
      |> Enum.filter(fn m -> m.is_active end)
      |> Enum.map(fn m -> {m.activation_id, m.validity, m.rated_as} end)

    {:ok, activation_ids}
  end

  defp is_activation_valid(changesets, repo) do
    errors? = changesets |> Enum.filter(fn a -> a.valid? == false end)

    case errors? |> length do
      0 ->
        {:ok,
         changesets
         |> Enum.map(fn c ->
           {:ok, obj} =
             c
             |> repo.insert()

           obj
         end)}

      _ ->
        {:error, errors?}
    end
  end

  defp altan_response(response, 200), do: %{valid?: true, response: response.body}
  defp altan_response(response, _status), do: %{valid?: false, response: response.body}

  defp do_altan_activations(activations, rated_as, service) do
    token =
      case service do
        "mifi" -> Security.get_mifi_token()
        "mobility" -> Security.get_mobility_token()
        _ -> Security.get_token()
      end

    activations
    |> Enum.map(fn a ->
      body = build_activation_body(a, rated_as)

      response =
        case Application.get_env(:provisioning, :async, false) do
          true -> IntegrationC.post_action(token, body, a.msisdn, :activate)
          false -> IntegrationC.post_action(token, body, a.msisdn, :activate, :infinity)
        end

      {altan_response(response, response.status_code), body, a.msisdn}
    end)
  end

  # since the %Activation{} has start_date and it wasn't set the value is null by default.
  defp build_activation_body(
         %Activation{
           activation_id: offering_id,
           validity: validity,
           start_date: start_date
         },
         "package" = _rated_as
       )
       when not is_nil(start_date) do
    {start_date, end_date} = start_date |> FormatDates.get_start_end_date(validity)

    body = %{
      "offeringId" => "#{offering_id}",
      "startEffectiveDate" => FormatDates.date_to_altan_format(start_date),
      "expireEffectiveDate" => FormatDates.date_to_altan_format(end_date)
    }

    Logger.info(fn -> "Body for package rated as `package` for mobility" end)
    Logger.debug(fn -> inspect(body, pretty: true) end)
    body
  end

  defp build_activation_body(%Activation{activation_id: offering_id}, "bulk") do
    body = %{
      "offeringId" => "#{offering_id}"
    }

    Logger.info(fn -> "Body for package rated as `bulk` for mobility" end)
    Logger.debug(fn -> inspect(body, pretty: true) end)
    body
  end

  defp get_order_activation(
         %{
           asyncOrder: %{"id" => order_id},
           effectiveDate: effective_date,
           msisdn: msisdn,
           offeringId: offering_id
         },
         line_id
       ) do
    # async payload
    # %{
    #   asyncOrder: %{"id" => "390"},
    #   effectiveDate: "20191109002241",
    #   msisdn: "4961560123",
    #   offeringId: "1719912000"
    # }
    %{
      effective_date: String.pad_trailing(effective_date, 14, "0"),
      order_id: order_id,
      status: "activate",
      processed_by: "Provisioning.Workflow.activate_mobility",
      message:
        "async: true, async_id: #{order_id}, activation_id: #{offering_id}, msisdn: #{msisdn} ",
      line_id: line_id
    }
  end

  defp get_order_activation(
         %{
           effectiveDate: effective_date,
           msisdn: msisdn,
           offeringId: offering_id,
           order: %{"id" => order_id}
         },
         line_id
       ) do
    %{
      effective_date: String.pad_trailing(effective_date, 14, "0"),
      order_id: order_id,
      status: "activate",
      processed_by: "Provisioning.Workflow.activate_mobility",
      message:
        "async: false, order_id: #{order_id}, activation_id: #{offering_id}, msisdn: #{msisdn}",
      line_id: line_id
    }
  end

  def response_with_sms({:ok, t} = transaction, %{msisdn: msisdn}, %{sms_notification: true}) do
    # load client from some configuration remember to add a flag to the mvno profile or a
    # check a better way to send the sms

    line =
      t.subscriber_line
      |> Line.preload([{:package, [{:package, :modules}], :mvno, :account}])

    account = line.account

    validity =
      line.package.package.modules
      |> Enum.filter(fn m -> m.offer_type == "primary" end)
      |> Enum.map(fn m -> m.validity end)
      |> Enum.max()

    # {"5598239418", "hbb"}, {"5598239418", "mobility"}, {"5598239418", "mifi"}
    {cell_phone, service} =
      case Inventory.get_sim_by(%{msisdn: msisdn}) do
        nil ->
          {:error, :unknown}

        %Sim{profile: profile} when profile in ["mifi", "mobility"] ->
          {account.account_phone, profile}

        %Sim{profile: profile} ->
          {line.msisdn, profile}
      end

    # Deliver sms if apply, read from configuration the provider and deliver with it
    case cell_phone do
      :error ->
        :not_sended_sms

      cell_phone ->
        message = "Bienvenido a <+B+>, se ha activado el plan <+C+> con vigencia de <+D+> días."
        campaign_name = "#{service}_activations"

        recipient = %{
          cellphone: cell_phone,
          name: line.mvno.name,
          field1: line.package.name,
          field2: "#{validity}"
        }

        Logger.info("send message using #{inspect(recipient, pretty: true)}")
        maybe_send_sms(recipient, campaign_name, message)
    end

    transaction
  end

  def response_with_sms(transaction, _params, _), do: transaction

  defp maybe_send_sms(recipient, campaign_name, message) do
    case Service.deliver(:mas_mensajes, recipient, campaign_name, message) do
      {:error, error} ->
        Logger.error("the message can't be sended, #{inspect(error)}")
        :error

      {:ok, %{message: message}} ->
        Logger.info("SMS sended, #{inspect(message)}")
        :ok
    end
  end

  def assign_sim_card(data) do
    # , status: "reserved"
    case Inventory.get_sim_by(data) do
      nil ->
        Logger.error(
          "The pre-activation fails because the sim card with msisdn #{data.msisdn} could not be found in the sim's inventory."
        )

        {:error, "The sim card for the msisdn #{data.msisdn} could not be found."}

      sim ->
        sim
        |> Inventory.Schema.Sim.preload([:provider])
        |> Inventory.assign_sim_card()
    end
  end

  def get_mvno_package(input) do
    Logger.debug(fn ->
      inspect("Get Package using: %{id: #{input.package_id}, mvno_id: #{input.mvno_id}}")
    end)

    params = %{mvno_id: input.mvno_id, id: input.package_id}

    case Offers.get_mvno_package(params) do
      nil ->
        {:error, "Package can't be found please check it, using params: #{inspect(params)}"}

      mvno_package ->
        {:ok, mvno_package}
    end
  end

  def get_account(repo, mvno_package, input) do
    account =
      %{account_email: input.email}
      |> Subscriber.get_account()
      |> existing_account(input, mvno_package)

    # There is an account or we need to create one
    case account do
      %Account{} ->
        {:ok, account}

      %Ecto.Changeset{} ->
        repo.insert(account)
    end
  end



  def activate_suscriber(repo, input, subscriber_line_params,
    %{
      activation_ids_with_validity: aids,
      account: account,
      mvno_package: mvno_package
    } ) do
    {_, validity, _rated_as} = aids |> hd

    {start_date, end_date} =
      input
      |> Map.get(:start_date, Adm.now())
      |> FormatDates.get_start_end_date(validity)

    extra_params = %{
      account_id: account.id,
      package: mvno_package,
      from_date: start_date,
      to_date: end_date
    }

    subscriber_line_params
    |> Enum.into(extra_params)
    |> Line.activate_subscriber()
    |> repo.insert()
  end

  def validate_activation(repo, input, %{
    activation_ids_with_validity: ids,
    account: account,
    subscriber_line: subscriber_line,
    sim_card: sim,
    mvno_package: mvno_package
  }) do
    {_, _validity, rated_as} = ids |> hd
    base = Enum.into(input, %{rated_as: rated_as})

    params =
      Map.merge(base, %{
        account: account,
        subscriber_line: subscriber_line,
        complete: true,
        tries: 1,
        provider: Map.from_struct(sim.provider),
        metadata: %{
          rated_as: rated_as,
          provider_name: sim.provider.name,
          service: sim.profile,
          plan_name: mvno_package.name,
          iccid: subscriber_line.iccid,
          imsi: subscriber_line.imsi,
          address: subscriber_line.address,
          subscriber_name: "#{account.account_name} #{account.account_lastname}"
        }
      })

    %Activation{}
    |> Activation.mobility_activation(ids, params)
    |> is_activation_valid(repo)
  end

  def altan_activation(data) do
    {_, _validity, rated_as} = data.activation_ids_with_validity |> hd

    activations =
      case Inventory.get_sim_by(%{msisdn: data.msisdn}) do
        nil ->
          []

        %Sim{profile: profile} when profile in ["mifi", "mobility"] ->
          do_altan_activations(data.activations, rated_as, profile)

        %Sim{profile: _profile} ->
          []
      end

    errors? = activations |> Enum.filter(fn {e, _payload, _msisdn} -> e.valid? == false end)

    case length(errors?) do
      0 ->
        responses =
          activations |> Enum.map(fn {a, payload, msisdn} -> {a.response, payload, msisdn} end)

        Logger.info("activations responses (mobility): #{inspect(responses, pretty: true)}")
        {:ok, responses}

      _ ->
        Logger.error(
          "Activation result for mobility:\n#{inspect(errors?, pretty: true, limit: :infinity)}"
        )

        Logger.info(
          "used data for activation (mobility): #{inspect(data, pretty: true, limit: :infinity)}"
        )

        {:error,
         errors? |> Enum.map(fn {e, payload, msisdn} -> {e.response, payload, msisdn} end)}
    end
  end

  def complete_altan_activation(%{altan: altan, activations: activations}) do
    Logger.info(
      "complete_activation add payload #{inspect(altan, pretty: true, limit: :infinity)}"
    )

    complete_activations =
      altan
      |> Enum.map(fn {_order, payload, msisdn} ->
        case Enum.filter(activations, &(&1.msisdn == msisdn)) do
          [activation] ->
            metadata = %{activation.metadata | payload: payload} |> Map.from_struct()

            Subscriber.update_activation(activation, %{metadata: metadata})

          _ ->
            Logger.error(
              "Something happen we can't found on activations #{inspect(activations)} the msisdn #{
                msisdn
              }"
            )

            nil
        end
      end)

    {:ok, %{complete_activation: complete_activations}}
  end

  def create_order(%{altan: altan, subscriber_line: line}) do
    Logger.info("creating order using #{inspect(altan, pretty: true, limit: :infinity)}")

    orders =
      altan
      |> Enum.map(fn {order, _payload, _msisdn} ->
        {:ok, order} =
          order
          |> Enum.into(%{})
          |> get_order_activation(line.id)
          |> Subscriber.create_order()

        order
      end)

    {:ok, %{orders: orders}}
  end
end
