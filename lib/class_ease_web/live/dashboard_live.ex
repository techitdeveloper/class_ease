# Save this as lib/class_ease_web/live/dashboard_live.ex
defmodule ClassEaseWeb.DashboardLive do
  use ClassEaseWeb, :live_view
  alias ClassEase.Accounts

  @impl true
  def mount(%{"user_token" => token}, _session, socket) do
    case Accounts.get_user_by_session_token(token) do
      nil ->
        {:ok,
         socket
         |> put_flash(:error, "Invalid session. Please log in again.")
         |> redirect(to: ~p"/login")}

      user ->
        {:ok,
         socket
         |> assign(:current_user, user)
         |> assign(:page_title, "Dashboard")}
    end
  end

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> put_flash(:error, "Please log in to access the dashboard.")
     |> redirect(to: ~p"/login")}
  end

  @impl true
  def handle_event("logout", _params, socket) do
    {:noreply,
     socket
     |> put_flash(:info, "Logged out successfully!")
     |> redirect(to: ~p"/login")}
  end
end
