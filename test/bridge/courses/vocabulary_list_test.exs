defmodule Bridge.Courses.VocabularyListTest do
  use Bridge.DataCase, async: true

  alias Bridge.Courses.{VocabularyList, Course}
  import Bridge.Factory

  describe "changeset/2" do
    test "valid changeset with all required fields" do
      course = insert(:course)

      valid_attrs = %{
        name: "Basic Spanish Words",
        slug: "basic-spanish-words",
        course_id: course.id
      }

      changeset = VocabularyList.create_changeset(valid_attrs)

      assert changeset.valid?
      assert get_change(changeset, :name) == "Basic Spanish Words"
      assert get_change(changeset, :slug) == "basic-spanish-words"
      assert get_change(changeset, :course_id) == course.id
    end

    test "invalid changeset with missing required fields" do
      changeset = VocabularyList.create_changeset(%{})

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).name
      assert "can't be blank" in errors_on(changeset).slug
      assert "can't be blank" in errors_on(changeset).course_id
    end

    test "validates unique constraint on slug" do
      course = insert(:course)

      attrs = %{
        name: "Basic Spanish Words",
        slug: "basic-spanish-words",
        course_id: course.id
      }

      # Insert first vocabulary list
      VocabularyList.create_changeset(attrs) |> Repo.insert!()

      # Try to insert second vocabulary list with same slug
      duplicate_attrs = %{
        name: "Different Name",
        # Same slug
        slug: "basic-spanish-words",
        course_id: course.id
      }

      changeset = VocabularyList.create_changeset(duplicate_attrs)
      {:error, changeset} = Repo.insert(changeset)

      assert "has already been taken" in errors_on(changeset).slug
    end

    test "validates foreign key constraint for course_id" do
      attrs = %{
        name: "Basic Spanish Words",
        slug: "basic-spanish-words",
        course_id: Ecto.UUID.generate()
      }

      changeset = VocabularyList.create_changeset(attrs)
      assert changeset.valid?

      {:error, changeset} = Repo.insert(changeset)
      assert "does not exist" in errors_on(changeset).course_id
    end
  end
end
