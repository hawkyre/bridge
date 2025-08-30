defmodule Bridge.Courses.Tag do
  @moduledoc """
  Tags for categorizing anything (e.g., for lessons: verbs, adjectives, sentence forming).

  Tags support multiple languages through tag translations.
  """

  use TypedEctoSchema
  import Ecto.Changeset

  alias Bridge.Courses.TagTranslation

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  typed_schema "tags" do
    field :key, :string

    has_many :tag_translations, TagTranslation

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(tag, attrs) do
    tag
    |> cast(attrs, [:key])
    |> validate_required([:key])
    |> validate_length(:key, max: 40)
    |> validate_format(:key, ~r/^[a-z]+(_[a-z0-9]+)*$/,
      message: "must be a valid identifier (lowercase, numbers, underscores)"
    )
    |> unique_constraint(:key)
  end
end
