# defmodule ClassEase.Accounts.User do
#   use Ecto.Schema
#   import Ecto.Changeset

#   @primary_key {:id, :binary_id, autogenerate: true}
#   @foreign_key_type :binary_id

#   schema "users" do
#     field :email, :string
#     field :password, :string, virtual: true, redact: true
#     field :password_hash, :string, redact: true
#     field :name, :string
#     field :role, :string, default: "teacher"
#     field :subscription_tier, :string, default: "free"
#     field :pdf_count, :integer, default: 0
#     field :pdf_reset_date, :date
#     field :email_verified, :boolean, default: false
#     field :oauth_provider, :string
#     field :oauth_uid, :string
#     field :created_classes_count, :integer, default: 0
#     field :last_login_at, :utc_datetime
#     field :preferences, :map, default: %{}

#     timestamps(type: :utc_datetime)
#   end

#   def registration_changeset(user, attrs, opts \\ []) do
#     user
#     |> cast(attrs, [:email, :password, :name, :subscription_tier])
#     |> validate_email(opts)
#     |> validate_password(opts)
#     |> validate_required([:name])
#     |> validate_subscription_tier()
#   end

#   def login_changeset(user, attrs, opts \\ []) do
#     user
#     |> cast(attrs, [:email, :password])
#     |> validate_email(opts)
#     |> validate_password(opts)
#   end

#   defp validate_email(changeset, opts) do
#     changeset
#     |> validate_required([:email])
#     |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
#     |> validate_length(:email, max: 160)
#     |> maybe_validate_unique_email(opts)
#   end

#   defp validate_password(changeset, opts) do
#     changeset
#     |> validate_required([:password])
#     |> validate_length(:password, min: 8, max: 72)
#     |> validate_format(:password, ~r/[a-z]/, message: "at least one lower case character")
#     |> validate_format(:password, ~r/[A-Z]/, message: "at least one upper case character")
#     |> validate_format(:password, ~r/[!?@#$%^&*_0-9]/,
#       message: "at least one digit or punctuation character"
#     )
#     |> maybe_hash_password(opts)
#   end

#   defp validate_subscription_tier(changeset) do
#     validate_inclusion(changeset, :subscription_tier, ["free", "teacher", "school"])
#   end

#   defp maybe_hash_password(changeset, opts) do
#     hash_password? = Keyword.get(opts, :hash_password, true)
#     password = get_change(changeset, :password)

#     if hash_password? && password && changeset.valid? do
#       changeset
#       |> validate_length(:password, max: 72, count: :bytes)
#       |> put_change(:password_hash,Pbkdf2.hash_pwd_salt(password)) # Bcrypt.hash_pwd_salt(password))
#       |> delete_change(:password)
#     else
#       changeset
#     end
#   end

#   defp maybe_validate_unique_email(changeset, opts) do
#     if Keyword.get(opts, :validate_email, true) do
#       changeset
#       |> unsafe_validate_unique(:email, ClassEase.Repo)
#       |> unique_constraint(:email)
#     else
#       changeset
#     end
#   end

#   def valid_password?(%ClassEase.Accounts.User{password_hash: hashed_password}, password)
#       when is_binary(hashed_password) and byte_size(password) > 0 do
#     # Bcrypt.verify_pass(password, hashed_password)
#     Pbkdf2.verify_pass(password, hashed_password)
#   end

#   def valid_password?(_, _) do
#     # Bcrypt.no_user_verify()
#     Pbkdf2.no_user_verify()
#     false
#   end
# end



