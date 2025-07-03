defmodule ClassEaseWeb.DashboardLive do
  use ClassEaseWeb, :live_view

  alias ClassEase.Accounts

  def mount(params, session, socket) do
    # Check for token in params first (from login redirect), then session
    token = params["token"] || session["user_token"]

    case token do
      nil ->
        socket =
          socket
          |> put_flash(:error, "You must be logged in to access this page")
          |> redirect(to: "/login")

        {:ok, socket}

      token ->
        case Accounts.get_user_by_session_token(token) do
          nil ->
            socket =
              socket
              |> put_flash(:error, "Invalid session. Please log in again.")
              |> redirect(to: "/login")

            {:ok, socket}

          user ->
            socket = assign(socket, :current_user, user)
            {:ok, socket}
        end
    end
  end

  def handle_event("logout", _params, socket) do
    # You can add logout logic here later
    socket =
      socket
      |> put_flash(:info, "Logged out successfully")
      |> redirect(to: "/")

    {:noreply, socket}
  end
end
