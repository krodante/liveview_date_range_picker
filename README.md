# LiveView DateRangePicker

![date range picker demo](https://github.com/krodante/liveview_date_range_picker/assets/22243947/ae7af671-1abd-4432-9b18-5796a65d3f15)


This is a generic date range picker component that you may import into your Phoenix app. The repo includes a full Phoenix app in order to show functionality, but you will only need to copy a few files and lines of code to your app in order to use it.

Requirements:
* Phoenix
* Elixir
* Tailwind

## Installation Instructions

1. Copy the `lib/liveview_date_range_picker_web/components/date_range_picker.ex` file into your component directory. Example: `lib/your_app_web/components/`
2. At the top of the `date_range_picker.ex` file, change the module definition to your directory. For example, if you put the component in `lib/your_app_web/components/some/nested/components/date_range_picker.ex`, you would change the `defmodule` line to: `defmodule YourAppWeb.Components.Some.Nested.Components.DateRangePicker do`
3. Add the helper function to `CoreComponents`. Open the `lib/liveview_date_range_picker_web/components/core_components.ex` file and copy-paste this code snippet:

```elixir
  @min_date Date.utc_today() |> Date.add(-365)

  attr(:id, :string, required: true)
  attr(:label, :string, required: true)

  attr(:start_date_field, :any,
    doc: "a %Phoenix.HTML.Form{}/field name tuple, for example: @form[:start_date]"
  )

  attr(:end_date_field, :any,
    doc: "a %Phoenix.HTML.Form{}/field name tuple, for example: @form[:end_date]"
  )

  attr(:required, :boolean, default: false)
  attr(:readonly, :boolean, default: false)
  attr(:min, :any, default: @min_date, doc: "the earliest date that can be set")
  attr(:errors, :list, default: [])
  attr(:form, :any)

  def date_range_picker(assigns) do
    ~H"""
    <.live_component
      module={LiveviewDateRangePickerWeb.Components.DateRangePicker}
      label={@label}
      id={@id}
      form={@form}
      start_date_field={@start_date_field}
      end_date_field={@end_date_field}
      required={@required}
      readonly={@readonly}
      is_range?
      min={@min}
    />
    <div phx-feedback-for={@start_date_field.name}>
      <.error :for={msg <- @start_date_field.errors}><%= format_form_error(msg) %></.error>
    </div>
    <div phx-feedback-for={@end_date_field.name}>
      <.error :for={msg <- @end_date_field.errors}><%= format_form_error(msg) %></.error>
    </div>
    """
  end

  attr(:id, :string, required: true)
  attr(:label, :string, required: true)

  attr(:start_date_field, :any,
    doc: "a %Phoenix.HTML.Form{}/field name tuple, for example: @form[:start_date]"
  )

  attr(:required, :boolean, default: false)
  attr(:readonly, :boolean, default: false)
  attr(:min, :any, default: @min_date, doc: "the earliest date that can be set")
  attr(:errors, :list, default: [])
  attr(:form, :any)

  def date_picker(assigns) do
    ~H"""
    <.live_component
      module={LiveviewDateRangePickerWeb.Components.DateRangePicker}
      label={@label}
      id={@id}
      form={@form}
      start_date_field={@start_date_field}
      required={@required}
      readonly={@readonly}
      is_range?={false}
      min={@min}
    />
    <div phx-feedback-for={@start_date_field.name}>
      <.error :for={msg <- @start_date_field.form.errors}><%= format_form_error(msg) %></.error>
    </div>
    """
  end

  defp format_form_error({_key, {msg, _type}}), do: msg
  defp format_form_error({msg, _type}), do: msg
```

4. In the code you just copied, change the `LiveviewDateRangePickerWeb.Components.DateRangePicker` to your app's DateRangePicker module. For example: `YourAppWeb.Components.Some.Nested.Components.DateRangePicker`
5. Copy the `assets/js/daterange-hover.js` file to your `assets/js` directory, at the same level as `app.js`.
6. In `assets/js/app.js`, import the `daterange-hover.js` script and set the `hooks` in `liveSocket`

```diff
+ import DaterangeHover from "./daterange-hover";

+ let Hooks = { DaterangeHover };

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
- let liveSocket = new LiveSocket("/live", Socket, {params: {_csrf_token: csrfToken}})
+ let liveSocket = new LiveSocket("/live", Socket, {params: {_csrf_token: csrfToken}, hooks: Hooks})
```

## Usage

To add a `.date_range_picker` input within a form you will have to add it within the `.form` or `.simple_form` element. Example usage is in the `lib/liveview_date_range_picker_web/live/homepage_live.ex` file.

### .date_range_picker

```elixir
<.date_range_picker
  label="Date Range" # input label
  id="date_range_picker" # the ID of the element. If you have multiple date_range_pickers you could add the object ID here to differentiate them. Example: id={"#{@form.id}-date_range_picker"}
  form={@form}
  start_date_field={@form[:start_date]} # this is the range start field in your database/schema
  end_date_field={@form[:end_date]} # this is the range end field in your database/schema
  min={Date.utc_today() |> Date.add(-7)} # the earliest date users can choose. In this case, the min is set to 7 days ago.
  required={true} # indicate that the field is required
/>
```

### .date_picker

```elixir
<.date_picker
  label="Single Date" # input label
  id="date_picker" # the ID of the element. If you have multiple date_pickers you could add the object ID here to differentiate them. Example: id={"#{@form.id}-date_picker"}
  form={@form}
  start_date_field={@form[:start_date]} # this is the range start field in your database/schema
  min={Date.utc_today() |> Date.add(-7)} # the earliest date users can choose. In this case, the min is set to 7 days ago.
  required={true} # indicate that the field is required
/>
```
