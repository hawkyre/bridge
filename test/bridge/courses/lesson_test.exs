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

      changeset = Lesson.changeset(%Lesson{}, valid_attrs)

      assert changeset.valid?
      assert get_change(changeset, :order) == 1
      assert get_change(changeset, :level) == "beginner"
      assert get_change(changeset, :title) == "Introduction to Spanish"

      assert get_change(changeset, :description) ==
               "Learn basic Spanish greetings and introductions"

      assert get_change(changeset, :slug) == "introduction-spanish"
      assert get_change(changeset, :markdown_content) == "# Hello\n\nWelcome to Spanish!"
      assert get_change(changeset, :visible) == true
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

      changeset = Lesson.changeset(%Lesson{}, valid_attrs)

      assert changeset.valid?
      # visible defaults to false in schema
      assert get_field(changeset, :visible) == false
    end

    test "invalid changeset with missing required fields" do
      changeset = Lesson.changeset(%Lesson{}, %{})

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).order
      assert "can't be blank" in errors_on(changeset).level
      assert "can't be blank" in errors_on(changeset).title
      assert "can't be blank" in errors_on(changeset).description
      assert "can't be blank" in errors_on(changeset).slug
      assert "can't be blank" in errors_on(changeset).markdown_content
      assert "can't be blank" in errors_on(changeset).course_id
    end

    test "validates level length constraint" do
      course = insert(:course)
      long_level = String.duplicate("a", 31)
      attrs = params_for(:lesson, course_id: course.id, level: long_level)

      changeset = Lesson.changeset(%Lesson{}, attrs)

      refute changeset.valid?
      assert "should be at most 30 character(s)" in errors_on(changeset).level
    end

    test "validates title length constraint" do
      course = insert(:course)
      long_title = String.duplicate("a", 101)
      attrs = params_for(:lesson, course_id: course.id, title: long_title)

      changeset = Lesson.changeset(%Lesson{}, attrs)

      refute changeset.valid?
      assert "should be at most 100 character(s)" in errors_on(changeset).title
    end

    test "validates description length constraint" do
      course = insert(:course)
      long_description = String.duplicate("a", 2001)
      attrs = params_for(:lesson, course_id: course.id, description: long_description)

      changeset = Lesson.changeset(%Lesson{}, attrs)

      refute changeset.valid?
      assert "should be at most 2000 character(s)" in errors_on(changeset).description
    end

    test "validates slug length constraint" do
      course = insert(:course)
      long_slug = String.duplicate("a", 51)
      attrs = params_for(:lesson, course_id: course.id, slug: long_slug)

      changeset = Lesson.changeset(%Lesson{}, attrs)

      refute changeset.valid?
      assert "should be at most 50 character(s)" in errors_on(changeset).slug
    end

    test "validates order is greater than 0" do
      course = insert(:course)

      invalid_orders = [0, -1, -10]

      for order <- invalid_orders do
        attrs = params_for(:lesson, course_id: course.id, order: order)
        changeset = Lesson.changeset(%Lesson{}, attrs)

        refute changeset.valid?, "Order #{order} should be invalid"
        assert "must be greater than 0" in errors_on(changeset).order
      end
    end

    test "validates slug format - accepts valid slugs" do
      course = insert(:course)
      valid_slugs = ["lesson-1", "intro", "advanced-grammar-2024", "a", "test-123"]

      for slug <- valid_slugs do
        attrs = params_for(:lesson, course_id: course.id, slug: slug)
        changeset = Lesson.changeset(%Lesson{}, attrs)

        assert changeset.valid?, "#{slug} should be valid"
      end
    end

    test "validates slug format - rejects invalid slugs" do
      course = insert(:course)

      invalid_slugs = [
        # spaces
        "Lesson 1",
        # underscores
        "lesson_1",
        # periods
        "lesson.1",
        # uppercase
        "Lesson-1",
        # uppercase
        "123A",
        # special chars
        "test@home"
      ]

      for slug <- invalid_slugs do
        attrs = params_for(:lesson, course_id: course.id, slug: slug)
        changeset = Lesson.changeset(%Lesson{}, attrs)

        refute changeset.valid?, "#{slug} should be invalid"

        assert "must only contain lowercase letters, numbers, and hyphens" in errors_on(changeset).slug
      end
    end

    test "validates unique constraint on course_id and slug" do
      course = insert(:course)
      attrs = params_for(:lesson, course_id: course.id)

      # Insert first lesson
      %Lesson{} |> Lesson.changeset(attrs) |> Repo.insert!()

      # Try to insert second lesson with same course_id and slug
      changeset = Lesson.changeset(%Lesson{}, attrs)
      {:error, changeset} = Repo.insert(changeset)

      assert "has already been taken" in errors_on(changeset).course_id
    end

    test "allows same slug in different courses" do
      course1 = insert(:course, slug: "course-1")
      course2 = insert(:course, slug: "course-2")

      attrs1 = params_for(:lesson, course_id: course1.id, slug: "intro")
      attrs2 = params_for(:lesson, course_id: course2.id, slug: "intro")

      # Both should succeed
      assert {:ok, _} = Lesson.changeset(%Lesson{}, attrs1) |> Repo.insert()
      assert {:ok, _} = Lesson.changeset(%Lesson{}, attrs2) |> Repo.insert()
    end

    test "validates foreign key constraint for course_id" do
      attrs = params_for(:lesson, course_id: Ecto.UUID.generate())

      changeset = Lesson.changeset(%Lesson{}, attrs)
      assert changeset.valid?

      {:error, changeset} = Repo.insert(changeset)
      assert "does not exist" in errors_on(changeset).course_id
    end
  end

  describe "create_changeset/2" do
    test "sets visibility to false by default" do
      course = insert(:course)
      attrs = params_for(:lesson, course_id: course.id, visible: true)

      changeset = Lesson.create_changeset(%Lesson{}, attrs)

      assert changeset.valid?
      refute assert get_change(changeset, :visible)
    end

    test "overrides visible field even if provided as true" do
      course = insert(:course)
      attrs = params_for(:lesson, course: course, visible: true)

      changeset = Lesson.create_changeset(%Lesson{}, attrs)

      assert get_change(changeset, :visible) != true
    end

    test "includes all other validations from regular changeset" do
      invalid_attrs = %{slug: "Invalid Slug"}

      changeset = Lesson.create_changeset(%Lesson{}, invalid_attrs)

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).title

      assert "must only contain lowercase letters, numbers, and hyphens" in errors_on(changeset).slug
    end
  end

  describe "visibility_changeset/2" do
    test "valid changeset for updating visibility to true" do
      course = insert(:course)
      lesson = insert(:lesson, course: course)

      changeset = Lesson.visibility_changeset(lesson, %{visible: true})

      assert changeset.valid?
      assert get_change(changeset, :visible) == true
    end

    test "valid changeset for updating visibility to false" do
      course = insert(:course)
      lesson = insert(:lesson, course: course, visible: true)

      changeset = Lesson.visibility_changeset(lesson, %{visible: false})

      assert changeset.valid?
      assert get_change(changeset, :visible) == false
    end

    test "invalid changeset with missing visible field" do
      course = insert(:course)
      lesson = insert(:lesson, course: course)

      changeset = Lesson.visibility_changeset(lesson, %{})

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).visible
    end

    test "does not allow updating other fields" do
      course = insert(:course)
      lesson = insert(:lesson, course: course)

      changeset =
        Lesson.visibility_changeset(lesson, %{
          visible: true,
          title: "New Title",
          slug: "new-slug"
        })

      assert changeset.valid?
      assert get_change(changeset, :visible) == true
      assert get_change(changeset, :title) == nil
      assert get_change(changeset, :slug) == nil
    end
  end

  describe "order_changeset/2" do
    test "valid changeset for updating order" do
      course = insert(:course)
      lesson = insert(:lesson, course: course, order: 1)

      changeset = Lesson.order_changeset(lesson, %{order: 5})

      assert changeset.valid?
      assert get_change(changeset, :order) == 5
    end

    test "invalid changeset with missing order field" do
      course = insert(:course)
      lesson = insert(:lesson, course: course)

      changeset = Lesson.order_changeset(lesson, %{})

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).order
    end

    test "validates order is greater than 0" do
      course = insert(:course)
      lesson = insert(:lesson, course: course, order: 1)

      changeset = Lesson.order_changeset(lesson, %{order: 0})

      refute changeset.valid?
      assert "must be greater than 0" in errors_on(changeset).order
    end

    test "does not allow updating other fields" do
      course = insert(:course)
      lesson = insert(:lesson, course: course)

      changeset =
        Lesson.order_changeset(lesson, %{
          order: 10,
          title: "New Title",
          slug: "new-slug"
        })

      assert changeset.valid?
      assert get_change(changeset, :order) == 10
      assert get_change(changeset, :title) == nil
      assert get_change(changeset, :slug) == nil
    end
  end
end
