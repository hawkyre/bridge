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
      valid_attrs = %{
        title: "Spanish for Beginners",
        description: "Learn Spanish from scratch",
        slug: "spanish-beginners",
        taught_language_code: "es",
        instruction_language_code: "en"
      }

      changeset = Course.changeset(%Course{}, valid_attrs)

      assert changeset.valid?
      # visible defaults to false in schema
      assert get_field(changeset, :visible) == false
    end

    test "invalid changeset with missing required fields" do
      changeset = Course.changeset(%Course{}, %{})

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).title
      assert "can't be blank" in errors_on(changeset).description
      assert "can't be blank" in errors_on(changeset).slug
      assert "can't be blank" in errors_on(changeset).taught_language_code
      assert "can't be blank" in errors_on(changeset).instruction_language_code
    end

    test "validates title length constraint" do
      long_title = String.duplicate("a", 101)
      attrs = valid_course_attrs() |> Map.put(:title, long_title)

      changeset = Course.changeset(%Course{}, attrs)

      refute changeset.valid?
      assert "should be at most 100 character(s)" in errors_on(changeset).title
    end

    test "validates description length constraint" do
      long_description = String.duplicate("a", 2001)
      attrs = valid_course_attrs() |> Map.put(:description, long_description)

      changeset = Course.changeset(%Course{}, attrs)

      refute changeset.valid?
      assert "should be at most 2000 character(s)" in errors_on(changeset).description
    end

    test "validates slug length constraint" do
      long_slug = String.duplicate("a", 71)
      attrs = valid_course_attrs() |> Map.put(:slug, long_slug)

      changeset = Course.changeset(%Course{}, attrs)

      refute changeset.valid?
      assert "should be at most 70 character(s)" in errors_on(changeset).slug
    end

    test "validates taught_language_code length constraint" do
      long_code = String.duplicate("a", 6)
      attrs = valid_course_attrs() |> Map.put(:taught_language_code, long_code)

      changeset = Course.changeset(%Course{}, attrs)

      refute changeset.valid?
      assert "should be at most 5 character(s)" in errors_on(changeset).taught_language_code
    end

    test "validates instruction_language_code length constraint" do
      long_code = String.duplicate("a", 6)
      attrs = valid_course_attrs() |> Map.put(:instruction_language_code, long_code)

      changeset = Course.changeset(%Course{}, attrs)

      refute changeset.valid?
      assert "should be at most 5 character(s)" in errors_on(changeset).instruction_language_code
    end

    test "validates slug format - accepts valid slugs" do
      valid_slugs = ["spanish-basics", "french101", "german-advanced-2024", "a", "test-123"]

      for slug <- valid_slugs do
        attrs = valid_course_attrs() |> Map.put(:slug, slug)
        changeset = Course.changeset(%Course{}, attrs)

        assert changeset.valid?, "#{slug} should be valid"
      end
    end

    test "validates slug format - rejects invalid slugs" do
      invalid_slugs = [
        # spaces
        "Spanish Basics",
        # underscores
        "spanish_basics",
        # periods
        "spanish.basics",
        # uppercase
        "Spanish-basics",
        # double hyphens (still valid regex but bad practice)
        "spanish--basics",
        # empty
        "",
        # uppercase
        "123A",
        # special chars
        "test@home"
      ]

      for slug <- invalid_slugs do
        attrs = valid_course_attrs() |> Map.put(:slug, slug)
        changeset = Course.changeset(%Course{}, attrs)

        refute changeset.valid?, "#{slug} should be invalid"

        assert "must only contain lowercase letters, numbers, and hyphens" in errors_on(changeset).slug
      end
    end

    test "validates taught_language_code format - accepts valid codes" do
      valid_codes = ["es", "en", "fr", "de", "pt", "zh", "ja", "ko", "ar", "hi", "zh-cn", "en-us"]

      for code <- valid_codes do
        attrs = valid_course_attrs() |> Map.put(:taught_language_code, code)
        changeset = Course.changeset(%Course{}, attrs)

        assert changeset.valid?, "#{code} should be valid"
      end
    end

    test "validates taught_language_code format - rejects invalid codes" do
      invalid_codes = ["", "e", "ESP", "123", "e1", "english", "es-ES-valencia"]

      for code <- invalid_codes do
        attrs = valid_course_attrs() |> Map.put(:taught_language_code, code)
        changeset = Course.changeset(%Course{}, attrs)

        refute changeset.valid?, "#{code} should be invalid"
        assert "must be a valid language code" in errors_on(changeset).taught_language_code
      end
    end

    test "validates instruction_language_code format - accepts valid codes" do
      valid_codes = ["es", "en", "fr", "de", "pt", "zh", "ja", "ko", "ar", "hi", "zh-cn", "en-us"]

      for code <- valid_codes do
        attrs = valid_course_attrs() |> Map.put(:instruction_language_code, code)
        changeset = Course.changeset(%Course{}, attrs)

        assert changeset.valid?, "#{code} should be valid"
      end
    end

    test "validates instruction_language_code format - rejects invalid codes" do
      invalid_codes = ["", "e", "ESP", "123", "e1", "english", "es-ES-valencia"]

      for code <- invalid_codes do
        attrs = valid_course_attrs() |> Map.put(:instruction_language_code, code)
        changeset = Course.changeset(%Course{}, attrs)

        refute changeset.valid?, "#{code} should be invalid"
        assert "must be a valid language code" in errors_on(changeset).instruction_language_code
      end
    end

    test "validates unique constraint on slug" do
      # Insert first course with specific slug
      insert(:course, slug: "test-slug")

      # Try to insert second course with same slug
      attrs = %{
        title: "Different Course",
        description: "Different description",
        # Same slug
        slug: "test-slug",
        taught_language_code: "fr",
        instruction_language_code: "en"
      }

      changeset = Course.changeset(%Course{}, attrs)
      {:error, changeset} = Repo.insert(changeset)

      assert "has already been taken" in errors_on(changeset).slug
    end
  end

  describe "create_changeset/2" do
    test "sets visibility to false by default" do
      attrs = valid_course_attrs() |> Map.put(:visible, true)

      changeset = Course.create_changeset(%Course{}, attrs)

      assert changeset.valid?
      assert get_change(changeset, :visible) == false
    end

    test "overrides visible field even if provided as true" do
      attrs = valid_course_attrs() |> Map.put(:visible, true)

      changeset = Course.create_changeset(%Course{}, attrs)

      assert get_change(changeset, :visible) == false
    end

    test "includes all other validations from regular changeset" do
      invalid_attrs = %{slug: "Invalid Slug"}

      changeset = Course.create_changeset(%Course{}, invalid_attrs)

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).title

      assert "must only contain lowercase letters, numbers, and hyphens" in errors_on(changeset).slug
    end
  end

  describe "visibility_changeset/2" do
    test "valid changeset for updating visibility to true" do
      course = insert(:course)

      changeset = Course.visibility_changeset(course, %{visible: true})

      assert changeset.valid?
      assert get_change(changeset, :visible) == true
    end

    test "valid changeset for updating visibility to false" do
      course = insert(:course, visible: true)

      changeset = Course.visibility_changeset(course, %{visible: false})

      assert changeset.valid?
      assert get_change(changeset, :visible) == false
    end

    test "invalid changeset with missing visible field" do
      course = insert(:course)

      changeset = Course.visibility_changeset(course, %{})

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).visible
    end

    test "does not allow updating other fields" do
      course = insert(:course)

      changeset =
        Course.visibility_changeset(course, %{
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

  # Test helpers
  defp valid_course_attrs do
    %{
      title: "Spanish for Beginners",
      description: "Learn Spanish from scratch",
      slug: "spanish-beginners",
      taught_language_code: "es",
      instruction_language_code: "en"
    }
  end
end
