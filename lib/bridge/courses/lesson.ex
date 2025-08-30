defmodule Bridge.Courses.Lesson do
  @moduledoc """
  Grammar lessons containing educational content in markdown format.

  Lessons are ordered within a course, have difficulty levels, and can be
  tagged for easy categorization and discovery.
  """

  use TypedEctoSchema
  import Ecto.Changeset

  alias Bridge.Courses.{Course, LessonTag}
  alias Bridge.Format.Slug

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  typed_schema "lessons" do
    field :order, :integer
    field :level, :string
    field :title, :string
    field :description, :string
    field :slug, :string
    field :markdown_content, :string
    field :visible, :boolean, default: false

    belongs_to :course, Course
    many_to_many :lesson_tags, LessonTag, join_through: "lesson_tag_in_lesson"

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(lesson, attrs) do
    lesson
    |> cast(attrs, [
      :order,
      :level,
      :title,
      :description,
      :slug,
      :markdown_content,
      :visible,
      :course_id
    ])
    |> validate_required([
      :order,
      :level,
      :title,
      :description,
      :slug,
      :markdown_content,
      :course_id
    ])
    |> validate_length(:level, max: 30)
    |> validate_length(:title, max: 100)
    |> validate_length(:description, max: 2000)
    |> validate_length(:slug, max: 50)
    |> validate_number(:order, greater_than: 0)
    |> Slug.validate()
    |> unique_constraint([:course_id, :slug])
    |> foreign_key_constraint(:course_id)
  end

  @doc """
  Changeset for creating a lesson with default visibility set to false.
  """
  def create_changeset(lesson, attrs) do
    lesson
    |> changeset(attrs)
    |> put_change(:visible, false)
  end
end
