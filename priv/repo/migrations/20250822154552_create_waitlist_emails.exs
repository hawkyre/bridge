defmodule Bridge.Repo.Migrations.CreateWaitlistEmails do
  use Ecto.Migration

  def change do
    create table(:waitlist_emails, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :email, :string

      timestamps(type: :utc_datetime)
    end

    create unique_index(:waitlist_emails, [:email])
  end
end
