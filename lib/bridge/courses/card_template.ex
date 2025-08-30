defmodule Bridge.Courses.CardTemplate do
  @moduledoc """
  Templates defining the structure and fields for vocabulary cards.

  Templates use flexible JSONB field definitions to support various
  card types (translation, explanation, etc.) with different field types
  and validation requirements.
  """

  use TypedEctoSchema
  import Ecto.Changeset

  alias Bridge.Courses.{TemplateMapping, Card}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @field_types ~w(short_text long_text audio_url image_url single_choice multiple_choice examples)
  @valid_field_map_keys ~w(key type required)

  typed_schema "card_templates" do
    field :name, :string
    field :fields, {:array, :map}

    has_many :template_mappings, TemplateMapping
    has_many :cards, Card

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(card_template, attrs) do
    card_template
    |> cast(attrs, [:name, :fields])
    |> validate_required([:name, :fields])
    |> validate_length(:name, max: 100)
    |> validate_template_fields()
  end

  @doc """
  Validates the template fields structure.

  Each field should have:
  - key: string identifier
  - type: one of the allowed field types
  - required: boolean
  """
  def validate_template_fields(changeset) do
    case get_field(changeset, :fields) do
      nil ->
        changeset

      [] ->
        add_error(changeset, :fields, "must have at least one field")

      fields when is_list(fields) ->
        if valid_fields_structure?(fields) do
          changeset
        else
          add_error(changeset, :fields, "invalid field structure")
        end

      _invalid ->
        add_error(changeset, :fields, "must be a list of field definitions")
    end
  end

  defp valid_fields_structure?(fields) when is_list(fields) do
    Enum.all?(fields, &valid_field_definition?/1)
  end

  defp valid_field_definition?(%{"key" => key, "type" => type, "required" => required} = field)
       when is_binary(key) and type in @field_types and is_boolean(required) do
    String.match?(key, ~r/^[a-z_][a-z0-9_]*$/) and
      Enum.all?(Map.keys(field), &(&1 in @valid_field_map_keys))
  end

  defp valid_field_definition?(_), do: false

  @doc """
  Returns the list of allowed field types.
  """
  def field_types, do: @field_types
end
