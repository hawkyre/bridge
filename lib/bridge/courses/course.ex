defmodule Bridge.Courses.Course do
  @moduledoc """
  A course that teaches a specific language.

  Courses contain grammar lessons and vocabulary cards, and support
  multiple instruction languages for internationalization.
  """

  use TypedEctoSchema
  import Ecto.Changeset

  alias Bridge.Courses.{Lesson, VocabularyList, Card}
  alias Bridge.Format.Slug
  alias Bridge.Format.LanguageCode

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  typed_schema "courses" do
    field :title, :string
    field :description, :string
    field :slug, :string
    field :taught_language_code, :string
    field :instruction_language_code, :string
    field :visible, :boolean, default: false

    has_many :lessons, Lesson
    has_many :vocabulary_lists, VocabularyList
    has_many :cards, Card

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(course, attrs) do
    course
    |> cast(attrs, [
      :title,
      :description,
      :slug,
      :taught_language_code,
      :instruction_language_code,
      :visible
    ])
    |> validate_required([
      :title,
      :description,
      :slug,
      :taught_language_code,
      :instruction_language_code
    ])
    |> validate_length(:title, max: 100)
    |> validate_length(:description, max: 2000)
    |> validate_length(:slug, max: 70)
    |> validate_length(:taught_language_code, max: 5)
    |> validate_length(:instruction_language_code, max: 5)
    |> Slug.validate()
    |> LanguageCode.validate(:taught_language_code)
    |> LanguageCode.validate(:instruction_language_code)
    |> unique_constraint(:slug)
  end

  @doc """
  Changeset for creating a course with default visibility set to false.
  """
  def create_changeset(course, attrs) do
    course
    |> changeset(attrs)
    |> put_change(:visible, false)
  end
end
