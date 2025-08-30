defmodule Bridge.Courses.CardTest do
  use Bridge.DataCase, async: true

  alias Bridge.Courses.Card
  import Bridge.Factory

  describe "changeset/2" do
    test "valid changeset with all required fields" do
      course = insert(:course)

      card_template =
        insert(:card_template,
          fields: [
            %{"key" => "word", "type" => "short_text"},
            %{"key" => "translation", "type" => "short_text"}
          ]
        )

      attrs = %{
        fields: %{"word" => "hello", "translation" => "hola"},
        course_id: course.id,
        card_template_id: card_template.id
      }

      changeset = Card.create_changeset(attrs)

      assert changeset.valid?
      assert get_change(changeset, :fields) == %{"word" => "hello", "translation" => "hola"}
      assert get_change(changeset, :course_id) == course.id
      assert get_change(changeset, :card_template_id) == card_template.id
    end

    test "valid changeset with examples field" do
      course = insert(:course)

      card_template =
        insert(:card_template,
          fields: [
            %{"key" => "examples", "type" => "examples"}
          ]
        )

      attrs = %{
        fields: %{
          "examples" => [
            %{
              "taught_language" => "I am pablo",
              "instruction_language" => "Yo soy pablo"
            },
            %{
              "taught_language" => "I am not pablo",
              "instruction_language" => "Yo no soy pablo"
            }
          ]
        },
        course_id: course.id,
        card_template_id: card_template.id
      }

      changeset = Card.create_changeset(attrs)

      assert changeset.valid?
    end

    test "invalid changeset with wrong format for examples field" do
      course = insert(:course)

      card_template =
        insert(:card_template,
          fields: [
            %{"key" => "examples", "type" => "examples"}
          ]
        )

      wrong_examples = [
        %{
          "taught_languages" => "I am pablo",
          "wrong" => "Yo soy pablo"
        },
        %{
          "taught_language" => "Missing key"
        },
        %{
          "instruction_language" => "Missing key"
        },
        %{},
        "string"
      ]

      for example <- wrong_examples do
        attrs = %{
          fields: %{"examples" => [example]},
          course_id: course.id,
          card_template_id: card_template.id
        }

        refute Card.create_changeset(attrs).valid?
      end
    end

    test "valid changeset with single choice field" do
      course = insert(:course)

      card_template =
        insert(:card_template,
          fields: [
            %{
              "key" => "single_choice",
              "type" => "single_choice",
              "metadata" => %{"choices" => ["choice1", "choice2"]}
            }
          ]
        )

      attrs = %{
        fields: %{"single_choice" => "choice1"},
        course_id: course.id,
        card_template_id: card_template.id
      }

      changeset = Card.create_changeset(attrs)

      assert changeset.valid?
    end

    test "invalid changeset with wrong choice for single choice field" do
      course = insert(:course)

      card_template =
        insert(:card_template,
          fields: [
            %{
              "key" => "single_choice",
              "type" => "single_choice",
              "metadata" => %{"choices" => ["choice1", "choice2"]}
            }
          ]
        )

      attrs = %{
        fields: %{"single_choice" => "wrong_choice"},
        course_id: course.id,
        card_template_id: card_template.id
      }

      changeset = Card.create_changeset(attrs)

      refute changeset.valid?
      assert "must be a map of valid field values" in errors_on(changeset).fields
    end

    test "valid changeset with multiple choice field" do
      course = insert(:course)

      card_template =
        insert(:card_template,
          fields: [
            %{
              "key" => "mc",
              "type" => "multiple_choice",
              "metadata" => %{"choices" => ["choice1", "choice2", "choice3"]}
            }
          ]
        )

      attrs = %{
        fields: %{"mc" => ["choice1", "choice2"]},
        course_id: course.id,
        card_template_id: card_template.id
      }

      changeset = Card.create_changeset(attrs)

      assert changeset.valid?
    end

    test "invalid changeset with wrong choice for multiple choice field" do
      course = insert(:course)

      card_template =
        insert(:card_template,
          fields: [
            %{
              "key" => "mc",
              "type" => "multiple_choice",
              "metadata" => %{"choices" => ["choice1", "choice2"]}
            }
          ]
        )

      attrs = %{
        fields: %{"mc" => ["choice1", "wrong_choice"]},
        course_id: course.id,
        card_template_id: card_template.id
      }

      changeset = Card.create_changeset(attrs)

      refute changeset.valid?
      assert "must be a map of valid field values" in errors_on(changeset).fields
    end

    test "valid changeset with image url field" do
      course = insert(:course)

      card_template =
        insert(:card_template,
          fields: [
            %{"key" => "image_url", "type" => "image_url"}
          ]
        )

      attrs = %{
        fields: %{"image_url" => "https://example.com/image.png"},
        course_id: course.id,
        card_template_id: card_template.id
      }

      changeset = Card.create_changeset(attrs)

      assert changeset.valid?
    end

    test "invalid changeset with wrong url for image url field" do
      course = insert(:course)

      card_template =
        insert(:card_template,
          fields: [
            %{"key" => "image_url", "type" => "image_url"}
          ]
        )

      attrs = %{
        fields: %{"image_url" => "wrong_url"},
        course_id: course.id,
        card_template_id: card_template.id
      }

      changeset = Card.create_changeset(attrs)

      refute changeset.valid?
      assert "must be a map of valid field values" in errors_on(changeset).fields
    end
  end
end
