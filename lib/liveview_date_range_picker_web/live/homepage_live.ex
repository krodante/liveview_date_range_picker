defmodule LiveviewDateRangePickerWeb.HomepageLive do
  use LiveviewDateRangePickerWeb, :live_view

  def render(assigns) do
    ~H"""
    <.simple_form
      for={@form}
      id="demo_form"
      phx-change="validate"
      phx-submit="save"
    >
      <.date_range_picker
        label="Date Range"
        id="date-range-picker"
        form={@form}
        start_date_field={@form[:start_date]}
        end_date_field={@form[:end_date]}
        min={Date.utc_today() |> Date.add(-7)}
        required={true}
      />
    </.simple_form>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    form = %{
      "start_date" => nil,
      "end_date" => nil
    }

    {:ok, assign(socket, :form, to_form(form))}
  end

  @impl true
  def handle_event("validate", params, socket) do
    form = %{
      "start_date" => params["start_date"],
      "end_date" => params["end_date"]
    }

    {:noreply, assign(socket, :form, to_form(form))}
  end
end