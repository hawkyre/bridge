defmodule Bridge.Repo.Migrations.CreateEmailSubscriptions do
  use Ecto.Migration

  def change do
    create table(:email_subscriptions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :email, :string

      timestamps(type: :utc_datetime)
    end

    create unique_index(:email_subscriptions, [:email])
  end
end
