defmodule Bridge.Courses.TagTranslation do
  @moduledoc """
  Translations for tags in different languages.

  Allows tags to be displayed in multiple languages based on
  the user's preferred language or course instruction language.
  """

  use TypedEctoSchema
  import Ecto.Changeset

  alias Bridge.Courses.Tag
  alias Bridge.Format.LanguageCode

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  typed_schema "tag_translations" do
    field :language_code, :string
    field :name, :string

    belongs_to :tag, Tag

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(tag_translation, attrs) do
    tag_translation
    |> cast(attrs, [:language_code, :name, :tag_id])
    |> validate_required([:language_code, :name, :tag_id])
    |> validate_length(:language_code, max: 5)
    |> validate_length(:name, max: 100)
    |> LanguageCode.validate()
    |> unique_constraint([:tag_id, :language_code])
    |> foreign_key_constraint(:tag_id)
  end

  def create_changeset(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
  end
end
