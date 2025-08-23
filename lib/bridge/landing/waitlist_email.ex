defmodule Bridge.Landing.WaitlistEmail do
  @moduledoc """
  A schema for email subscriptions.
  """

  use TypedEctoSchema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  typed_schema "waitlist_emails" do
    field :email, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(email_subscription, attrs) do
    email_subscription
    |> cast(attrs, [:email])
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> validate_length(:email, max: 160)
    |> unique_constraint(:email)
  end
end
