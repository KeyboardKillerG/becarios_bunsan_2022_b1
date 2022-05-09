defmodule InvoiceValidator3Test do
  use ExUnit.Case, async: false
  import InvoiceValidator

  Calendar.put_time_zone_database(Tzdata.TimeZoneDatabase)

  @pac_dt DateTime.from_naive!(~N[2022-03-23 15:06:35], "America/Mexico_City")

  data = [
    {"72 hrs atras", "America/Tijuana", ~N[2022-03-20 13:06:31],
     "Invoice was issued more than 72 hrs before received by the PAC"},
    {"72 hrs atras", "America/Mazatlan", ~N[2022-03-20 14:06:31],
     "Invoice was issued more than 72 hrs before received by the PAC"},
    {"72 hrs atras", "America/Mexico_City", ~N[2022-03-20 15:06:31],
     "Invoice was issued more than 72 hrs before received by the PAC"},
    {"72 hrs atrás", "America/Cancun", ~N[2022-03-20 16:06:31],
     "Invoice was issued more than 72 hrs before received by the PAC"},
    {"72 hrs atras", "America/Tijuana", ~N[2022-03-20 13:06:35], :ok},
    {"72 hrs atras", "America/Mazatlan", ~N[2022-03-20 14:06:35], :ok},
    {"72 hrs atras", "America/Mexico_City", ~N[2022-03-20 15:06:35], :ok},
    {"72 hrs atras", "America/Cancun", ~N[2022-03-20 16:06:35], :ok},
    {"5 mns adelante", "America/Tijuana", ~N[2022-03-23 13:11:35], :ok},
    {"5 mns adelante", "America/Mazatlan", ~N[2022-03-23 14:11:35], :ok},
    {"5 mns adelante", "America/Mexico_City", ~N[2022-03-23 15:11:35], :ok},
    {"5 mns adelante", "America/Cancun", ~N[2022-03-23 16:11:35], :ok},
    {"5 mns adelante", "America/Tijuana", ~N[2022-03-23 13:11:36],
     "Invoice is more than 5 mins ahead in time"},
    {"5 mns adelante", "America/Mazatlan", ~N[2022-03-23 14:11:36],
     "Invoice is more than 5 mins ahead in time"},
    {"5 mns adelante", "America/Mexico_City", ~N[2022-03-23 15:11:36],
     "Invoice is more than 5 mins ahead in time"},
    {"5 mns adelante", "America/Cancun", ~N[2022-03-23 16:11:36],
     "Invoice is more than 5 mins ahead in time"}
  ]

  for {text, emisor_time_zone, emisor_date_time, result} <- data do
    @text text
    @emisor_date_time emisor_date_time
    @emisor_time_zone emisor_time_zone
    @result result
    test "#{@text}, emisor in #{@emisor_time_zone} at #{@emisor_date_time} returns #{@result}" do
      # Change test implementation
      assert validate_dates(
               DateTime.from_naive!(@emisor_date_time, @emisor_time_zone),
               @pac_dt
             ) == @result
    end
  end
end
