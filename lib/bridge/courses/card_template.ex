defmodule Bridge.Courses.CardTemplate do
  @moduledoc """
  Templates defining the structure and fields for vocabulary cards.

  Templates use flexible JSONB field definitions to support various
  card types (translation, explanation, etc.) with different field types
  and validation requirements.
  """

  use TypedEctoSchema
  import Ecto.Changeset

  alias Bridge.Courses.Card
  alias Bridge.Courses.TemplateField
  alias Bridge.Courses.TemplateMapping

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @field_types ~w(short_text long_text audio_url image_url single_choice multiple_choice examples)

  typed_schema "card_templates" do
    field :name, :string
    field :fields, {:array, :map}

    has_many :template_mappings, TemplateMapping
    has_many :cards, Card

    timestamps(type: :utc_datetime)
  end

  def create_changeset(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
  end

  @doc false
  def changeset(card_template, attrs) do
    card_template
    |> cast(attrs, [:name, :fields])
    |> validate_required([:name, :fields])
    |> validate_length(:name, max: 100)
    |> validate_template_fields()
  end

  defp validate_template_fields(changeset) do
    case get_field(changeset, :fields) do
      nil ->
        changeset

      [] ->
        add_error(changeset, :fields, "must have at least one field")

      fields when is_list(fields) ->
        validated_fields =
          Enum.map(
            fields,
            &(TemplateField.changeset(%TemplateField{}, &1) |> apply_action(:validate))
          )

        if Enum.all?(validated_fields, &match?({:ok, _}, &1)) do
          changeset
        else
          add_error(changeset, :fields, "invalid field structure")
        end

      _invalid ->
        add_error(changeset, :fields, "must be a list of field definitions")
    end
  end

  @doc """
  Returns the list of allowed field types.
  """
  def field_types, do: @field_types
end
