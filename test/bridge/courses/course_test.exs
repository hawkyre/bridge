defmodule Bridge.Courses.CourseTest do
  use Bridge.DataCase, async: true

  alias Bridge.Courses.Course
  import Bridge.Factory

  describe "changeset/2" do
    test "valid changeset with all required fields" do
      valid_attrs = %{
        title: "Spanish for Beginners",
        description: "Learn Spanish from scratch",
        slug: "spanish-beginners",
        taught_language_code: "es",
        instruction_language_code: "en",
        visible: true
      }

      changeset = Course.changeset(%Course{}, valid_attrs)

      assert changeset.valid?
      assert get_change(changeset, :title) == "Spanish for Beginners"
      assert get_change(changeset, :description) == "Learn Spanish from scratch"
      assert get_change(changeset, :slug) == "spanish-beginners"
      assert get_change(changeset, :taught_language_code) == "es"
      assert get_change(changeset, :instruction_language_code) == "en"
      assert get_change(changeset, :visible) == true
    end

    test "valid changeset without visibility (defaults to false)" do
      valid_attrs = params_for(:course) |> Map.delete(:visible)

      changeset = Course.changeset(%Course{}, valid_attrs)

      assert changeset.valid?

      assert get_field(changeset, :visible) == false
    end

    test "validates unique constraint on slug" do
      insert(:course, slug: "test-slug")

      attrs = params_for(:course, slug: "test-slug")

      changeset = Course.changeset(%Course{}, attrs)
      {:error, changeset} = Repo.insert(changeset)

      assert "has already been taken" in errors_on(changeset).slug
    end
  end

  describe "create_changeset/2" do
    test "sets visibility to false when creating a course" do
      attrs = params_for(:course) |> Map.put(:visible, true)

      changeset = Course.create_changeset(%Course{}, attrs)

      assert changeset.valid?
      refute get_change(changeset, :visible)
    end
  end
end
