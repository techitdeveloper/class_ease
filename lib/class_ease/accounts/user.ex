defmodule ClassEase.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "users" do
    field :email, :string
    field :password, :string, virtual: true, redact: true
    field :password_hash, :string, redact: true
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

    timestamps()
  end

  # This is the main function that validates user data
  def registration_changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :password, :name, :subscription_tier])
    |> validate_required([:email, :password, :name])
    |> validate_email()
    |> validate_password()
    |> validate_name()
    |> validate_subscription_tier()
    |> unique_constraint(:email)
    |> put_password_hash()
  end

  # Validates the email format and uniqueness
  defp validate_email(changeset) do
    changeset
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+\.[^\s]+$/, message: "must be a valid email")
    |> validate_length(:email, max: 160)
    |> unsafe_validate_unique(:email, ClassEase.Repo)
  end

  # Validates the password strength
  defp validate_password(changeset) do
    changeset
    |> validate_length(:password,
      min: 8,
      max: 72,
      message: "must be between 8 and 128 characters"
    )
    |> validate_format(:password, ~r/[0-9]+/, message: "must contain at least one number")
    |> validate_format(:password, ~r/[A-Z]+/,
      message: "must contain at least one uppercase letter"
    )
    |> validate_format(:password, ~r/[a-z]+/,
      message: "must contain at least one lowercase letter"
    )
  end

  # Validates the name length
  defp validate_name(changeset) do
    changeset
    |> validate_length(:name, min: 2, max: 50, message: "must be between 1 and 100 characters")
    |> validate_format(:name, ~r/^[a-zA-Z\s]+$/, message: "can only contain letters and spaces")
  end

  # Validates the subscription tier
  defp validate_subscription_tier(changeset) do
    allowed_tiers = ["free", "teacher", "school"]
    validate_inclusion(changeset, :subscription_tier, allowed_tiers)
  end

  # Hashes the password before saving
  defp put_password_hash(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{password: password}} ->
        put_change(changeset, :password_hash, Pbkdf2.hash_pwd_salt(password))

      _ ->
        changeset
    end
  end

  # Check if password matches the stored hash
  def valid_password?(%__MODULE__{password_hash: hash}, password)
      when is_binary(hash) and byte_size(password) > 0 do
    Pbkdf2.verify_pass(password, hash)
  end

  def valid_password?(_, _) do
    Pbkdf2.no_user_verify()
    false
  end

  @doc """
  Changeset for email verification.
  """
  def email_verification_changeset(user) do
    user
    |> change(%{email_verified: true})
  end
end
