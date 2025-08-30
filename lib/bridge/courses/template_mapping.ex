defmodule Bridge.Courses.TemplateMapping do
  @moduledoc """
  Mappings that define how card template fields are used in different contexts.

  Examples of use cases: display, flashcard, study_mode, etc.
  Mappings contain template strings that reference field keys from the template.
  """

  use TypedEctoSchema
  import Ecto.Changeset

  alias Bridge.Repo
  alias Bridge.Courses.CardTemplate
  alias Bridge.Courses.MappingField

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  typed_schema "template_mappings" do
    field :use_case, :string
    field :mapping, {:array, :map}

    belongs_to :card_template, CardTemplate

    timestamps(type: :utc_datetime)
  end

  @doc false
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(template_mapping, attrs) do
    template_mapping
    |> cast(attrs, [:use_case, :mapping, :card_template_id])
    |> validate_required([:use_case, :mapping, :card_template_id])
    |> validate_length(:use_case, max: 50)
    |> foreign_key_constraint(:card_template_id)
    |> validate_mapping_structure()
  end

  def create_changeset(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
  end

  @doc """
  Validates the mapping structure.

  Each mapping should be a list of objects with:
  - key: string identifier
  - value: template string that can reference template fields
  """
  @spec validate_mapping_structure(Ecto.Changeset.t()) :: Ecto.Changeset.t()
  def validate_mapping_structure(changeset) do
    template_id = get_field(changeset, :card_template_id)
    template = Repo.get(CardTemplate, template_id)

    case get_field(changeset, :mapping) do
      nil ->
        changeset

      mapping when is_list(mapping) ->
        validated_mappings =
          Enum.map(
            mapping,
            &(MappingField.create_changeset(&1, template) |> apply_action(:validate))
          )

        if Enum.all?(validated_mappings, &match?({:ok, _}, &1)) do
          changeset
        else
          add_error(changeset, :mapping, "invalid mapping structure")
        end

      _invalid ->
        add_error(changeset, :mapping, "must be a list of mapping definitions")
    end
  end
end
