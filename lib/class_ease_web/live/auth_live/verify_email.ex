defmodule ClassEaseWeb.AuthLive.VerifyEmail do
  use ClassEaseWeb, :live_view
  alias ClassEase.Accounts

  def mount(params, _session, socket) do
    case params do
      %{"token" => token} ->
        case Accounts.verify_email(token) do
          {:ok, _user} ->
            # Redirect immediately to login with success message
            socket =
              socket
              |> put_flash(:info, "Email verified successfully! Please log in to continue.")
              |> push_navigate(to: "/login")
            {:ok, socket}

          {:error, :invalid_token} ->
            socket =
              socket
              |> assign(:verification_status, :invalid_token)
              |> assign(:user, nil)
            {:ok, socket}

          {:error, _changeset} ->
            socket =
              socket
              |> assign(:verification_status, :error)
              |> assign(:user, nil)
            {:ok, socket}
        end

      _params ->
        socket =
          socket
          |> assign(:verification_status, :missing_token)
          |> assign(:user, nil)
        {:ok, socket}
    end
  end
end
