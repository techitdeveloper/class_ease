defmodule ClassEase.Repo do
  use Ecto.Repo,
    otp_app: :class_ease,
    adapter: Ecto.Adapters.Postgres
end
