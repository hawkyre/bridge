defmodule Bridge.Courses.TagTranslation do
  @moduledoc """
  Translations for lesson tags in different languages.

  Allows lesson tags to be displayed in multiple languages based on
  the user's preferred language or course instruction language.
  """

  use TypedEctoSchema
  import Ecto.Changeset

  alias Bridge.Courses.LessonTag

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  typed_schema "tag_translations" do
    field :language_code, :string
    field :name, :string

    belongs_to :lesson_tag, LessonTag

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(tag_translation, attrs) do
    tag_translation
    |> cast(attrs, [:language_code, :name, :lesson_tag_id])
    |> validate_required([:language_code, :name, :lesson_tag_id])
    |> validate_length(:language_code, max: 5)
    |> validate_length(:name, max: 100)
    |> validate_format(:language_code, ~r/^[a-z]{2}(-[a-z]{2})?$/,
      message: "must be a valid language code"
    )
    |> unique_constraint([:lesson_tag_id, :language_code])
    |> foreign_key_constraint(:lesson_tag_id)
  end
end
