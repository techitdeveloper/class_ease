defmodule ClassEaseWeb.DashboardLive do
  use ClassEaseWeb, :live_view

  # This will ensure the user is authenticated
  on_mount {ClassEaseWeb.UserAuth, :ensure_authenticated}

  def mount(_params, _session, socket) do
    user = socket.assigns.current_user

    socket =
      socket
      |> assign(:user, user)
      |> assign(:page_title, "Dashboard")

    {:ok, socket}
  end

  def handle_event("logout", _params, socket) do
    # Redirect to logout controller action
    socket = redirect(socket, to: ~p"/logout")
    {:noreply, socket}
  end
end
