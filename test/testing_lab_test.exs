defmodule InvoiceValidatorTest do
  Calendar.put_time_zone_database(Tzdata.TimeZoneDatabase)
  use ExUnit.Case

  test "Emisor and PAC are equal dates" do
    assert InvoiceValidator.validate_dates(
             DateTime.from_naive!(~N[2022-03-23 10:00:00], "America/Mazatlan"),
             DateTime.from_naive!(~N[2022-03-23 11:00:00], "America/Mexico_City")
           ) == :ok

    assert InvoiceValidator.validate_dates(
             DateTime.from_naive!(~N[2022-03-23 10:00:00], "America/Tijuana"),
             DateTime.from_naive!(~N[2022-03-23 11:00:00], "America/Mexico_City")
           ) == :ok

    assert InvoiceValidator.validate_dates(
             DateTime.from_naive!(~N[2022-03-23 10:00:00], "America/Mexico_City"),
             DateTime.from_naive!(~N[2022-03-23 10:00:00], "America/Mexico_City")
           ) == :ok
  end

  test "Emisor date is 72 hours or less behind PAC" do
    assert InvoiceValidator.validate_dates(
             DateTime.from_naive!(~N[2022-03-20 10:00:00], "America/Mazatlan"),
             DateTime.from_naive!(~N[2022-03-23 11:00:00], "America/Mexico_City")
           ) == :ok

    assert InvoiceValidator.validate_dates(
             DateTime.from_naive!(~N[2022-03-20 10:00:00], "America/Tijuana"),
             DateTime.from_naive!(~N[2022-03-23 10:59:00], "America/Mexico_City")
           ) == :ok

    assert InvoiceValidator.validate_dates(
             DateTime.from_naive!(~N[2022-03-20 10:01:00], "America/Mexico_City"),
             DateTime.from_naive!(~N[2022-03-23 10:00:00], "America/Mexico_City")
           ) == :ok
  end

  test "Emisor date is more than 72 hours behind PAC" do
    assert InvoiceValidator.validate_dates(
             DateTime.from_naive!(~N[2022-03-20 09:59:59], "America/Mazatlan"),
             DateTime.from_naive!(~N[2022-03-23 11:00:00], "America/Mexico_City")
           ) == {:error, "Invoice was issued more than 72 hrs before received by the PAC"}

    assert InvoiceValidator.validate_dates(
             DateTime.from_naive!(~N[2022-03-20 10:00:00], "America/Tijuana"),
             DateTime.from_naive!(~N[2022-03-23 11:00:01], "America/Mexico_City")
           ) == {:error, "Invoice was issued more than 72 hrs before received by the PAC"}

    assert InvoiceValidator.validate_dates(
             DateTime.from_naive!(~N[2022-03-20 09:00:00], "America/Mexico_City"),
             DateTime.from_naive!(~N[2022-03-23 10:00:00], "America/Mexico_City")
           ) == {:error, "Invoice was issued more than 72 hrs before received by the PAC"}
  end

  test "Emisor date is 5 minutes or less ahead of PAC" do
    assert InvoiceValidator.validate_dates(
             DateTime.from_naive!(~N[2022-03-23 10:05:00], "America/Mazatlan"),
             DateTime.from_naive!(~N[2022-03-23 11:00:00], "America/Mexico_City")
           ) == :ok

    assert InvoiceValidator.validate_dates(
             DateTime.from_naive!(~N[2022-03-23 10:04:59], "America/Tijuana"),
             DateTime.from_naive!(~N[2022-03-23 11:00:00], "America/Mexico_City")
           ) == :ok

    assert InvoiceValidator.validate_dates(
             DateTime.from_naive!(~N[2022-03-23 10:02:00], "America/Mexico_City"),
             DateTime.from_naive!(~N[2022-03-23 10:00:00], "America/Mexico_City")
           ) == :ok
  end

  test "Emisor date is more than 5 minutes ahead of PAC" do
    assert InvoiceValidator.validate_dates(
             DateTime.from_naive!(~N[2022-03-23 10:05:01], "America/Mazatlan"),
             DateTime.from_naive!(~N[2022-03-23 11:00:00], "America/Mexico_City")
           ) == {:error, "Invoice is more than 5 mins ahead in time"}

    assert InvoiceValidator.validate_dates(
             DateTime.from_naive!(~N[2022-03-23 10:06:00], "America/Tijuana"),
             DateTime.from_naive!(~N[2022-03-23 11:00:00], "America/Mexico_City")
           ) == {:error, "Invoice is more than 5 mins ahead in time"}

    assert InvoiceValidator.validate_dates(
             DateTime.from_naive!(~N[2022-03-23 10:07:00], "America/Mexico_City"),
             DateTime.from_naive!(~N[2022-03-23 10:00:00], "America/Mexico_City")
           ) == {:error, "Invoice is more than 5 mins ahead in time"}
  end
end
