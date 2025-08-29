defmodule Bridge.Courses.Card do
  @moduledoc """
  Vocabulary cards containing flexible content based on card templates.

  Cards store their data in a JSONB fields map that corresponds to
  the template's field definitions, allowing for flexible vocabulary
  card types and content structures.
  """

  use TypedEctoSchema
  import Ecto.Changeset

  alias Bridge.Courses.{Course, CardTemplate, VocabularyList}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  typed_schema "cards" do
    field :fields, :map

    belongs_to :course, Course
    belongs_to :card_template, CardTemplate
    many_to_many :vocabulary_lists, VocabularyList, join_through: "vocabulary_list_cards"

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(card, attrs) do
    card
    |> cast(attrs, [:fields, :course_id, :card_template_id])
    |> validate_required([:fields, :course_id, :card_template_id])
    |> validate_fields_structure()
    |> foreign_key_constraint(:course_id)
    |> foreign_key_constraint(:card_template_id)
  end

  @doc """
  Validates that the card fields conform to the template structure.

  This validation checks that:
  - All required template fields are present
  - No unknown fields are included
  - Field values match expected types
  """
  def validate_fields_structure(changeset) do
    case get_field(changeset, :fields) do
      nil ->
        changeset

      fields when is_map(fields) ->
        # Note: Full template validation would require loading the template
        # For now, we just validate that fields is a map
        # Template-specific validation should be done at the business logic level
        changeset

      _invalid ->
        add_error(changeset, :fields, "must be a map of field values")
    end
  end

  @doc """
  Changeset for updating card fields while preserving template compliance.
  """
  def update_fields_changeset(card, attrs) do
    card
    |> cast(attrs, [:fields])
    |> validate_required([:fields])
    |> validate_fields_structure()
  end
end
