defmodule Bridge.Format.SlugTest do
  use Bridge.DataCase, async: true

  alias Bridge.Format.Slug
  import Ecto.Changeset

  describe "validate/1" do
    test "accepts valid slugs" do
      valid_slugs = [
        "spanish",
        "spanish-2-beginners",
        "a1-dutch",
        "english-advanced",
        "course-123",
        "test",
        "long-slug-with-many-segments",
        "a",
        "course1"
      ]

      for slug <- valid_slugs do
        changeset = cast({%{}, %{slug: :string}}, %{slug: slug}, [:slug])
        result = Slug.validate(changeset)

        assert result.valid?,
               "Expected '#{slug}' to be valid but got errors: #{inspect(result.errors)}"
      end
    end

    test "rejects invalid slugs" do
      invalid_cases = [
        "1spanish",
        "-spanish",
        "Spanish",
        "Spanish-Course",
        "camelCase",
        "spanish_course",
        "spanish.course",
        "spanish course",
        "spanish@course",
        "spanish/course",
        "spanish--course",
        "spanish-"
      ]

      for slug <- invalid_cases do
        changeset = cast({%{}, %{slug: :string}}, %{slug: slug}, [:slug])
        result = Slug.validate(changeset)

        refute result.valid?, "Expected '#{slug}' to be invalid"
      end
    end
  end
end
