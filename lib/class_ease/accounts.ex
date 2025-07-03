defmodule ClassEase.Accounts do
  @moduledoc """
  The Accounts context - handles all user-related business logic
  """

  import Ecto.Query, warn: false
  alias ClassEase.Repo
  alias ClassEase.Accounts.{User, UserToken}

  @doc """
  Creates a new user account with email verification.

  ## Examples

      iex> register_user(%{email: "test@example.com", password: "Password123", name: "John Doe"})
      {:ok, %{user: %User{}, token: "verification-token"}}

      iex> register_user(%{email: "bad-email"})
      {:error, %Ecto.Changeset{}}

  """
  def register_user(attrs \\ %{}) do
    # Start a database transaction
    Ecto.Multi.new()
    |> Ecto.Multi.insert(:user, User.registration_changeset(%User{}, attrs))
    |> Ecto.Multi.run(:token, fn _repo, %{user: user} ->
      {token, user_token} = UserToken.build_email_token(user, "email_verification")

      case Repo.insert(user_token) do
        {:ok, _user_token} -> {:ok, token}
        {:error, changeset} -> {:error, changeset}
      end
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user, token: token}} ->
        # In a real app, you'd send an email here
        # For development, we'll just log it
        simulate_send_verification_email(user, token)
        track_user_event(user, "user_registered")
        {:ok, %{user: user, token: token}}

      {:error, :user, changeset, _changes_so_far} ->
        {:error, changeset}

      {:error, :token, changeset, _changes_so_far} ->
        {:error, changeset}
    end
  end

  @doc """
  Verifies a user's email using the verification token.

  ## Examples

      iex> verify_email("valid-token")
      {:ok, %User{email_verified: true}}

      iex> verify_email("invalid-token")
      {:error, :invalid_token}

  """
  def verify_email(token) do
    case UserToken.verify_email_token_query(token) do
      {:ok, query} ->
        case Repo.one(query) do
          nil ->
            {:error, :invalid_token}

          user ->
            # Start transaction: update user and delete token
            Ecto.Multi.new()
            |> Ecto.Multi.update(:user, User.email_verification_changeset(user))
            |> Ecto.Multi.delete_all(
              :tokens,
              UserToken.user_and_contexts_query(user, ["email_verification"])
            )
            |> Repo.transaction()
            |> case do
              {:ok, %{user: user}} ->
                track_user_event(user, "email_verified")
                {:ok, user}

              {:error, :user, changeset, _} ->
                {:error, changeset}
            end
        end

      :error ->
        {:error, :invalid_token}
    end
  end

  @doc """
  Authenticates a user with email and password.
  Only allows login if email is verified.

  ## Examples

      iex> authenticate_user("test@example.com", "Password123")
      {:ok, %User{}}

      iex> authenticate_user("test@example.com", "wrong-password")
      {:error, :invalid_credentials}

      iex> authenticate_user("unverified@example.com", "Password123")
      {:error, :email_not_verified}

  """
  def authenticate_user(email, password) when is_binary(email) and is_binary(password) do
    user = Repo.get_by(User, email: email)

    cond do
      user && User.valid_password?(user, password) && user.email_verified ->
        update_last_login(user)
        {:ok, user}

      user && User.valid_password?(user, password) && !user.email_verified ->
        {:error, :email_not_verified}

      user ->
        {:error, :invalid_credentials}

      true ->
        # Run password verification anyway to prevent timing attacks
        Pbkdf2.no_user_verify()
        {:error, :invalid_credentials}
    end
  end

  @doc """
  Resends email verification token.

  ## Examples

      iex> resend_verification_email(user)
      {:ok, "new-token"}

  """
  def resend_verification_email(%User{email_verified: false} = user) do
    # Delete existing verification tokens
    UserToken.user_and_contexts_query(user, ["email_verification"])
    |> Repo.delete_all()

    # Create new token
    {token, user_token} = UserToken.build_email_token(user, "email_verification")

    case Repo.insert(user_token) do
      {:ok, _user_token} ->
        simulate_send_verification_email(user, token)
        track_user_event(user, "verification_email_resent")
        {:ok, token}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def resend_verification_email(%User{email_verified: true}) do
    {:error, :already_verified}
  end

  @doc """
  Gets a user by email.
  """
  def get_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: email)
  end

  @doc """
  Gets a user by ID.
  """
  def get_user(id), do: Repo.get(User, id)

  @doc """
  Updates a user's subscription tier.
  """
  def update_subscription_tier(%User{} = user, tier) when tier in ["free", "teacher", "school"] do
    changeset =
      user
      |> Ecto.Changeset.change(%{
        subscription_tier: tier,
        # Reset PDF count when tier changes
        pdf_count: 0,
        pdf_reset_date: Date.utc_today()
      })

    case Repo.update(changeset) do
      {:ok, updated_user} ->
        track_user_event(updated_user, "subscription_tier_changed", %{new_tier: tier})
        {:ok, updated_user}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  # Private function to simulate sending verification email
  defp simulate_send_verification_email(user, token) do
    verification_url = "http://localhost:4000/verify-email/#{token}"

    require Logger

    Logger.info("""

    📧 EMAIL VERIFICATION (Development Mode)
    =====================================
    To: #{user.email}
    Subject: Verify your ClassEase account

    Hi #{user.name},

    Please click the link below to verify your email:
    #{verification_url}

    This link expires in 24 hours.

    =====================================
    """)
  end

  # Private function to update last login time
  defp update_last_login(%User{} = user) do
    user
    |> Ecto.Changeset.change(%{last_login_at: DateTime.utc_now() |> DateTime.truncate(:second)})
    |> Repo.update()
  end

  # Private function to track user events
  defp track_user_event(%User{} = user, event_type, data \\ %{}) do
    require Logger
    Logger.info("User #{user.id} performed #{event_type}: #{inspect(data)}")
  end

  @doc """
  Creates a session token for the user after successful login.
  This token will be stored in the browser session.
  """
  def create_user_session_token(user) do
    {token, user_token} = UserToken.build_session_token(user)

    case Repo.insert(user_token) do
      {:ok, _user_token} ->
        track_user_event(user, "session_created")
        {:ok, token}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  @doc """
  Gets the user by session token.
  """
  def get_user_by_session_token(token) do
    {:ok, query} = UserToken.verify_session_token_query(token)
    Repo.one(query)
  end

  @doc """
  Deletes the session token (logout).
  """
  def delete_session_token(token) do
    case UserToken.verify_session_token_query(token) do
      {:ok, _query} ->
        # Get the token record to delete it
        token_query =
          from t in UserToken,
            where: t.token == ^:crypto.hash(:sha256, Base.url_decode64!(token, padding: false)),
            where: t.context == "session"

        case Repo.delete_all(token_query) do
          {count, _} when count > 0 ->
            :ok

          _ ->
            :error
        end

      :error ->
        :error
    end
  end

  @doc """
  Deletes all session tokens for a user (logout from all devices).
  """
  def delete_all_user_session_tokens(user) do
    UserToken.user_and_contexts_query(user, ["session"])
    |> Repo.delete_all()

    track_user_event(user, "all_sessions_deleted")
    :ok
  end

  @doc """
  Login function that combines authentication and session creation.
  """
  def login_user(email, password) do
    case authenticate_user(email, password) do
      {:ok, user} ->
        case create_user_session_token(user) do
          {:ok, token} ->
            {:ok, %{user: user, token: token}}

          {:error, changeset} ->
            {:error, changeset}
        end

      error ->
        error
    end
  end
end
