defmodule Bridge.Courses.TagTranslationTest do
  use Bridge.DataCase, async: true

  alias Bridge.Courses.{TagTranslation, LessonTag, Course}
  import Bridge.Factory

  describe "changeset/2" do
    test "valid changeset with all required fields" do
      lesson_tag = insert(:lesson_tag)

      valid_attrs = %{
        language_code: "es",
        name: "Verbos",
        lesson_tag_id: lesson_tag.id
      }

      changeset = TagTranslation.changeset(%TagTranslation{}, valid_attrs)

      assert changeset.valid?
      assert get_change(changeset, :language_code) == "es"
      assert get_change(changeset, :name) == "Verbos"
      assert get_change(changeset, :lesson_tag_id) == lesson_tag.id
    end

    test "invalid changeset with missing required fields" do
      changeset = TagTranslation.changeset(%TagTranslation{}, %{})

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).language_code
      assert "can't be blank" in errors_on(changeset).name
      assert "can't be blank" in errors_on(changeset).lesson_tag_id
    end

    test "invalid changeset with missing language_code" do
      lesson_tag = insert(:lesson_tag)

      attrs = %{
        name: "Verbos",
        lesson_tag_id: lesson_tag.id
      }

      changeset = TagTranslation.changeset(%TagTranslation{}, attrs)

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).language_code
    end

    test "invalid changeset with missing name" do
      lesson_tag = insert(:lesson_tag)

      attrs = %{
        language_code: "es",
        lesson_tag_id: lesson_tag.id
      }

      changeset = TagTranslation.changeset(%TagTranslation{}, attrs)

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).name
    end

    test "invalid changeset with missing lesson_tag_id" do
      attrs = %{
        language_code: "es",
        name: "Verbos"
      }

      changeset = TagTranslation.changeset(%TagTranslation{}, attrs)

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).lesson_tag_id
    end

    test "validates language_code length constraint" do
      lesson_tag = insert(:lesson_tag)
      long_code = String.duplicate("a", 6)

      attrs = %{
        language_code: long_code,
        name: "Verbos",
        lesson_tag_id: lesson_tag.id
      }

      changeset = TagTranslation.changeset(%TagTranslation{}, attrs)

      refute changeset.valid?
      assert "should be at most 5 character(s)" in errors_on(changeset).language_code
    end

    test "validates name length constraint" do
      lesson_tag = insert(:lesson_tag)
      long_name = String.duplicate("a", 101)

      attrs = %{
        language_code: "es",
        name: long_name,
        lesson_tag_id: lesson_tag.id
      }

      changeset = TagTranslation.changeset(%TagTranslation{}, attrs)

      refute changeset.valid?
      assert "should be at most 100 character(s)" in errors_on(changeset).name
    end

    test "validates language_code format - accepts valid codes" do
      lesson_tag = insert(:lesson_tag)
      valid_codes = ["es", "en", "fr", "de", "pt", "zh", "ja", "ko", "ar", "hi", "zh-cn", "en-us"]

      for code <- valid_codes do
        attrs = %{
          language_code: code,
          name: "Test Name",
          lesson_tag_id: lesson_tag.id
        }

        changeset = TagTranslation.changeset(%TagTranslation{}, attrs)

        assert changeset.valid?, "#{code} should be valid"
      end
    end

    test "validates language_code format - rejects invalid codes" do
      lesson_tag = insert(:lesson_tag)

      invalid_codes = [
        "e",
        "ESP",
        "123",
        "e1",
        "english",
        "es-ES-valencia",
        "En",
        "FR",
        "en-"
      ]

      for code <- invalid_codes do
        attrs = %{
          language_code: code,
          name: "Test Name",
          lesson_tag_id: lesson_tag.id
        }

        changeset = TagTranslation.changeset(%TagTranslation{}, attrs)

        refute changeset.valid?, "#{code} should be invalid"
        assert "must be a valid language code" in errors_on(changeset).language_code
      end
    end

    test "validates unique constraint on lesson_tag_id and language_code" do
      lesson_tag = insert(:lesson_tag)

      attrs = %{
        language_code: "es",
        name: "Verbos",
        lesson_tag_id: lesson_tag.id
      }

      # Insert first translation
      TagTranslation.changeset(%TagTranslation{}, attrs) |> Repo.insert!()

      # Try to insert second translation with same lesson_tag_id and language_code
      duplicate_attrs = %{
        language_code: "es",
        # Different name but same lesson_tag_id and language_code
        name: "Verbos Diferentes",
        lesson_tag_id: lesson_tag.id
      }

      changeset = TagTranslation.changeset(%TagTranslation{}, duplicate_attrs)
      {:error, changeset} = Repo.insert(changeset)

      # The error might be on different fields depending on constraint name
      errors = errors_on(changeset)

      assert "has already been taken" in (errors[:language_code] || errors[:lesson_tag_id] ||
                                            errors[:lesson_tag])
    end

    test "allows same language_code for different lesson_tags" do
      course = insert_course()
      lesson_tag1 = insert_lesson_tag(course, "verbs")
      lesson_tag2 = insert_lesson_tag(course, "adjectives")

      attrs1 = %{
        language_code: "es",
        name: "Verbos",
        lesson_tag_id: lesson_tag1.id
      }

      attrs2 = %{
        language_code: "es",
        name: "Adjetivos",
        lesson_tag_id: lesson_tag2.id
      }

      # Both should succeed
      assert {:ok, _} = TagTranslation.changeset(%TagTranslation{}, attrs1) |> Repo.insert()
      assert {:ok, _} = TagTranslation.changeset(%TagTranslation{}, attrs2) |> Repo.insert()
    end

    test "allows same lesson_tag for different language_codes" do
      lesson_tag = insert(:lesson_tag)

      attrs1 = %{
        language_code: "es",
        name: "Verbos",
        lesson_tag_id: lesson_tag.id
      }

      attrs2 = %{
        language_code: "fr",
        name: "Verbes",
        lesson_tag_id: lesson_tag.id
      }

      # Both should succeed
      assert {:ok, _} = TagTranslation.changeset(%TagTranslation{}, attrs1) |> Repo.insert()
      assert {:ok, _} = TagTranslation.changeset(%TagTranslation{}, attrs2) |> Repo.insert()
    end

    test "validates foreign key constraint for lesson_tag_id" do
      attrs = %{
        language_code: "es",
        name: "Verbos",
        lesson_tag_id: Ecto.UUID.generate()
      }

      changeset = TagTranslation.changeset(%TagTranslation{}, attrs)
      assert changeset.valid?

      {:error, changeset} = Repo.insert(changeset)
      assert "does not exist" in errors_on(changeset).lesson_tag_id
    end

    test "accepts maximum length fields" do
      lesson_tag = insert(:lesson_tag)
      max_language_code = String.duplicate("a", 5)
      max_name = String.duplicate("a", 100)

      attrs = %{
        language_code: max_language_code,
        name: max_name,
        lesson_tag_id: lesson_tag.id
      }

      changeset = TagTranslation.changeset(%TagTranslation{}, attrs)

      assert changeset.valid?
    end

    test "successful insertion creates translation" do
      lesson_tag = insert(:lesson_tag)

      attrs = %{
        language_code: "es",
        name: "Verbos",
        lesson_tag_id: lesson_tag.id
      }

      changeset = TagTranslation.changeset(%TagTranslation{}, attrs)

      assert {:ok, tag_translation} = Repo.insert(changeset)
      assert tag_translation.language_code == "es"
      assert tag_translation.name == "Verbos"
      assert tag_translation.lesson_tag_id == lesson_tag.id
      assert tag_translation.id != nil
      assert tag_translation.inserted_at != nil
      assert tag_translation.updated_at != nil
    end

    test "accepts unicode characters in name" do
      lesson_tag = insert(:lesson_tag)

      attrs = %{
        language_code: "zh",
        # Chinese characters
        name: "动词",
        lesson_tag_id: lesson_tag.id
      }

      changeset = TagTranslation.changeset(%TagTranslation{}, attrs)

      assert changeset.valid?
    end

    test "accepts names with spaces and special characters" do
      lesson_tag = insert(:lesson_tag)

      attrs = %{
        language_code: "en",
        name: "Past Tense Verbs (Regular)",
        lesson_tag_id: lesson_tag.id
      }

      changeset = TagTranslation.changeset(%TagTranslation{}, attrs)

      assert changeset.valid?
    end
  end

  # Test helpers
  defp insert_course(attrs \\ %{}) do
    default_attrs = %{
      title: "Spanish for Beginners",
      description: "Learn Spanish from scratch",
      slug: "spanish-beginners",
      taught_language_code: "es",
      instruction_language_code: "en"
    }

    attrs = Map.merge(default_attrs, attrs)

    %Course{}
    |> Course.changeset(attrs)
    |> Repo.insert!()
  end

  defp insert_lesson_tag(course \\ nil, key \\ "verbs") do
    course = course || insert_course()

    %LessonTag{}
    |> LessonTag.changeset(%{key: key, course_id: course.id})
    |> Repo.insert!()
  end
end
