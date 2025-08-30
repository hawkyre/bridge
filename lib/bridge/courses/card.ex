defmodule Bridge.Courses.Card do
  @moduledoc """
  Vocabulary cards containing flexible content based on card templates.

  Cards store their data in a JSONB fields map that corresponds to
  the template's field definitions, allowing for flexible vocabulary
  card types and content structures.
  """

  use TypedEctoSchema
  import Ecto.Changeset

  alias Bridge.Repo
  alias Bridge.Courses.{Course, CardTemplate, VocabularyList, CardField}

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

  def create_changeset(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
  end

  defp validate_fields_structure(changeset) do
    card_template_id = get_field(changeset, :card_template_id)
    card_template = Repo.get(CardTemplate, card_template_id)

    case get_field(changeset, :fields) do
      nil ->
        changeset

      fields when is_map(fields) ->
        valid_fields? =
          fields
          |> Enum.map(&CardField.validate(&1, card_template))
          |> Enum.all?(&match?(:ok, &1))

        if valid_fields? do
          changeset
        else
          add_error(changeset, :fields, "must be a map of valid field values")
        end

      _invalid ->
        add_error(changeset, :fields, "must be a map of valid field values")
    end
  end
end
