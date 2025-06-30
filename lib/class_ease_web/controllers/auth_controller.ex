defmodule ClassEaseWeb.AuthController do
  use ClassEaseWeb, :controller
  alias ClassEase.Accounts
  alias ClassEaseWeb.UserAuth

  plug Ueberauth

  @doc """
  Handle session creation from LiveView login.
  """

  def create_session(conn, %{"user_token" => encoded_token} = params) do
    with {:ok, token} <- Base.url_decode64(encoded_token),
        %Accounts.User{} = user <- Accounts.get_user_by_session_token(token) do

      remember_me = Map.get(params, "remember_me", "false")
      redirect_to = Map.get(params, "redirect_to", "/dashboard")

      conn
      |> put_session(:user_return_to, redirect_to)
      |> UserAuth.log_in_user(user, %{
          "remember_me" => remember_me,
          "token" => token  # Pass the existing validated token
        })
    else
      _ ->
        conn
        |> put_flash(:error, "Invalid session. Please try logging in again.")
        |> redirect(to: ~p"/login")
    end
  end


  @doc """
  Handle OAuth callback from providers like Google.
  """
  def callback(conn, %{"provider" => provider} = _params) do
    %{assigns: %{ueberauth_auth: auth}} = conn

    case extract_user_info(auth, provider) do
      {:ok, user_info} ->
        case Accounts.oauth_register_user(user_info) do
          {:ok, user} ->
            conn
            |> put_flash(:info, "Successfully signed in with #{String.capitalize(provider)}!")
            |> UserAuth.log_in_user(user)

          {:error, _changeset} ->
            conn
            |> put_flash(:error, "There was an error signing you in. Please try again.")
            |> redirect(to: ~p"/login")
        end

      {:error, reason} ->
        conn
        |> put_flash(:error, "Authentication failed: #{reason}")
        |> redirect(to: ~p"/login")
    end
  end

  @doc """
  Handle OAuth failures.
  """
  def failure(conn, _params) do
    conn
    |> put_flash(:error, "Authentication failed. Please try again.")
    |> redirect(to: ~p"/login")
  end

  @doc """
  Handle user logout.
  """
  def logout(conn, _params) do
    conn
    |> put_flash(:info, "You have been logged out successfully.")
    |> UserAuth.log_out_user()
  end

  defp extract_user_info(%Ueberauth.Auth{} = auth, provider) do
    case auth do
      %{info: %{email: email, name: name}, uid: uid} when not is_nil(email) ->
        {:ok, %{
          email: email,
          name: name || extract_name_from_email(email),
          provider: provider,
          uid: to_string(uid)
        }}

      _ ->
        {:error, "Invalid authentication data"}
    end
  end

  defp extract_name_from_email(email) do
    email
    |> String.split("@")
    |> List.first()
    |> String.split(".")
    |> Enum.map(&String.capitalize/1)
    |> Enum.join(" ")
  end
end
