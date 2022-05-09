defmodule InvoiceValidator do
  @moduledoc """
    This module provides a function to validate Invoices.
  """
  def validate_dates(%DateTime{} = emisor_dt, %DateTime{} = pac_dt) do   
    case DateTime.compare(emisor_dt, pac_dt) do 
      :gt ->
        if DateTime.diff(emisor_dt, pac_dt) <= 300 do
          :ok
        else
          "Invoice is more than 5 mins ahead in time"
        end
      :lt ->
        if DateTime.diff(pac_dt, emisor_dt) <= 259_200 do
          :ok
        else 
          "Invoice was issued more than 72 hrs before received by the PAC"
        end
      :eq ->
        :ok
        
    end
  end
end

