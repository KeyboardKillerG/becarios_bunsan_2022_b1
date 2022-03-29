defmodule InvoiceValidator do
  def validate_dates(%DateTime{} = emisor_dt, %DateTime{} = pac_dt) do   
    case DateTime.compare(emisor_dt, pac_dt) do 
      :gt ->
        cond do
          DateTime.diff(emisor_dt, pac_dt) <= 300 ->
            :ok
          true ->
            "Invoice is more than 5 mins ahead in time"
        end
      :lt ->
        cond do
          DateTime.diff(pac_dt, emisor_dt) <= 259200 ->
            :ok
          true -> 
            "Invoice was issued more than 72 hrs before received by the PAC"
        end
      :eq ->
        :ok
        
    end
  end
end

