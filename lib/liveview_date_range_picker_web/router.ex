defmodule LiveviewDateRangePickerWeb.Router do
  use LiveviewDateRangePickerWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {LiveviewDateRangePickerWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", LiveviewDateRangePickerWeb do
    pipe_through :browser

    live "/", HomepageLive
  end

  # Other scopes may use custom stacks.
  # scope "/api", LiveviewDateRangePickerWeb do
  #   pipe_through :api
  # end
end
