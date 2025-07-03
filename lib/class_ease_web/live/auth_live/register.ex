defmodule ClassEaseWeb.AuthLive.Register do
  use ClassEaseWeb, :live_view

  alias ClassEase.Accounts
  alias ClassEase.Accounts.User

  def mount(_params, _session, socket) do
    changeset = User.registration_changeset(%User{}, %{})

    socket =
      socket
      |> assign(:changeset, changeset)
      |> assign(:trigger_submit, false)
      |> assign(:registration_success, false)
      |> assign(:user_email, nil)

    {:ok, socket}
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset =
      %User{}
      |> User.registration_changeset(user_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, changeset: changeset)}
  end

  def handle_event("save", %{"user" => user_params}, socket) do
    case Accounts.register_user(user_params) do
      {:ok, %{user: user, token: _token}} ->
        socket =
          socket
          |> assign(:registration_success, true)
          |> assign(:user_email, user.email)
          |> assign(:changeset, User.registration_changeset(user, %{}))

        {:noreply, socket}

      {:error, changeset} ->
        socket =
          socket
          |> assign(:changeset, changeset)
          |> assign(:trigger_submit, false)

        {:noreply, socket}
    end
  end

  def handle_event("resend_verification", _params, socket) do
    case socket.assigns.user_email do
      nil ->
        {:noreply, socket}

      email ->
        user = Accounts.get_user_by_email(email)

        case Accounts.resend_verification_email(user) do
          {:ok, _token} ->
            socket = put_flash(socket, :info, "Verification email resent successfully.")
            {:noreply, socket}

          {:error, :already_verified} ->
            socket = put_flash(socket, :error, "Email already verified.")
            {:noreply, socket}

          {:error, _reason} ->
            socket = put_flash(socket, :error, "Failed to resend verification email.")
            {:noreply, socket}
        end
    end
  end

  def handle_event("back_to_form", _params, socket) do
    socket =
      socket
      |> assign(:registration_success, false)
      |> assign(:user_email, nil)
      |> assign(:changeset, User.registration_changeset(%User{}, %{}))

    {:noreply, socket}
  end
end