defmodule ClassEase.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @subscription_tiers ["free", "teacher", "school"]
  # @roles ["teacher", "admin"]

  schema "users" do
    field :email, :string
    field :password_hash, :string
    field :password, :string, virtual: true, redact: true
    field :password_confirmation, :string, virtual: true, redact: true
    field :name, :string
    field :role, :string, default: "teacher"
    field :subscription_tier, :string, default: "free"
    field :pdf_count, :integer, default: 0
    field :pdf_reset_date, :date
    field :email_verified, :boolean, default: false
    field :oauth_provider, :string
    field :oauth_uid, :string
    field :created_classes_count, :integer, default: 0
    field :last_login_at, :utc_datetime
    field :preferences, :map, default: %{}

    has_many :tokens, ClassEase.Accounts.UserToken

    timestamps(type: :utc_datetime)
  end

  @doc """
  A user changeset for registration.
  """
  def registration_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:email, :password, :password_confirmation, :name, :subscription_tier])
    |> validate_email(opts)
    |> validate_password(opts)
    |> validate_name()
    |> validate_subscription_tier()
    |> validate_confirmation(:password, message: "does not match password")
  end

  @doc """
  A user changeset for OAuth registration.
  """
  def oauth_changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :name, :oauth_provider, :oauth_uid])
    |> validate_email([])
    |> validate_name()
    |> validate_required([:oauth_provider, :oauth_uid])
    |> put_change(:email_verified, true)
  end

  @doc """
  A user changeset for changing the password.
  """
  def password_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:password, :password_confirmation])
    |> validate_confirmation(:password, message: "does not match password")
    |> validate_password(opts)
    |> maybe_hash_password(opts)
  end

  @doc """
  A changeset for changing the email.
  """
  def email_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:email])
    |> validate_email(opts)
    |> case do
      %{changes: %{email: _}} = changeset ->
        changeset |> put_change(:email_verified, false)
      changeset ->
        changeset
    end
  end

  @doc """
  Verifies the password.
  """
  def valid_password?(%ClassEase.Accounts.User{password_hash: hashed_password}, password)
      when is_binary(hashed_password) and byte_size(password) > 0 do
    Pbkdf2.verify_pass(password, hashed_password)
  end

  def valid_password?(_, _) do
    Pbkdf2.no_user_verify()
    false
  end

  @doc """
  Validates the current password otherwise adds an error to the changeset.
  """
  def validate_current_password(changeset, password) do
    if valid_password?(changeset.data, password) do
      changeset
    else
      add_error(changeset, :current_password, "is not valid")
    end
  end

  defp validate_email(changeset, opts) do
    changeset
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> validate_length(:email, max: 160)
    |> maybe_validate_unique_email(opts)
  end

  defp validate_password(changeset, opts) do
    changeset
    |> validate_required([:password])
    |> validate_length(:password, min: 8, max: 72)
    |> validate_format(:password, ~r/[a-z]/, message: "at least one lower case character")
    |> validate_format(:password, ~r/[A-Z]/, message: "at least one upper case character")
    |> validate_format(:password, ~r/[!?@#$%^&*_0-9]/, message: "at least one digit or punctuation character")
    |> maybe_hash_password(opts)
  end

  defp validate_name(changeset) do
    changeset
    |> validate_required([:name])
    |> validate_length(:name, min: 2, max: 50)
    |> validate_format(:name, ~r/^[a-zA-Z\s]+$/, message: "must contain only letters and spaces")
  end

  defp validate_subscription_tier(changeset) do
    changeset
    |> validate_inclusion(:subscription_tier, @subscription_tiers)
  end

  defp maybe_hash_password(changeset, opts) do
    hash_password? = Keyword.get(opts, :hash_password, true)
    password = get_change(changeset, :password)

    if hash_password? && password && changeset.valid? do
      changeset
      |> validate_length(:password, max: 72, count: :bytes)
      |> put_change(:password_hash, Pbkdf2.hash_pwd_salt(password))
      |> delete_change(:password)
    else
      changeset
    end
  end

  defp maybe_validate_unique_email(changeset, opts) do
    if Keyword.get(opts, :validate_email, true) do
      changeset
      |> unsafe_validate_unique(:email, ClassEase.Repo)
      |> unique_constraint(:email)
    else
      changeset
    end
  end

  def confirm_changeset(user) do
    change(user, email_verified: true)
  end
end
