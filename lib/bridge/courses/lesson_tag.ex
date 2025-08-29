defmodule Bridge.Courses.LessonTag do
  @moduledoc """
  Tags for categorizing grammar lessons (e.g., verbs, adjectives, sentence forming).

  Tags support multiple languages through tag translations and can be
  associated with multiple lessons.
  """

  use TypedEctoSchema
  import Ecto.Changeset

  alias Bridge.Courses.{Course, TagTranslation, Lesson}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  typed_schema "lesson_tags" do
    field :key, :string

    belongs_to :course, Course
    has_many :tag_translations, TagTranslation
    many_to_many :lessons, Lesson, join_through: "lesson_tag_in_lesson"

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(lesson_tag, attrs) do
    lesson_tag
    |> cast(attrs, [:key, :course_id])
    |> validate_required([:key, :course_id])
    |> validate_length(:key, max: 40)
    |> validate_format(:key, ~r/^[a-z_][a-z0-9_]*$/,
      message: "must be a valid identifier (lowercase, numbers, underscores)"
    )
    |> unique_constraint(:key)
    |> foreign_key_constraint(:course_id)
  end
end
