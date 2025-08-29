defmodule Bridge.Courses.CardTest do
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

    test "invalid changeset with missing fields" do
      course = insert(:course)
      card_template = insert(:card_template)

      attrs = %{
        course_id: course.id,
        card_template_id: card_template.id
      }

      changeset = Card.changeset(%Card{}, attrs)

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).fields
    end

    test "invalid changeset with missing course_id" do
      card_template = insert(:card_template)

      attrs = %{
        fields: %{"word" => "hello"},
        card_template_id: card_template.id
      }

      changeset = Card.changeset(%Card{}, attrs)

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).course_id
    end

    test "invalid changeset with missing card_template_id" do
      course = insert(:course)

      attrs = %{
        fields: %{"word" => "hello"},
        course_id: course.id
      }

      changeset = Card.changeset(%Card{}, attrs)

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).card_template_id
    end

    test "validates foreign key constraint for course_id" do
      card_template = insert(:card_template)

      attrs = %{
        fields: %{"word" => "hello"},
        course_id: Ecto.UUID.generate(),
        card_template_id: card_template.id
      }

      changeset = Card.changeset(%Card{}, attrs)
      assert changeset.valid?

      {:error, changeset} = Repo.insert(changeset)
      assert "does not exist" in errors_on(changeset).course_id
    end

    test "validates foreign key constraint for card_template_id" do
      course = insert(:course)

      attrs = %{
        fields: %{"word" => "hello"},
        course_id: course.id,
        card_template_id: Ecto.UUID.generate()
      }

      changeset = Card.changeset(%Card{}, attrs)
      assert changeset.valid?

      {:error, changeset} = Repo.insert(changeset)
      assert "does not exist" in errors_on(changeset).card_template_id
    end
  end

  describe "validate_fields_structure/1" do
    test "accepts valid map fields" do
      changeset =
        %Card{}
        |> Card.changeset(%{fields: %{"word" => "hello", "translation" => "hola"}})

      assert changeset.valid?
    end

    test "accepts empty map fields" do
      changeset =
        %Card{}
        |> Card.changeset(%{fields: %{}})

      assert changeset.valid?
    end

    test "accepts nil fields (handled by required validation)" do
      changeset =
        %Card{}
        |> change(%{fields: nil})
        |> Card.validate_fields_structure()

      # No error added by validate_fields_structure, but will fail required validation
      refute "must be a map of field values" in (errors_on(changeset)[:fields] || [])
    end

    test "rejects non-map fields" do
      changeset =
        %Card{}
        |> change(%{fields: "invalid"})
        |> Card.validate_fields_structure()

      refute changeset.valid?
      assert "must be a map of field values" in errors_on(changeset).fields
    end

    test "rejects list fields" do
      changeset =
        %Card{}
        |> change(%{fields: ["invalid", "list"]})
        |> Card.validate_fields_structure()

      refute changeset.valid?
      assert "must be a map of field values" in errors_on(changeset).fields
    end

    test "rejects integer fields" do
      changeset =
        %Card{}
        |> change(%{fields: 123})
        |> Card.validate_fields_structure()

      refute changeset.valid?
      assert "must be a map of field values" in errors_on(changeset).fields
    end
  end

  describe "update_fields_changeset/2" do
    test "valid changeset for updating fields only" do
      course = insert(:course)
      card_template = insert(:card_template)

      card =
        insert(:card, course: course, card_template: card_template, fields: %{"word" => "hello"})

      new_fields = %{"word" => "goodbye", "translation" => "adiós"}
      changeset = Card.update_fields_changeset(card, %{fields: new_fields})

      assert changeset.valid?
      assert get_change(changeset, :fields) == new_fields
    end

    test "invalid changeset with missing fields" do
      course = insert(:course)
      card_template = insert(:card_template)

      card =
        insert(:card, course: course, card_template: card_template, fields: %{"word" => "hello"})

      changeset = Card.update_fields_changeset(card, %{})

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).fields
    end

    test "invalid changeset with non-map fields" do
      course = insert(:course)
      card_template = insert(:card_template)

      card =
        insert(:card, course: course, card_template: card_template, fields: %{"word" => "hello"})

      changeset = Card.update_fields_changeset(card, %{fields: "invalid"})

      refute changeset.valid?
      assert "must be a map of field values" in errors_on(changeset).fields
    end

    test "does not allow updating other fields" do
      course = insert(:course)
      card_template = insert(:card_template)

      card =
        insert(:card, course: course, card_template: card_template, fields: %{"word" => "hello"})

      changeset =
        Card.update_fields_changeset(card, %{
          fields: %{"word" => "updated"},
          course_id: Ecto.UUID.generate(),
          card_template_id: Ecto.UUID.generate()
        })

      assert changeset.valid?
      assert get_change(changeset, :fields) == %{"word" => "updated"}
      assert get_change(changeset, :course_id) == nil
      assert get_change(changeset, :card_template_id) == nil
    end
  end
end
