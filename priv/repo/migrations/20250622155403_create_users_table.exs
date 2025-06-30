defmodule ClassEase.Repo.Migrations.CreateUsersTable do
  use Ecto.Migration

  def change do
    create table(:users, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :email, :string, null: false
      add :password_hash, :string, null: false
      add :name, :string, null: false
      add :role, :string, default: "teacher"
      add :subscription_tier, :string, default: "free"
      add :pdf_count, :integer, default: 0
      add :pdf_reset_date, :date
      add :email_verified, :boolean, default: false
      add :oauth_provider, :string
      add :oauth_uid, :string
      add :created_classes_count, :integer, default: 0
      add :last_login_at, :utc_datetime
      add :preferences, :map, default: %{}

      timestamps()
    end

    create unique_index(:users, [:email])
    create index(:users, [:subscription_tier])
    create index(:users, [:email_verified])
    create index(:users, [:oauth_provider, :oauth_uid])
  end
end
