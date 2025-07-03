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
    _remember_me = login_params["remember_me"] == "true"

    socket = assign(socket, :loading, true)

    case Accounts.login_user(email, password) do
      {:ok, %{user: user, token: token}} ->
        # For LiveView, we need to send a message to handle session
        send(self(), {:login_success, user, token})

        socket =
          socket
          |> assign(:loading, false)
          |> put_flash(:info, "Welcome back, #{user.name}!")

        {:noreply, socket}

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

      {:error, _reason} ->
        socket =
          socket
          |> assign(:loading, false)
          |> put_flash(:error, "An error occurred. Please try again.")

        {:noreply, socket}
    end
  end

  def handle_info({:login_success, _user, token}, socket) do
    # This is a workaround for LiveView session handling
    # In a real app, you might want to use a regular controller for login
    socket = redirect(socket, to: "/dashboard?token=#{token}")
    {:noreply, socket}
  end
end
