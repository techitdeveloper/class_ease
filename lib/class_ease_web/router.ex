# defmodule ClassEaseWeb.Router do
#   use ClassEaseWeb, :router

#   pipeline :browser do
#     plug :accepts, ["html"]
#     plug :fetch_session
#     plug :fetch_live_flash
#     plug :put_root_layout, html: {ClassEaseWeb.Layouts, :root}
#     plug :protect_from_forgery
#     plug :put_secure_browser_headers
#   end

#   pipeline :api do
#     plug :accepts, ["json"]
#   end

#   scope "/", ClassEaseWeb do
#     pipe_through :browser

#     get "/", PageController, :home
#   end

#   scope "/", ClassEaseWeb do
#     pipe_through [:browser, :redirect_if_user_is_authenticated]

#     live_session :redirect_if_user_is_authenticated,
#       on_mount: [{ClassEaseWeb.UserAuth, :redirect_if_user_is_authenticated}] do
#       live "/register", UserLive.Auth, :register
#       live "/login", UserLive.Auth, :login
#     end

#     # OAuth routes
#     get "/auth/:provider", AuthController, :request
#     get "/auth/:provider/callback", AuthController, :callback
#     get "/auth/failure", AuthController, :failure

#     # Email confirmation
#     get "/users/confirm/:token", UserConfirmationController, :edit
#     post "/users/confirm/:token", UserConfirmationController, :update
#   end

#   scope "/", ClassEaseWeb do
#     pipe_through [:browser, :require_authenticated_user]

#     live_session :require_authenticated_user,
#       on_mount: [{ClassEaseWeb.UserAuth, :ensure_authenticated}] do
#       live "/dashboard", DashboardLive.Index, :index
#       live "/settings", UserSettingsLive, :edit
#     end

#     # Logout route
#     delete "/users/log_out", AuthController, :logout
#     get "/logout", AuthController, :logout
#   end

#   # Other scopes may use custom stacks.
#   # scope "/api", ClassEaseWeb do
#   #   pipe_through :api
#   # end

#   # Enable LiveDashboard and Swoosh mailbox preview in development
#   if Application.compile_env(:class_ease, :dev_routes) do
#     # If you want to use the LiveDashboard in production, you should put
#     # it behind authentication and allow only admins to access it.
#     # If your application does not have an admins-only section yet,
#     # you can use Plug.BasicAuth to set up some basic authentication
#     # as long as you are also using SSL (which you should anyway).
#     import Phoenix.LiveDashboard.Router

#     scope "/dev" do
#       pipe_through :browser

#       live_dashboard "/dashboard", metrics: ClassEaseWeb.Telemetry
#       forward "/mailbox", Plug.Swoosh.MailboxPreview
#     end
#   end
# end






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

  # Public routes
  scope "/", ClassEaseWeb do
    pipe_through :browser

    get "/", PageController, :home
  end

  # Authentication routes (redirect if already authenticated)
  scope "/", ClassEaseWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    live_session :redirect_if_user_is_authenticated,
      on_mount: [{ClassEaseWeb.UserAuth, :redirect_if_user_is_authenticated}] do
      live "/register", UserLive.Auth, :register
      live "/login", UserLive.Auth, :login
    end

    # OAuth routes
    get "/auth/:provider", AuthController, :request
    get "/auth/:provider/callback", AuthController, :callback
    get "/auth/failure", AuthController, :failure

    # Email confirmation
    get "/users/confirm/:token", UserConfirmationController, :edit
    post "/users/confirm/:token", UserConfirmationController, :update
  end

   scope "/auth", ClassEaseWeb do
    pipe_through :browser

    get "/session/create", AuthController, :create_session
  end

  # Protected routes (require authentication)
  scope "/", ClassEaseWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{ClassEaseWeb.UserAuth, :ensure_authenticated}] do
      # live "/dashboard", DashboardLive.Index, :index
      live "/dashboard", DashboardLive, :index
      live "/settings", UserSettingsLive, :edit
    end

    # Logout route
    delete "/users/log_out", AuthController, :logout
    get "/logout", AuthController, :logout
  end

  # Other scopes may use custom stacks.
  # scope "/api", ClassEaseWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:classease, :dev_routes) do
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
