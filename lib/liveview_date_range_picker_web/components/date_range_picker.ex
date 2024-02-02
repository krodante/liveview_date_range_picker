defmodule LiveviewDateRangePickerWeb.Components.DateRangePicker do
  use LiveviewDateRangePickerWeb, :live_component

  @week_start_at :sunday
  @fsm %{
    set_start: :set_end,
    set_end: :reset,
    reset: :set_start
  }
  @initial_state :set_start

  @impl true
  def render(assigns) do
    ~H"""
    <div class="date-range-picker">
      <.input field={@start_date_field} type="hidden" />
      <.input :if={@is_range?} field={@end_date_field} type="hidden" />
      <div class="fake-input-tag relative" phx-click="open-calendar" phx-target={@myself}>
        <.input
          name={"#{@id}_display_value"}
          required={@required}
          readonly
          type="text"
          label={@label}
          value={date_range_display(@range_start, @range_end)}
        />
        <.icon name="hero-calendar" class="absolute top-10 right-3 flex text-gray-400" />
      </div>

      <div
        :if={@calendar?}
        id={"#{@id}_calendar"}
        class="absolute z-50 w-72 shadow"
        phx-click-away="close-calendar"
        phx-target={@myself}
      >
        <div
          id="calendar_background"
          class="w-full bg-white rounded-md shadow-lg ring-1 ring-black ring-opacity-5 focus:outline-none p-3"
        >
          <div id="calendar_header" class="flex justify-between text-gray-900">
            <div id="button_left">
              <button
                type="button"
                phx-target={@myself}
                phx-click="prev-month"
                class="p-1.5 text-gray-400 hover:text-gray-500"
              >
                <.icon name="hero-arrow-left" />
              </button>
            </div>

            <div id="current_month_year" class="self-center">
              <%= @current.month %>
            </div>

            <div id="button_right">
              <button
                type="button"
                phx-target={@myself}
                phx-click="next-month"
                class="p-1.5 text-gray-400 hover:text-gray-500"
              >
                <.icon name="hero-arrow-right" />
              </button>
            </div>
          </div>

          <div
            id="click_today"
            class="text-gray-500 text-sm text-center cursor-pointer"
          >
            <.link phx-click="today" phx-target={@myself}>
              Today
            </.link>
          </div>

          <div
            id="calendar_weekdays"
            class="text-center mt-6 grid grid-cols-7 text-xs leading-6 text-gray-500"
          >
            <div :for={week_day <- List.first(@current.week_rows)}>
              <%= Calendar.strftime(week_day, "%a") %>
            </div>
          </div>

          <div
            id={"calendar_days_#{@current.month |> String.replace(" ", "-")}"}
            class="isolate mt-2 grid grid-cols-7 gap-px text-sm"
            phx-hook="DaterangeHover"
          >
            <button
              :for={day <- Enum.flat_map(@current.week_rows, & &1)}
              type="button"
              phx-target={@myself}
              phx-click="pick-date"
              phx-value-date={Calendar.strftime(day, "%Y-%m-%d") <> "T00:00:00Z"}
              class={[
                "calendar-day overflow-hidden py-1.5 h-10 w-auto focus:z-10 w-full",
                today?(day) && "font-bold border border-black",
                before_min_date?(day, @min) && "text-gray-300 cursor-not-allowed",
                !before_min_date?(day, @min) && "hover:bg-blue-300 hover:border hover:border-black",
                other_month?(day, @current.date) && "text-gray-500",
                selected_range?(day, @range_start, @hover_range_end || @range_end) && "hover:bg-blue-500 bg-blue-500 text-white"
              ]}
            >
              <time
                class="mx-auto flex h-6 w-6 items-center justify-center rounded-full"
                datetime={Calendar.strftime(day, "%Y-%m-%d")}
              >
                <%= Calendar.strftime(day, "%d") %>
              </time>
            </button>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def mount(socket) do
    current_date = Date.utc_today()

    {
      :ok,
      socket
      |> assign(:calendar?, false)
      |> assign(:current, format_date(current_date))
      |> assign(:is_range?, true)
      |> assign(:range_start, nil)
      |> assign(:range_end, nil)
      |> assign(:hover_range_end, nil)
      |> assign(:readonly, false)
      |> assign(:selected_date, nil)
      |> assign(:form, nil)
    }
  end

  @impl true
  def update(assigns, socket) do
    range_start = from_str!(assigns.start_date_field.value)
    range_end = from_str!(end_value(assigns))
    current_date = socket.assigns.current.date

    {
      :ok,
      socket
      |> assign(assigns)
      |> assign(:current, format_date(current_date))
      |> assign(:range_start, range_start)
      |> assign(:range_end, range_end)
      |> assign(:state, @initial_state)
    }
  end

  @impl true
  def handle_event("open-calendar", _, socket) do
    {:noreply, socket |> assign(:calendar?, true)}
  end

  @impl true
  def handle_event("close-calendar", _, socket) do
    [range_start, range_end] =
      [
        socket.assigns.range_start,
        socket.assigns.range_end || socket.assigns.range_start
      ]
      |> Enum.sort(&(DateTime.compare(&1, &2) != :gt))
      
    attrs = %{
      id: socket.assigns.id,
      start_date: range_start,
      end_date: range_end,
      form: socket.assigns.form
    }

    send(self(), {:updated_event, attrs})

    {
      :noreply,
      socket
      |> assign(:calendar?, false)
      |> assign(:end_date_field, set_field_value(socket.assigns, :end_date_field, range_end))
      |> assign(:start_date_field,set_field_value(socket.assigns, :start_date_field, range_start))
      |> assign(:state, @initial_state)
    }
  end

  @impl true
  def handle_event("today", _, socket) do
    new_date = Date.utc_today()
    {:noreply, socket |> assign(:current, format_date(new_date))}
  end

  @impl true
  def handle_event("prev-month", _, socket) do
    new_date = new_date(socket.assigns)
    {:noreply, socket |> assign(:current, format_date(new_date))}
  end

  @impl true
  def handle_event("next-month", _, socket) do
    last_row = socket.assigns.current.week_rows |> List.last()
    new_date = next_month_new_date(socket.assigns.current.date, last_row)
    {:noreply, socket |> assign(:current, format_date(new_date))}
  end

  @impl true
  def handle_event("pick-date", %{"date" => date_str}, socket) do
    date_time = from_str!(date_str)

    if Date.compare(socket.assigns.min, DateTime.to_date(date_time)) == :gt do
      {:noreply, socket}
    else
      ranges = calculate_date_ranges(socket.assigns.state, date_time)
      state =
        if socket.assigns.is_range? do
          @fsm[socket.assigns.state]
        else
          @initial_state
        end

      {
        :noreply,
        socket
        |> assign(ranges)
        |> assign(:state, state)
      }
    end    
  end

  @impl true
  def handle_event("cursor-move", date_str, socket) do
    date = from_str!(date_str)

    if Date.compare(socket.assigns.min, DateTime.to_date(date)) == :gt do
      {:noreply, socket}
    else
      hover_range_end =
        case socket.assigns.state do
          :set_end -> date
          _ -> nil
        end

      {:noreply, socket |> assign(:hover_range_end, hover_range_end)}
    end
  end

  defp end_value(assigns) when is_map_key(assigns, :to) do
    case assigns.to.value do
      nil -> nil
      "" -> nil
      _ -> assigns.to.value
    end
  end

  defp end_value(_), do: nil

  defp next_month_new_date(current_date, last_row) do
    last_row_last_day = last_row |> List.last()
    last_row_last_month = last_row_last_day |> Calendar.strftime("%B")
    last_row_first_month = last_row |> List.first() |> Calendar.strftime("%B")
    current_month = Calendar.strftime(current_date, "%B")
    next_month = next_month(last_row_first_month, last_row_last_month, last_row_last_day)

    case current_date in last_row && current_month == next_month do
      true ->
        current_date

      false ->
        current_date
        |> Date.end_of_month()
        |> Date.add(1)
    end
  end

  defp next_month(last_row_first_month, last_row_last_month, last_day) when last_row_first_month == last_row_last_month do
    last_day
    |> Date.end_of_month()
    |> Date.add(1)
    |> Calendar.strftime("%B")
  end

  defp next_month(_, last_day_of_last_week_month, _), do: last_day_of_last_week_month

  defp new_date(%{current: %{date: current_date, week_rows: week_rows}}) do
    current_date = current_date
    first_row = week_rows |> List.first()
    last_row = week_rows |> List.last()

    case current_date in last_row do
      true ->
        first_row
        |> List.last()
        |> Date.beginning_of_month()
        |> Date.add(-1)

      false ->
        current_date
        |> Date.beginning_of_month()
        |> Date.add(-1)
    end
  end

  defp week_rows(current_date) do
    first =
      current_date
      |> Date.beginning_of_month()
      |> Date.beginning_of_week(@week_start_at)

    last =
      current_date
      |> Date.end_of_month()
      |> Date.end_of_week(@week_start_at)

    Date.range(first, last)
    |> Enum.map(& &1)
    |> Enum.chunk_every(7)
  end

  defp calculate_date_ranges(:set_start, date_time) do
    %{
      range_start: date_time,
      range_end: nil
    }
  end

  defp calculate_date_ranges(:set_end, date_time), do: %{range_end: date_time}

  defp calculate_date_ranges(:reset, _date_time) do
    %{
      range_start: nil,
      range_end: nil
    }
  end

  defp set_field_value(nil, _field, _value), do: nil

  defp set_field_value(assigns, field, value) when is_binary(value) do
    if Map.has_key?(assigns, field) and is_map(assigns[field]) do
      {:ok, value, _} = DateTime.from_iso8601(value)
      Map.put(assigns[field], :value, value)
    else
      nil
    end
  end

  defp set_field_value(assigns, field, value) do
    if Map.has_key?(assigns, field) and is_map(assigns[field]) do
      {:ok, value, _} = DateTime.from_iso8601(Date.to_string(value) <> "T00:00:00Z")
      Map.put(assigns[field], :value, value)
    else
      nil
    end
  end

  defp before_min_date?(day, min) do
    Date.compare(day, min) == :lt
  end

  defp today?(day), do: day == Date.utc_today()

  defp other_month?(day, current_date) do
    Date.beginning_of_month(day) != Date.beginning_of_month(current_date)
  end

  defp selected_range?(_day, nil, nil), do: false

  defp selected_range?(day, range_start, nil) do
    day == DateTime.to_date(range_start)
  end

  defp selected_range?(day, nil, range_end) do
    day == DateTime.to_date(range_end)
  end

  defp selected_range?(day, range_start, range_end) do
    start_date = DateTime.to_date(range_start)
    end_date = DateTime.to_date(range_end)
    day in Date.range(start_date, end_date)
  end

  defp format_date(date) do
    %{
      date: date,
      month: Calendar.strftime(date, "%B %Y"),
      week_rows: week_rows(date)
    }
  end

  defp from_str!(""), do: nil

  defp from_str!(date_time_str) when is_binary(date_time_str) do
    with {:ok, date_time, _} <- DateTime.from_iso8601(date_time_str) do
      date_time
    else
      _ -> nil
    end
  end

  defp from_str!(date_time_str), do: date_time_str

  defp date_range_display(start_date, nil) when start_date in [nil, ""] do
    "MM/DD/YYYY - MM/DD/YYYY"
  end

  defp date_range_display(start_date, end_date) when end_date in [nil, ""] do
    start_date_datetime = extract_date(start_date)
    Calendar.strftime(start_date_datetime, "%b %d, %Y")
  end

  defp date_range_display(start_date, end_date) do
    start_date_datetime = extract_date(start_date)
    end_date_datetime = extract_date(end_date)

    "#{Calendar.strftime(start_date_datetime, "%b %d, %Y")} - #{Calendar.strftime(end_date_datetime, "%b %d, %Y")}"
  end

  defp extract_date(input) when input in [nil, ""], do: Date.utc_today()

  defp extract_date(datetime_string) when is_binary(datetime_string) do
    datetime_string
    |> String.split("T")
    |> List.first()
    |> Date.from_iso8601!()
  end

  defp extract_date(%DateTime{} = datetime), do: DateTime.to_date(datetime)
  defp extract_date(%NaiveDateTime{} = datetime), do: NaiveDateTime.to_date(datetime)
  defp extract_date(%{calendar: Calendar.ISO} = datetime), do: datetime
end
