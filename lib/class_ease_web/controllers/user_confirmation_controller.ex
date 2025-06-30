defmodule ClassEaseWeb.UserConfirmationController do
  use ClassEaseWeb, :controller

  alias ClassEase.Accounts

  def edit(conn, %{"token" => token}) do
    case Accounts.confirm_user(token) do
      {:ok, _user} ->
        conn
        |> put_flash(:info, "Email confirmed successfully! You can now log in.")
        |> redirect(to: ~p"/login")

      :error ->
        conn
        |> put_flash(:error, "Email confirmation link is invalid or has expired.")
        |> redirect(to: ~p"/login")
    end
  end

  def update(conn, %{"token" => token}) do
    edit(conn, %{"token" => token})
  end
end
