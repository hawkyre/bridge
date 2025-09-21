defmodule Bridge.Courses.TemplateField do
  @moduledoc """
  A field in a template.
  """
  alias Bridge.Format.Key

  @valid_types ~w(short_text long_text audio_url image_url single_choice multiple_choice examples)

  use TypedEctoSchema
  import Ecto.Changeset

  typed_embedded_schema do
    field :key, :string
    field :name, :string
    field :type, :string
    field :required, :boolean, default: false
    field :metadata, :map
  end

  @doc """
  Validates a template field.
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(template_field, attrs) do
    template_field
    |> cast(attrs, [:key, :name, :type, :required, :metadata])
    |> validate_required([:key, :name, :type])
    |> validate_length(:key, max: 100)
    |> validate_length(:name, max: 100)
    |> validate_inclusion(:type, @valid_types)
    |> Key.validate()
    |> validate_metadata()
  end

  def create_changeset(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
  end

  @spec validate_metadata(Ecto.Changeset.t()) :: Ecto.Changeset.t()
  defp validate_metadata(changeset) do
    case get_change(changeset, :type) do
      choice_type when choice_type in ["single_choice", "multiple_choice"] ->
        validate_metadata_choices(changeset)

      _ ->
        changeset
    end
  end

  @spec validate_metadata_choices(Ecto.Changeset.t()) :: Ecto.Changeset.t()
  defp validate_metadata_choices(changeset) do
    metadata = get_change(changeset, :metadata, %{})
    choices = Map.get(metadata, "choices")

    if is_list(choices) and Enum.all?(choices, &is_binary/1) do
      changeset
    else
      add_error(
        changeset,
        :metadata,
        "choice types' metadata must have a list of choices"
      )
    end
  end
end
