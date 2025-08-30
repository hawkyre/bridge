defmodule Bridge.Courses.MappingField do
  @moduledoc """
  A field in a mapping.

  TODO - add different field types and validate them
  """

  @valid_field_types ["text"]

  alias Bridge.Courses.CardTemplate
  alias Bridge.Format.Key

  use TypedEctoSchema
  import Ecto.Changeset

  typed_embedded_schema do
    field :key, :string
    field :value, :string
    field :type, :string
  end

  @doc false
  @spec changeset(t(), map(), CardTemplate.t() | nil) :: Ecto.Changeset.t()
  def changeset(mapping_field, attrs, template) do
    mapping_field
    |> cast(attrs, [:key, :value, :type])
    |> validate_required([:key, :value, :type])
    |> validate_length(:key, max: 100)
    |> validate_length(:value, max: 300)
    |> validate_inclusion(:type, @valid_field_types)
    |> Key.validate()
    |> validate_value(template)
  end

  defp validate_value(changeset, nil), do: changeset

  defp validate_value(changeset, template) do
    template_field_keys = template.fields |> Enum.map(& &1["key"])

    case get_field(changeset, :value) do
      nil ->
        changeset

      value ->
        captures = Regex.scan(value_regex(), value)

        cond do
          captures == [] ->
            add_error(changeset, :value, "must contain at least one template field key")

          Enum.all?(captures, fn [_, capture] -> capture in template_field_keys end) ->
            changeset

          true ->
            add_error(changeset, :value, "must contain only template field keys")
        end
    end
  end

  defp value_regex, do: Regex.compile!("\{\{(#{Key.regex(:string)})\}\}")
end
