defmodule Bridge.Courses.VocabularyList do
  @moduledoc """
  Organized collections of vocabulary cards within a course.

  Vocabulary lists help group related cards for study purposes
  and provide SEO-friendly URLs for content discovery.
  """

  use TypedEctoSchema
  import Ecto.Changeset

  alias Bridge.Courses.{Course, Card}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  typed_schema "vocabulary_lists" do
    field :name, :string
    field :slug, :string

    belongs_to :course, Course
    many_to_many :cards, Card, join_through: "vocabulary_list_cards"

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(vocabulary_list, attrs) do
    vocabulary_list
    |> cast(attrs, [:name, :slug, :course_id])
    |> validate_required([:name, :slug, :course_id])
    |> validate_length(:name, max: 200)
    |> validate_length(:slug, max: 50)
    |> validate_format(:slug, ~r/^[a-z0-9-]+$/,
      message: "must only contain lowercase letters, numbers, and hyphens"
    )
    |> unique_constraint(:slug)
    |> foreign_key_constraint(:course_id)
  end
end
