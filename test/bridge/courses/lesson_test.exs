defmodule Bridge.Courses.LessonTest do
  use Bridge.DataCase, async: true

  alias Bridge.Courses.{Lesson, Course}
  import Bridge.Factory

  describe "changeset/2" do
    test "valid changeset with all required fields" do
      course = insert(:course)

      valid_attrs = %{
        order: 1,
        level: "beginner",
        title: "Introduction to Spanish",
        description: "Learn basic Spanish greetings and introductions",
        slug: "introduction-spanish",
        markdown_content: "# Hello\n\nWelcome to Spanish!",
        visible: true,
        course_id: course.id
      }

      changeset = Lesson.create_changeset(valid_attrs)

      assert changeset.valid?
      assert get_change(changeset, :order) == 1
      assert get_change(changeset, :level) == "beginner"
      assert get_change(changeset, :title) == "Introduction to Spanish"

      assert get_change(changeset, :description) ==
               "Learn basic Spanish greetings and introductions"

      assert get_change(changeset, :slug) == "introduction-spanish"
      assert get_change(changeset, :markdown_content) == "# Hello\n\nWelcome to Spanish!"
      refute get_change(changeset, :visible)
      assert get_change(changeset, :course_id) == course.id
    end

    test "valid changeset without visibility (defaults to false)" do
      course = insert(:course)

      valid_attrs = %{
        order: 1,
        level: "beginner",
        title: "Introduction to Spanish",
        description: "Learn basic Spanish greetings and introductions",
        slug: "introduction-spanish",
        markdown_content: "# Hello\n\nWelcome to Spanish!",
        course_id: course.id
      }

      changeset = Lesson.create_changeset(valid_attrs)

      assert changeset.valid?
      # visible defaults to false in schema
      assert get_field(changeset, :visible) == false
    end

    test "validates unique constraint on course_id and slug" do
      course = insert(:course)
      attrs = params_for(:lesson, course_id: course.id)

      # Insert first lesson
      Lesson.create_changeset(attrs) |> Repo.insert!()

      # Try to insert second lesson with same course_id and slug
      changeset = Lesson.create_changeset(attrs)
      {:error, changeset} = Repo.insert(changeset)

      assert "has already been taken" in errors_on(changeset).course_id
    end

    test "allows same slug in different courses" do
      course1 = insert(:course, slug: "course-1")
      course2 = insert(:course, slug: "course-2")

      attrs1 = params_for(:lesson, course_id: course1.id, slug: "intro")
      attrs2 = params_for(:lesson, course_id: course2.id, slug: "intro")

      # Both should succeed
      assert {:ok, _} = Lesson.create_changeset(attrs1) |> Repo.insert()
      assert {:ok, _} = Lesson.create_changeset(attrs2) |> Repo.insert()
    end
  end

  describe "create_changeset/2" do
    test "sets visibility to false by default" do
      course = insert(:course)
      attrs = params_for(:lesson, course_id: course.id, visible: true)

      changeset = Lesson.create_changeset(attrs)

      assert changeset.valid?
      refute get_change(changeset, :visible)
    end

    test "overrides visible field even if provided as true" do
      course = insert(:course)
      attrs = params_for(:lesson, course: course, visible: true)

      changeset = Lesson.create_changeset(attrs)

      assert get_change(changeset, :visible) != true
    end
  end
end
