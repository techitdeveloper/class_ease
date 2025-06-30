# defmodule ClassEaseWeb.UserLive.Auth do
#   use ClassEaseWeb, :live_view
#   alias ClassEase.Accounts
#   alias ClassEase.Accounts.User


#   @impl true
#   def mount(_params, _session, socket) do
#     # Don't set mode here - let handle_params do it based on the route
#     socket =
#       socket
#       |> assign(:mode, :login) # Default mode, will be overridden by handle_params
#       |> assign(:form, to_form(Accounts.change_user_registration(%User{})))
#       |> assign(:loading, false)
#       |> assign(:subscription_tiers, subscription_tiers())

#     {:ok, socket, layout: false}
#   end

#   @impl true
#   def handle_params(_params, _url, socket) do
#     # Get the action from the LiveView's assigns
#     action = socket.assigns.live_action

#     mode = case action do
#       :register -> :register
#       :login -> :login
#       _ -> :login
#     end

#     {:noreply, assign(socket, :mode, mode)}
#   end

#   @impl true
#   def handle_event("register", %{"user" => user_params}, socket) do
#     socket = assign(socket, :loading, true)

#     case Accounts.register_user(user_params) do
#       {:ok, user} ->
#         # Generate email confirmation token
#         {:ok, _token} =
#           Accounts.deliver_user_confirmation_instructions(
#             user,
#             &url(~p"/users/confirm/#{&1}")
#           )

#         {:noreply,
#          socket
#          |> assign(:loading, false)
#          |> put_flash(:info, "Account created successfully! Please check your email to verify your account.")
#          |> redirect(to: ~p"/login")}

#       {:error, %Ecto.Changeset{} = changeset} ->
#         {:noreply,
#          socket
#          |> assign(:loading, false)
#          |> assign(:form, to_form(changeset))}
#     end
#   end

#   @impl true
#   def handle_event("login", %{"user" => %{"email" => email, "password" => password}}, socket) do
#     socket = assign(socket, :loading, true)

#     case Accounts.authenticate_user(email, password) do
#       {:ok, user} ->
#         token = Accounts.generate_user_session_token(user)

#         {:noreply,
#          socket
#          |> assign(:loading, false)
#          |> put_flash(:info, "Welcome back!")
#          |> redirect(to: ~p"/dashboard?user_token=#{token}")}

#       {:error, :invalid_credentials} ->
#         {:noreply,
#          socket
#          |> assign(:loading, false)
#          |> put_flash(:error, "Invalid email or password")}

#       {:error, :email_not_verified} ->
#         {:noreply,
#          socket
#          |> assign(:loading, false)
#          |> put_flash(:error, "Please verify your email address before logging in")}
#     end
#   end

#   @impl true
#   def handle_event("toggle_mode", _params, socket) do
#     new_mode = if socket.assigns.mode == :login, do: :register, else: :login

#     path = case new_mode do
#       :login -> ~p"/login"
#       :register -> ~p"/register"
#     end

#     {:noreply,
#     socket
#     |> assign(:mode, new_mode)
#     |> assign(:form, to_form(Accounts.change_user_registration(%User{})))
#     |> push_patch(to: path)}
#   end

#   @impl true
#   def handle_event("validate", %{"user" => user_params}, socket) do
#     changeset =
#       %User{}
#       |> Accounts.change_user_registration(user_params)
#       |> Map.put(:action, :validate)

#     {:noreply, assign(socket, :form, to_form(changeset))}
#   end

#   defp subscription_tiers do
#     [
#       %{
#         id: "free",
#         name: "Free",
#         description: "1 class, 10 students, 2 PDF reports/month",
#         price: "Free"
#       },
#       %{
#         id: "teacher",
#         name: "Teacher",
#         description: "1 class, 60 students, 10 PDF reports/month",
#         price: "$9/month"
#       },
#       %{
#         id: "school",
#         name: "School",
#         description: "Multiple classes, 500 students, 100 PDF reports/month",
#         price: "$29/month"
#       }
#     ]
#   end
# end




















