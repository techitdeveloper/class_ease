defmodule ClassEaseWeb.AuthLive.Login do
  use ClassEaseWeb, :live_view

  alias ClassEase.Accounts

  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:email, "")
      |> assign(:password, "")
      |> assign(:remember_me, false)
      |> assign(:loading, false)

    {:ok, socket}
  end

  def handle_event("validate", %{"login" => login_params}, socket) do
    socket =
      socket
      |> assign(:email, login_params["email"] || "")
      |> assign(:password, login_params["password"] || "")
      |> assign(:remember_me, login_params["remember_me"] == "true")

    {:noreply, socket}
  end

  def handle_event("save", %{"login" => login_params}, socket) do
    email = login_params["email"]
    password = login_params["password"]
    remember_me = login_params["remember_me"] == "false"

    socket = assign(socket, :loading, true)

    case Accounts.authenticate_user(email, password) do
      {:ok, user} ->
        # Create session token
        case Accounts.create_user_session_token(user) do
          {:ok, token} ->
            # Send message to handle the login in handle_info
            send(self(), {:login_success, user, token, remember_me})
            {:noreply, socket}

          {:error, _} ->
            socket =
              socket
              |> assign(:loading, false)
              |> put_flash(:error, "An error occurred. Please try again.")
            {:noreply, socket}
        end

      {:error, :invalid_credentials} ->
        socket =
          socket
          |> assign(:loading, false)
          |> put_flash(:error, "Invalid email or password")

        {:noreply, socket}

      {:error, :email_not_verified} ->
        socket =
          socket
          |> assign(:loading, false)
          |> put_flash(:error, "Please verify your email address before signing in")

        {:noreply, socket}
    end
  end

  def handle_info({:login_success, _user, token, remember_me}, socket) do
    # Redirect to a controller action that will handle the session
    socket =
      socket
      |> assign(:loading, false)
      |> redirect(to: ~p"/auth/login-success?token=#{token}&remember_me=#{remember_me}")

    {:noreply, socket}
  end
end
