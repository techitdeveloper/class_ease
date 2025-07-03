defmodule ClassEaseWeb.AuthLive.VerifyEmail do
  use ClassEaseWeb, :live_view

  alias ClassEase.Accounts

  def mount(%{"token" => token}, _session, socket) do
    case Accounts.verify_email(token) do
      {:ok, user} ->
        socket =
          socket
          |> assign(:verification_status, :success)
          |> assign(:user, user)
          |> put_flash(:info, "Email verified successfully. You can now log in.")

        {:ok, socket}

      {:error, :invalid_token} ->
        socket =
          socket
          |> assign(:verification_status, :invalid_token)
          |> assign(:user, nil)

        {:ok, socket}

      {:error, _chageset} ->
        socket =
          socket
          |> assign(:verification_status, :error)
          |> assign(:user, nil)

        {:ok, socket}
    end
  end

  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:verification_status, :missing_token)
      |> assign(:user, nil)

    {:ok, socket}
  end
end
