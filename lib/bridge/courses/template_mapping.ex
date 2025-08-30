defmodule Bridge.Courses.TemplateMapping do
  @moduledoc """
  Mappings that define how card template fields are used in different contexts.

  Examples of use cases: display, flashcard, study_mode, etc.
  Mappings contain template strings that reference field keys from the template.
  """

  use TypedEctoSchema
  import Ecto.Changeset

  alias Bridge.Courses.CardTemplate

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @valid_mapping_map_keys ~w(key value)

  typed_schema "template_mappings" do
    field :use_case, :string
    field :mapping, {:array, :map}

    belongs_to :card_template, CardTemplate

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(template_mapping, attrs) do
    template_mapping
    |> cast(attrs, [:use_case, :mapping, :card_template_id])
    |> validate_required([:use_case, :mapping, :card_template_id])
    |> validate_length(:use_case, max: 50)
    |> validate_mapping_structure()
    |> foreign_key_constraint(:card_template_id)
  end

  @doc """
  Validates the mapping structure.

  Each mapping should be a list of objects with:
  - key: string identifier
  - value: template string that can reference template fields
  """
  def validate_mapping_structure(changeset) do
    case get_field(changeset, :mapping) do
      nil ->
        changeset

      mapping when is_list(mapping) ->
        if valid_mapping_structure?(mapping) do
          changeset
        else
          add_error(changeset, :mapping, "invalid mapping structure")
        end

      _invalid ->
        add_error(changeset, :mapping, "must be a list of mapping definitions")
    end
  end

  defp valid_mapping_structure?(mapping) when is_list(mapping) do
    Enum.all?(mapping, &valid_mapping_definition?/1)
  end

  defp valid_mapping_definition?(%{"key" => key, "value" => value} = map)
       when is_binary(key) and is_binary(value) do
    String.match?(key, ~r/^[a-z_][a-z0-9_]*$/) and
      Enum.all?(Map.keys(map), &(&1 in @valid_mapping_map_keys))
  end

  defp valid_mapping_definition?(_), do: false
end
