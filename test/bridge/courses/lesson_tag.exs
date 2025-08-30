defmodule Bridge.Courses.LessonTagTest do
  # REVIEWED
  use Bridge.DataCase, async: true

  alias Bridge.Courses.{LessonTag, Lesson, Course}
  import Bridge.Factory

  describe "changeset/2" do
    test "valid changeset with all required fields" do
      {lesson, lesson_tag} = setup_lesson_and_tag()

      valid_attrs = %{
        lesson_id: lesson.id,
        tag_id: lesson_tag.id
      }

      changeset = LessonTag.changeset(%LessonTag{}, valid_attrs)

      assert changeset.valid?
      assert get_change(changeset, :lesson_id) == lesson.id
      assert get_change(changeset, :tag_id) == lesson_tag.id
    end

    test "validates unique constraint on lesson_id and tag_id" do
      {lesson, lesson_tag} = setup_lesson_and_tag()
      attrs = %{lesson_id: lesson.id, tag_id: lesson_tag.id}

      LessonTag.changeset(%LessonTag{}, attrs) |> Repo.insert!()

      changeset = LessonTag.changeset(%LessonTag{}, attrs)
      {:error, changeset} = Repo.insert(changeset)

      errors = errors_on(changeset)

      assert "has already been taken" in (errors[:lesson_id] || errors[:tag_id] ||
                                            errors[:lesson_tag])
    end

    test "allows same lesson with different tags" do
      course = insert(:course)
      lesson = insert(:lesson, course: course)
      tag1 = insert(:lesson_tag, course: course, key: "verbs")
      tag2 = insert(:lesson_tag, course: course, key: "adjectives")

      attrs1 = %{lesson_id: lesson.id, tag_id: tag1.id}
      attrs2 = %{lesson_id: lesson.id, tag_id: tag2.id}

      assert {:ok, _} = LessonTag.changeset(%LessonTag{}, attrs1) |> Repo.insert()
      assert {:ok, _} = LessonTag.changeset(%LessonTag{}, attrs2) |> Repo.insert()
    end

    test "allows same tag with different lessons" do
      course = insert(:course)
      lesson1 = insert(:lesson, course: course, slug: "lesson-1")
      lesson2 = insert(:lesson, course: course, slug: "lesson-2")
      tag = insert(:lesson_tag, course: course, key: "verbs")

      attrs1 = %{lesson_id: lesson1.id, tag_id: tag.id}
      attrs2 = %{lesson_id: lesson2.id, tag_id: tag.id}

      assert {:ok, _} = LessonTag.changeset(%LessonTag{}, attrs1) |> Repo.insert()
      assert {:ok, _} = LessonTag.changeset(%LessonTag{}, attrs2) |> Repo.insert()
    end

    test "rejects same tag in the same lesson" do
      course = insert(:course)
      lesson1 = insert(:lesson, course: course, slug: "lesson-1")
      tag = insert(:lesson_tag, course: course, key: "verbs")

      attrs = %{lesson_id: lesson1.id, tag_id: tag.id}

      assert {:ok, _} = LessonTag.changeset(%LessonTag{}, attrs) |> Repo.insert()
      assert {:error, changeset} = LessonTag.changeset(%LessonTag{}, attrs) |> Repo.insert()

      assert "has already been taken" in errors_on(changeset).tag_id
    end

    test "validates foreign key constraint for lesson_id" do
      {_lesson, lesson_tag} = setup_lesson_and_tag()
      attrs = %{lesson_id: Ecto.UUID.generate(), tag_id: lesson_tag.id}

      changeset = LessonTag.changeset(%LessonTag{}, attrs)
      assert changeset.valid?

      {:error, changeset} = Repo.insert(changeset)
      assert "does not exist" in errors_on(changeset).lesson_id
    end

    test "validates foreign key constraint for tag_id" do
      {lesson, _lesson_tag} = setup_lesson_and_tag()
      attrs = %{lesson_id: lesson.id, tag_id: Ecto.UUID.generate()}

      changeset = LessonTag.changeset(%LessonTag{}, attrs)
      assert changeset.valid?

      {:error, changeset} = Repo.insert(changeset)
      assert "does not exist" in errors_on(changeset).tag_id
    end
  end

  # Test helpers
  defp setup_lesson_and_tag(lesson_attrs \\ [], tag_key \\ "verbs") do
    course = insert(:course)
    lesson = insert(:lesson, Keyword.merge([course: course], lesson_attrs))
    lesson_tag = insert(:lesson_tag, course: course, key: tag_key)
    {lesson, lesson_tag}
  end
end
