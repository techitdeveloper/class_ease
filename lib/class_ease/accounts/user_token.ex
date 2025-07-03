defmodule ClassEase.Accounts.UserToken do
  use Ecto.Schema
  import Ecto.Query
  alias ClassEase.Accounts.UserToken

  @hash_algorithm :sha256
  @rand_size 32

  # Token expires after 24 hours for email verification
  @email_verification_validity_in_days 1
  # Password reset tokens expire after 1 hour
  @password_reset_validity_in_hours 1
  # Session tokens expire after 60 days
  @session_validity_in_days 60

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "user_tokens" do
    field :token, :binary
    field :context, :string
    field :sent_to, :string
    belongs_to :user, ClassEase.Accounts.User

    timestamps(updated_at: false)
  end

  @doc """
  Generates a token that will be sent to the given user email for email verification.

  ## Examples

      iex> {token, user_token} = UserToken.build_email_token(user, "email_verification")
      iex> user_token.context
      "email_verification"

  """
  def build_email_token(user, context) do
    build_hashed_token(user, context, user.email)
  end

  @doc """
  Generates a token for password reset.

  ## Examples

      iex> {token, user_token} = UserToken.build_email_token(user, "password_reset")
      iex> user_token.context
      "password_reset"

  """
  def build_password_reset_token(user) do
    build_hashed_token(user, "password_reset", user.email)
  end

  defp build_hashed_token(user, context, sent_to) do
    token = :crypto.strong_rand_bytes(@rand_size)
    hashed_token = :crypto.hash(@hash_algorithm, token)

    {Base.url_encode64(token, padding: false),
     %UserToken{
       token: hashed_token,
       context: context,
       sent_to: sent_to,
       user_id: user.id
     }}
  end

  @doc """
  Checks if the token is valid and returns its underlying lookup query.

  The query returns the user found by the token, if any.

  ## Examples

      iex> UserToken.verify_email_token_query("valid-token")
      #Ecto.Query<...>

      iex> UserToken.verify_email_token_query("invalid-token")
      nil

  """
  def verify_email_token_query(token) do
    case Base.url_decode64(token, padding: false) do
      {:ok, decoded_token} ->
        hashed_token = :crypto.hash(@hash_algorithm, decoded_token)
        days = @email_verification_validity_in_days

        query =
          from token in token_and_context_query(hashed_token, "email_verification"),
            join: user in assoc(token, :user),
            where: token.inserted_at > ago(^days, "day") and token.sent_to == user.email,
            select: user

        {:ok, query}

      :error ->
        :error
    end
  end

  @doc """
  Checks if the token is valid for password reset and returns its underlying lookup query.

  ## Examples

      iex> UserToken.verify_password_reset_token_query("valid-token")
      #Ecto.Query<...>

  """
  def verify_password_reset_token_query(token) do
    case Base.url_decode64(token, padding: false) do
      {:ok, decoded_token} ->
        hashed_token = :crypto.hash(@hash_algorithm, decoded_token)
        hours = @password_reset_validity_in_hours

        query =
          from token in token_and_context_query(hashed_token, "password_reset"),
            join: user in assoc(token, :user),
            where: token.inserted_at > ago(^hours, "hour") and token.sent_to == user.email,
            select: user

        {:ok, query}

      :error ->
        :error
    end
  end

  @doc """
  Returns the token struct for the given token value and context.
  """
  def token_and_context_query(token, context) do
    from UserToken, where: [token: ^token, context: ^context]
  end

  @doc """
  Gets all tokens for the given user for the given contexts.

  ## Examples

      iex> UserToken.user_and_contexts_query(user, ["email_verification"])
      #Ecto.Query<...>

  """
  def user_and_contexts_query(user, :all) do
    from t in UserToken, where: t.user_id == ^user.id
  end

  def user_and_contexts_query(user, [_ | _] = contexts) do
    from t in UserToken, where: t.user_id == ^user.id and t.context in ^contexts
  end


  # def delete_expired_tokens do
  #   from(t in UserToken,
  #     where:
  #       t.context == "email_verification" and
  #         t.inserted_at < ago(@email_verification_validity_in_days, "day")
  #   )
  #   |> ClassEase.Repo.delete_all()

  #   from(t in UserToken,
  #     where:
  #       t.context == "password_reset" and
  #         t.inserted_at < ago(@password_reset_validity_in_hours, "hour")
  #   )
  #   |> ClassEase.Repo.delete_all()
  # end

  @doc """
  Builds a token for session authentication.
  """
  def build_session_token(user) do
    build_hashed_token(user, "session", user.email)
  end

  @doc """
  Checks if the session token is valid and returns query to get the user.
  """
  def verify_session_token_query(token) do
    case Base.url_decode64(token, padding: false) do
      {:ok, decoded_token} ->
        hashed_token = :crypto.hash(@hash_algorithm, decoded_token)
        days = @session_validity_in_days

        query =
          from token in token_and_context_query(hashed_token, "session"),
            join: user in assoc(token, :user),
            where: token.inserted_at > ago(^days, "day"),
            select: user

        {:ok, query}

      :error ->
        :error
    end
  end

  # Update the delete_expired_tokens function to include session tokens
  def delete_expired_tokens() do
    # Email verification tokens
    from(t in UserToken,
      where:
        t.context == "email_verification" and
          t.inserted_at < ago(@email_verification_validity_in_days, "day")
    )
    |> ClassEase.Repo.delete_all()

    # Password reset tokens
    from(t in UserToken,
      where:
        t.context == "password_reset" and
          t.inserted_at < ago(@password_reset_validity_in_hours, "hour")
    )
    |> ClassEase.Repo.delete_all()

    # Session tokens
    from(t in UserToken,
      where:
        t.context == "session" and
          t.inserted_at < ago(@session_validity_in_days, "day")
    )
    |> ClassEase.Repo.delete_all()
  end
end
