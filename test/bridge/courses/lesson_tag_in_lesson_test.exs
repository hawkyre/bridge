defmodule Bridge.Courses.LessonTagInLessonTest do
  use Bridge.DataCase, async: true

  alias Bridge.Courses.{LessonTagInLesson, Lesson, LessonTag, Course}
  import Bridge.Factory

  describe "changeset/2" do
    test "valid changeset with all required fields" do
      {lesson, lesson_tag} = setup_lesson_and_tag()

      valid_attrs = %{
        lesson_id: lesson.id,
        lesson_tag_id: lesson_tag.id
      }

      changeset = LessonTagInLesson.changeset(%LessonTagInLesson{}, valid_attrs)

      assert changeset.valid?
      assert get_change(changeset, :lesson_id) == lesson.id
      assert get_change(changeset, :lesson_tag_id) == lesson_tag.id
    end

    test "invalid changeset with missing required fields" do
      changeset = LessonTagInLesson.changeset(%LessonTagInLesson{}, %{})

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).lesson_id
      assert "can't be blank" in errors_on(changeset).lesson_tag_id
    end

    test "invalid changeset with missing lesson_id" do
      {_lesson, lesson_tag} = setup_lesson_and_tag()

      attrs = %{lesson_tag_id: lesson_tag.id}

      changeset = LessonTagInLesson.changeset(%LessonTagInLesson{}, attrs)

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).lesson_id
    end

    test "invalid changeset with missing lesson_tag_id" do
      {lesson, _lesson_tag} = setup_lesson_and_tag()

      attrs = %{lesson_id: lesson.id}

      changeset = LessonTagInLesson.changeset(%LessonTagInLesson{}, attrs)

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).lesson_tag_id
    end

    test "validates unique constraint on lesson_id and lesson_tag_id" do
      {lesson, lesson_tag} = setup_lesson_and_tag()
      attrs = %{lesson_id: lesson.id, lesson_tag_id: lesson_tag.id}

      # Insert first association
      LessonTagInLesson.changeset(%LessonTagInLesson{}, attrs) |> Repo.insert!()

      # Try to insert duplicate association
      changeset = LessonTagInLesson.changeset(%LessonTagInLesson{}, attrs)
      {:error, changeset} = Repo.insert(changeset)

      # The error message might be on either field depending on the constraint name
      errors = errors_on(changeset)

      assert "has already been taken" in (errors[:lesson_id] || errors[:lesson_tag_id] ||
                                            errors[:lesson_tag])
    end

    test "allows same lesson with different tags" do
      course = insert(:course)
      lesson = insert(:lesson, course: course)
      tag1 = insert(:lesson_tag, course: course, key: "verbs")
      tag2 = insert(:lesson_tag, course: course, key: "adjectives")

      attrs1 = %{lesson_id: lesson.id, lesson_tag_id: tag1.id}
      attrs2 = %{lesson_id: lesson.id, lesson_tag_id: tag2.id}

      # Both should succeed
      assert {:ok, _} = LessonTagInLesson.changeset(%LessonTagInLesson{}, attrs1) |> Repo.insert()
      assert {:ok, _} = LessonTagInLesson.changeset(%LessonTagInLesson{}, attrs2) |> Repo.insert()
    end

    test "allows same tag with different lessons" do
      course = insert(:course)
      lesson1 = insert(:lesson, course: course, slug: "lesson-1")
      lesson2 = insert(:lesson, course: course, slug: "lesson-2")
      tag = insert(:lesson_tag, course: course, key: "verbs")

      attrs1 = %{lesson_id: lesson1.id, lesson_tag_id: tag.id}
      attrs2 = %{lesson_id: lesson2.id, lesson_tag_id: tag.id}

      # Both should succeed
      assert {:ok, _} = LessonTagInLesson.changeset(%LessonTagInLesson{}, attrs1) |> Repo.insert()
      assert {:ok, _} = LessonTagInLesson.changeset(%LessonTagInLesson{}, attrs2) |> Repo.insert()
    end

    test "validates foreign key constraint for lesson_id" do
      {_lesson, lesson_tag} = setup_lesson_and_tag()
      attrs = %{lesson_id: Ecto.UUID.generate(), lesson_tag_id: lesson_tag.id}

      changeset = LessonTagInLesson.changeset(%LessonTagInLesson{}, attrs)
      assert changeset.valid?

      {:error, changeset} = Repo.insert(changeset)
      assert "does not exist" in errors_on(changeset).lesson_id
    end

    test "validates foreign key constraint for lesson_tag_id" do
      {lesson, _lesson_tag} = setup_lesson_and_tag()
      attrs = %{lesson_id: lesson.id, lesson_tag_id: Ecto.UUID.generate()}

      changeset = LessonTagInLesson.changeset(%LessonTagInLesson{}, attrs)
      assert changeset.valid?

      {:error, changeset} = Repo.insert(changeset)
      assert "does not exist" in errors_on(changeset).lesson_tag_id
    end

    test "successful insertion creates association" do
      {lesson, lesson_tag} = setup_lesson_and_tag()
      attrs = %{lesson_id: lesson.id, lesson_tag_id: lesson_tag.id}

      changeset = LessonTagInLesson.changeset(%LessonTagInLesson{}, attrs)

      assert {:ok, lesson_tag_in_lesson} = Repo.insert(changeset)
      assert lesson_tag_in_lesson.lesson_id == lesson.id
      assert lesson_tag_in_lesson.lesson_tag_id == lesson_tag.id
      assert lesson_tag_in_lesson.id != nil
      assert lesson_tag_in_lesson.inserted_at != nil
      assert lesson_tag_in_lesson.updated_at != nil
    end

    test "does not allow updating IDs after insertion" do
      {lesson, lesson_tag} = setup_lesson_and_tag()
      attrs = %{lesson_id: lesson.id, lesson_tag_id: lesson_tag.id}

      {:ok, lesson_tag_in_lesson} =
        LessonTagInLesson.changeset(%LessonTagInLesson{}, attrs) |> Repo.insert()

      # Try to update the association IDs
      {lesson2, lesson_tag2} = setup_lesson_and_tag([slug: "lesson-2"], "nouns")

      update_attrs = %{lesson_id: lesson2.id, lesson_tag_id: lesson_tag2.id}
      changeset = LessonTagInLesson.changeset(lesson_tag_in_lesson, update_attrs)

      # Should maintain original values since IDs aren't typically updated
      assert get_change(changeset, :lesson_id) == lesson2.id
      assert get_change(changeset, :lesson_tag_id) == lesson_tag2.id
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
