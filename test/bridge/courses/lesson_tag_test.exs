defmodule Bridge.Courses.LessonTagTest do
  use Bridge.DataCase, async: true

  alias Bridge.Courses.{LessonTag, Course}
  import Bridge.Factory

  describe "changeset/2" do
    test "valid changeset with all required fields" do
      course = insert(:course)

      valid_attrs = %{
        key: "verbs",
        course_id: course.id
      }

      changeset = LessonTag.changeset(%LessonTag{}, valid_attrs)

      assert changeset.valid?
      assert get_change(changeset, :key) == "verbs"
      assert get_change(changeset, :course_id) == course.id
    end

    test "invalid changeset with missing required fields" do
      changeset = LessonTag.changeset(%LessonTag{}, %{})

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).key
      assert "can't be blank" in errors_on(changeset).course_id
    end

    test "invalid changeset with missing key" do
      course = insert(:course)

      attrs = %{course_id: course.id}

      changeset = LessonTag.changeset(%LessonTag{}, attrs)

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).key
    end

    test "invalid changeset with missing course_id" do
      attrs = %{key: "verbs"}

      changeset = LessonTag.changeset(%LessonTag{}, attrs)

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).course_id
    end

    test "validates key length constraint" do
      course = insert(:course)
      long_key = String.duplicate("a", 41)
      attrs = %{key: long_key, course_id: course.id}

      changeset = LessonTag.changeset(%LessonTag{}, attrs)

      refute changeset.valid?
      assert "should be at most 40 character(s)" in errors_on(changeset).key
    end

    test "validates key format - accepts valid keys" do
      course = insert(:course)

      valid_keys = [
        "verbs",
        "adjectives",
        "sentence_formation",
        "past_tense",
        "verb_conjugation",
        "a",
        "test_123",
        "grammar_1",
        "word_order"
      ]

      for key <- valid_keys do
        attrs = %{key: key, course_id: course.id}
        changeset = LessonTag.changeset(%LessonTag{}, attrs)

        assert changeset.valid?, "#{key} should be valid"
      end
    end

    test "validates key format - rejects invalid keys" do
      course = insert(:course)

      invalid_keys = [
        # uppercase
        "Verbs",
        # hyphens
        "past-tense",
        # spaces
        "verb conjugation",
        # periods
        "verb.conjugation",
        # starts with number
        "123invalid",
        # special chars
        "test@key",
        # exclamation
        "verbs!",
        # hash
        "test#tag"
      ]

      for key <- invalid_keys do
        attrs = %{key: key, course_id: course.id}
        changeset = LessonTag.changeset(%LessonTag{}, attrs)

        refute changeset.valid?, "#{key} should be invalid"

        assert "must be a valid identifier (lowercase, numbers, underscores)" in errors_on(
                 changeset
               ).key
      end
    end

    test "validates unique constraint on key" do
      course = insert(:course)
      attrs = %{key: "verbs", course_id: course.id}

      # Insert first lesson tag
      LessonTag.changeset(%LessonTag{}, attrs) |> Repo.insert!()

      # Try to insert second lesson tag with same key
      changeset = LessonTag.changeset(%LessonTag{}, attrs)
      {:error, changeset} = Repo.insert(changeset)

      assert "has already been taken" in errors_on(changeset).key
    end

    test "allows same key for different courses" do
      course1 = insert(:course, slug: "course-1")
      course2 = insert(:course, slug: "course-2")

      attrs1 = %{key: "verbs", course_id: course1.id}
      attrs2 = %{key: "verbs", course_id: course2.id}

      # Both should succeed
      assert {:ok, _} = LessonTag.changeset(%LessonTag{}, attrs1) |> Repo.insert()
      assert {:ok, _} = LessonTag.changeset(%LessonTag{}, attrs2) |> Repo.insert()
    end

    test "validates foreign key constraint for course_id" do
      attrs = %{key: "verbs", course_id: Ecto.UUID.generate()}

      changeset = LessonTag.changeset(%LessonTag{}, attrs)
      assert changeset.valid?

      {:error, changeset} = Repo.insert(changeset)
      assert "does not exist" in errors_on(changeset).course_id
    end

    test "accepts maximum length key" do
      course = insert(:course)
      max_length_key = String.duplicate("a", 40)
      attrs = %{key: max_length_key, course_id: course.id}

      changeset = LessonTag.changeset(%LessonTag{}, attrs)

      assert changeset.valid?
    end

    test "accepts key starting with underscore" do
      course = insert(:course)
      attrs = %{key: "_private_tag", course_id: course.id}

      changeset = LessonTag.changeset(%LessonTag{}, attrs)

      assert changeset.valid?
    end

    test "accepts key with multiple underscores" do
      course = insert(:course)
      attrs = %{key: "complex_tag_name_here", course_id: course.id}

      changeset = LessonTag.changeset(%LessonTag{}, attrs)

      assert changeset.valid?
    end

    test "accepts key ending with numbers" do
      course = insert(:course)
      attrs = %{key: "lesson_123", course_id: course.id}

      changeset = LessonTag.changeset(%LessonTag{}, attrs)

      assert changeset.valid?
    end

    test "rejects key with consecutive underscores" do
      course = insert(:course)
      attrs = %{key: "invalid__key", course_id: course.id}

      changeset = LessonTag.changeset(%LessonTag{}, attrs)

      refute changeset.valid?

      assert "must be a valid identifier (lowercase, numbers, underscores)" in errors_on(
               changeset
             ).key
    end
  end
end