defmodule ClassEaseWeb.UserLive.Auth do
  use ClassEaseWeb, :live_view
  alias ClassEase.Accounts
  alias ClassEase.Accounts.User

  @impl true
  def mount(_params, _session, socket) do
    # Don't set mode here - let handle_params do it based on the route
    socket =
      socket
      |> assign(:mode, :login) # Default mode, will be overridden by handle_params
      |> assign(:form, to_form(Accounts.change_user_registration(%User{})))
      |> assign(:loading, false)
      |> assign(:subscription_tiers, subscription_tiers())

    {:ok, socket, layout: false}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    # Get the action from the LiveView's assigns
    action = socket.assigns.live_action

    mode = case action do
      :register -> :register
      :login -> :login
      _ -> :login
    end

    {:noreply, assign(socket, :mode, mode)}
  end

  @impl true
  def handle_event("register", %{"user" => user_params}, socket) do
    socket = assign(socket, :loading, true)

    case Accounts.register_user(user_params) do
      {:ok, user} ->
        # Generate email confirmation token
        {:ok, _token} =
          Accounts.deliver_user_confirmation_instructions(
            user,
            &url(~p"/users/confirm/#{&1}")
          )

        {:noreply,
         socket
         |> assign(:loading, false)
         |> put_flash(:info, "Account created successfully! Please check your email to verify your account.")
         |> redirect(to: ~p"/login")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply,
         socket
         |> assign(:loading, false)
         |> assign(:form, to_form(changeset))}
    end
  end

  @impl true
  def handle_event("login", %{"user" => user_params}, socket) do
    %{"email" => email, "password" => password} = user_params
    socket = assign(socket, :loading, true)

    case Accounts.authenticate_user(email, password) do
      {:ok, user} ->
        # Generate session token
        token = Accounts.generate_user_session_token(user)
        remember_me = Map.get(user_params, "remember_me", "false")

        # Create login URL with properly encoded token
        # login_url =
        #   ~p"/auth/session/create"
        #   |> URI.parse()
        #   |> Map.put(:query, URI.encode_query(%{
        #     "user_token" => Base.url_encode64(token),
        #     "remember_me" => remember_me,
        #     "redirect_to" => "/dashboard"
        #   }))
        #   |> URI.to_string()

        login_url = "/auth/session/create?" <> URI.encode_query(%{
          "user_token" => Base.url_encode64(token),
          "remember_me" => remember_me,
          "redirect_to" => "/dashboard"
        })

        IO.inspect(login_url, label: "Generated login URL")

        {:noreply,
         socket
         |> assign(:loading, false)
         |> put_flash(:info, "Welcome back!")
         |> redirect(external: login_url)}

      {:error, :invalid_credentials} ->
        {:noreply,
         socket
         |> assign(:loading, false)
         |> put_flash(:error, "Invalid email or password")}

      {:error, :email_not_verified} ->
        {:noreply,
         socket
         |> assign(:loading, false)
         |> put_flash(:error, "Please verify your email address before logging in")}
    end
  end

  @impl true
  def handle_event("toggle_mode", _params, socket) do
    new_mode = if socket.assigns.mode == :login, do: :register, else: :login

    path = case new_mode do
      :login -> ~p"/login"
      :register -> ~p"/register"
    end

    {:noreply,
    socket
    |> assign(:mode, new_mode)
    |> assign(:form, to_form(Accounts.change_user_registration(%User{})))
    |> push_patch(to: path)}
  end

  @impl true
  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset =
      %User{}
      |> Accounts.change_user_registration(user_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  defp subscription_tiers do
    [
      %{
        id: "free",
        name: "Free",
        description: "1 class, 10 students, 2 PDF reports/month",
        price: "Free"
      },
      %{
        id: "teacher",
        name: "Teacher",
        description: "1 class, 60 students, 10 PDF reports/month",
        price: "$9/month"
      },
      %{
        id: "school",
        name: "School",
        description: "Multiple classes, 500 students, 100 PDF reports/month",
        price: "$29/month"
      }
    ]
  end
end
