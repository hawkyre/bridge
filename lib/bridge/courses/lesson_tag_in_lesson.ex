defmodule Bridge.Courses.LessonTagInLesson do
  @moduledoc """
  Join table for the many-to-many relationship between lessons and lesson tags.

  This allows lessons to have multiple tags and tags to be associated
  with multiple lessons for flexible categorization.
  """

  use TypedEctoSchema
  import Ecto.Changeset

  alias Bridge.Courses.{Lesson, LessonTag}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  typed_schema "lesson_tag_in_lesson" do
    belongs_to :lesson, Lesson
    belongs_to :lesson_tag, LessonTag

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(lesson_tag_in_lesson, attrs) do
    lesson_tag_in_lesson
    |> cast(attrs, [:lesson_id, :lesson_tag_id])
    |> validate_required([:lesson_id, :lesson_tag_id])
    |> unique_constraint([:lesson_id, :lesson_tag_id])
    |> foreign_key_constraint(:lesson_id)
    |> foreign_key_constraint(:lesson_tag_id)
  end
end
