defmodule ClassEaseWeb.UserSessionController do
  use ClassEaseWeb, :controller

  alias ClassEase.Accounts
  # alias ClassEaseWeb.UserAuth

  def login_success(conn, %{"token" => token, "remember_me" => _remember_me}) do
    # Get user from token to verify it's valid
    case Accounts.get_user_by_session_token(token) do
      %ClassEase.Accounts.User{} = user ->
        conn
        |> put_session(:user_token, token)
        |> put_session(:live_socket_id, "users_sessions:#{Base.url_encode64(token)}")
        |> configure_session(renew: true)
        |> put_flash(:info, "Welcome back, #{user.name}!")
        |> redirect(to: ~p"/dashboard")

      nil ->
        conn
        |> put_flash(:error, "Invalid login session. Please try again.")
        |> redirect(to: ~p"/login")
    end
  end

  def delete(conn, _params) do
    user_token = get_session(conn, :user_token)

    # Delete the token from database
    if user_token do
      Accounts.delete_session_token(user_token)
    end

    # Broadcast disconnect to LiveView
    if live_socket_id = get_session(conn, :live_socket_id) do
      ClassEaseWeb.Endpoint.broadcast(live_socket_id, "disconnect", %{})
    end

    conn
    |> configure_session(renew: true)
    |> clear_session()
    |> put_flash(:info, "Logged out successfully.")
    |> redirect(to: ~p"/")
  end
end
