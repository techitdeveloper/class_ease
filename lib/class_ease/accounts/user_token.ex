# defmodule ClassEase.Accounts.UserToken do
#   use Ecto.Schema
#   import Ecto.Query
#   alias ClassEase.Accounts.UserToken

#   @hash_algorithm :sha256
#   @rand_size 32

#   @reset_password_validity_in_days 1
#   @confirm_validity_in_days 7
#   @change_email_validity_in_days 7
#   @session_validity_in_days 60

#   @primary_key {:id, :binary_id, autogenerate: true}
#   @foreign_key_type :binary_id

#   schema "users_tokens" do
#     field :token, :binary
#     field :context, :string
#     field :sent_to, :string
#     belongs_to :user, ClassEase.Accounts.User

#     timestamps(type: :utc_datetime, updated_at: false)
#   end

#   def build_session_token(user) do
#     token = :crypto.strong_rand_bytes(@rand_size)
#     {token, %UserToken{token: token, context: "session", user_id: user.id}}
#   end

#   def build_email_token(user, context) do
#     build_hashed_token(user, context, user.email)
#   end

#   defp build_hashed_token(user, context, sent_to) do
#     token = :crypto.strong_rand_bytes(@rand_size)
#     hashed_token = :crypto.hash(@hash_algorithm, token)

#     {Base.url_encode64(token, padding: false),
#      %UserToken{
#        token: hashed_token,
#        context: context,
#        sent_to: sent_to,
#        user_id: user.id
#      }}
#   end

#   def days_for_context("confirm"), do: @confirm_validity_in_days
#   def days_for_context("reset_password"), do: @reset_password_validity_in_days

#   def token_and_context_query(token, context) do
#     case Base.url_decode64(token, padding: false) do
#       {:ok, decoded_token} ->
#         hashed_token = :crypto.hash(@hash_algorithm, decoded_token)
#         days = days_for_context(context)

#         from token in token_and_context_query(hashed_token, context),
#           where: token.inserted_at > ago(^days, "day")

#       :error ->
#         :error
#     end
#   end

#   def token_and_context_query(hashed_token, context) do
#     from UserToken, where: [token: ^hashed_token, context: ^context]
#   end

#   def user_and_contexts_query(user, :all) do
#     from t in UserToken, where: t.user_id == ^user.id
#   end

#   def user_and_contexts_query(user, [_ | _] = contexts) do
#     from t in UserToken, where: t.user_id == ^user.id and t.context in ^contexts
#   end

#   def expired_tokens_query(context) do
#     days = days_for_context(context)

#     from token in UserToken,
#       where: token.context == ^context and token.inserted_at < ago(^days, "day")
#   end

#   def verify_session_token_query(token) do
#     case token_and_context_query(token, "session") do
#       :error ->
#         :error

#       query ->
#         session_query =
#           from token in query,
#             join: user in assoc(token, :user),
#             where: token.inserted_at > ago(@session_validity_in_days, "day"),
#             select: user

#         {:ok, session_query}
#     end
#   end

#   def verify_email_token_query(token, context) do
#     case token_and_context_query(token, context) do
#       :error -> :error
#       query -> {:ok, query}
#     end
#   end
# end



defmodule ClassEase.Accounts.UserToken do
  use Ecto.Schema
  import Ecto.Query
  alias ClassEase.Accounts.UserToken

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @hash_algorithm :sha256
  @rand_size 32

  # It is very important to keep the reset password token expiry short,
  # since someone with access to the email may take over the account.
  @reset_password_validity_in_days 1
  @confirm_validity_in_days 7
  @change_email_validity_in_days 7
  @session_validity_in_days 60

  schema "user_tokens" do
    field :token, :binary
    field :context, :string
    field :sent_to, :string
    belongs_to :user, ClassEase.Accounts.User

    timestamps(type: :utc_datetime, updated_at: false)
  end

  @doc """
  Generates a token that will be stored in a signed place,
  such as session or cookie. As they are signed, those
  tokens do not need to be hashed.

  The reason why we store session tokens in the database, even
  though Phoenix already provides a session cookie, is because
  Phoenix' default session cookies are not persisted, they are
  simply signed and potentially encrypted. This means they are
  valid indefinitely, unless you change the signing/encryption
  salt.

  Therefore, storing them allows individual user
  sessions to be expired. The token system can also be extended
  to store additional data, such as the device used for logging in.
  It could also be extended to federate logins across multiple
  applications and backends.

  On logout, we could simply remove all tokens for a given user.
  Tokens are currently expected to be at least 8 characters long.
  """
  def build_session_token(user) do
    token = :crypto.strong_rand_bytes(@rand_size)
    {token, %UserToken{token: token, context: "session", user_id: user.id}}
  end

  @doc """
  Checks if the token is valid and returns its underlying lookup query.

  The query returns the user found by the token, if any.

  The token is valid if it matches the value in the database and it has
  not expired (after @session_validity_in_days).
  """
  def verify_session_token_query(token) do
    query =
      from token in by_token_and_context_query(token, "session"),
        join: user in assoc(token, :user),
        where: token.inserted_at > ago(@session_validity_in_days, "day"),
        select: user

    {:ok, query}
  end

  @doc """
  Builds a token and its hash to be delivered to the user's email.

  The non-hashed token is sent to the user email while the
  hashed part is stored in the database. The original token cannot be reconstructed,
  which means anyone with read-only access to the database cannot directly use
  the token in the application to gain access. Furthermore, if the user changes
  their email, all tokens sent to the previous email are no longer valid.

  Users can easily adapt the existing code to provide other types of delivery
  methods, for example, by phone numbers.
  """
  def build_email_token(user, context) do
    build_hashed_token(user, context, user.email)
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

  This is used to validate tokens on actions like confirm instructions.
  """
  def verify_email_token_query(token, context) do
    case Base.url_decode64(token, padding: false) do
      {:ok, decoded_token} ->
        hashed_token = :crypto.hash(@hash_algorithm, decoded_token)
        days = days_for_context(context)

        query =
          from token in by_token_and_context_query(hashed_token, context),
            join: user in assoc(token, :user),
            where: token.inserted_at > ago(^days, "day") and token.sent_to == user.email,
            select: user

        {:ok, query}

      :error ->
        :error
    end
  end

  defp days_for_context("confirm"), do: @confirm_validity_in_days
  defp days_for_context("reset_password"), do: @reset_password_validity_in_days
  defp days_for_context("change_email"), do: @change_email_validity_in_days

  @doc """
  Returns the token struct for the given token value and context.
  """
  def by_token_and_context_query(token, context) do
    from UserToken, where: [token: ^token, context: ^context]
  end

  @doc """
  Gets all tokens for the given user for the given contexts.
  """
  def by_user_and_contexts_query(user, :all) do
    from t in UserToken, where: t.user_id == ^user.id
  end

  def by_user_and_contexts_query(user, [_ | _] = contexts) do
    from t in UserToken, where: t.user_id == ^user.id and t.context in ^contexts
  end
end
