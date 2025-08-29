defmodule Bridge.Courses.VocabularyListCard do
  @moduledoc """
  Join table for the many-to-many relationship between vocabulary lists and cards.

  This allows vocabulary lists to contain multiple cards and cards to appear
  in multiple lists for flexible organization of study materials.
  """

  use TypedEctoSchema
  import Ecto.Changeset

  alias Bridge.Courses.{VocabularyList, Card}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  typed_schema "vocabulary_list_cards" do
    belongs_to :vocabulary_list, VocabularyList
    belongs_to :card, Card

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(vocabulary_list_card, attrs) do
    vocabulary_list_card
    |> cast(attrs, [:vocabulary_list_id, :card_id])
    |> validate_required([:vocabulary_list_id, :card_id])
    |> unique_constraint([:card_id, :vocabulary_list_id])
    |> foreign_key_constraint(:vocabulary_list_id)
    |> foreign_key_constraint(:card_id)
  end
end
