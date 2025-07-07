defmodule ClassEaseWeb.Router do
  use ClassEaseWeb, :router

  import ClassEaseWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {ClassEaseWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  # Public routes (no authentication required)
  scope "/", ClassEaseWeb do
    pipe_through :browser

    get "/", PageController, :home
  end

  # Authentication routes (redirect if already authenticated)
  scope "/", ClassEaseWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    live "/register", AuthLive.Register, :new
    live "/login", AuthLive.Login, :index
    live "/verify-email/:token", AuthLive.VerifyEmail, :show
  end

  # Protected routes (require authentication)
  scope "/", ClassEaseWeb do
    pipe_through [:browser, :require_authenticated_user]

    live "/dashboard", DashboardLive, :index
  end

  # Auth actions (for login success and logout)
  scope "/auth", ClassEaseWeb do
    pipe_through [:browser]

    get "/login-success", UserSessionController, :login_success
  end

  scope "/", ClassEaseWeb do
    pipe_through [:browser]

    get "/logout", UserSessionController, :delete
  end

  # Other scopes may use custom stacks.
  # scope "/api", ClassEaseWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:class_ease, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: ClassEaseWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
