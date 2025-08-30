defmodule Bridge.Courses.CardTest do
  # REVIEWED - NEED TO ADD TESTS FOR THE FIELDS
  use Bridge.DataCase, async: true

  alias Bridge.Courses.Card
  import Bridge.Factory

  describe "changeset/2" do
    test "valid changeset with all required fields" do
      course = insert(:course)
      card_template = insert(:card_template)

      valid_attrs = %{
        fields: %{"word" => "hello", "translation" => "hola"},
        course_id: course.id,
        card_template_id: card_template.id
      }

      changeset = Card.changeset(%Card{}, valid_attrs)

      assert changeset.valid?
      assert get_change(changeset, :fields) == %{"word" => "hello", "translation" => "hola"}
      assert get_change(changeset, :course_id) == course.id
      assert get_change(changeset, :card_template_id) == card_template.id
    end

    test "invalid changeset with missing required fields" do
      changeset = Card.changeset(%Card{}, %{})

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).fields
      assert "can't be blank" in errors_on(changeset).course_id
      assert "can't be blank" in errors_on(changeset).card_template_id
    end
  end
end
