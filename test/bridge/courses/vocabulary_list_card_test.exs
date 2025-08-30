defmodule Bridge.Courses.VocabularyListCardTest do
  use Bridge.DataCase, async: true

  alias Bridge.Courses.VocabularyListCard
  import Bridge.Factory

  describe "changeset/2" do
    test "valid changeset with all required fields" do
      {vocabulary_list, card} = setup_vocabulary_list_and_card()

      valid_attrs = %{
        vocabulary_list_id: vocabulary_list.id,
        card_id: card.id
      }

      changeset = VocabularyListCard.changeset(%VocabularyListCard{}, valid_attrs)

      assert changeset.valid?
      assert get_change(changeset, :vocabulary_list_id) == vocabulary_list.id
      assert get_change(changeset, :card_id) == card.id
    end

    test "validates unique constraint on card_id and vocabulary_list_id" do
      {vocabulary_list, card} = setup_vocabulary_list_and_card()
      attrs = %{vocabulary_list_id: vocabulary_list.id, card_id: card.id}

      # Insert first association
      VocabularyListCard.changeset(%VocabularyListCard{}, attrs) |> Repo.insert!()

      # Try to insert duplicate association
      changeset = VocabularyListCard.changeset(%VocabularyListCard{}, attrs)
      {:error, changeset} = Repo.insert(changeset)

      # The error message might be on either field depending on the constraint name
      errors = errors_on(changeset)

      assert "has already been taken" in (errors[:card_id] || errors[:vocabulary_list_id] ||
                                            errors[:vocabulary_list])
    end

    test "allows same vocabulary_list with different cards" do
      course = insert(:course)
      card_template = insert(:card_template)
      vocabulary_list = insert(:vocabulary_list, course: course)

      card1 =
        insert(:card, course: course, card_template: card_template, fields: %{"word" => "hello"})

      card2 =
        insert(:card,
          course: course,
          card_template: card_template,
          fields: %{"word" => "goodbye"}
        )

      attrs1 = %{vocabulary_list_id: vocabulary_list.id, card_id: card1.id}
      attrs2 = %{vocabulary_list_id: vocabulary_list.id, card_id: card2.id}

      # Both should succeed
      assert {:ok, _} =
               VocabularyListCard.changeset(%VocabularyListCard{}, attrs1) |> Repo.insert()

      assert {:ok, _} =
               VocabularyListCard.changeset(%VocabularyListCard{}, attrs2) |> Repo.insert()
    end

    test "allows same card with different vocabulary_lists" do
      course = insert(:course)
      card_template = insert(:card_template)
      vocabulary_list1 = insert(:vocabulary_list, course: course, slug: "list-1")
      vocabulary_list2 = insert(:vocabulary_list, course: course, slug: "list-2")

      card =
        insert(:card, course: course, card_template: card_template, fields: %{"word" => "hello"})

      attrs1 = %{vocabulary_list_id: vocabulary_list1.id, card_id: card.id}
      attrs2 = %{vocabulary_list_id: vocabulary_list2.id, card_id: card.id}

      # Both should succeed
      assert {:ok, _} =
               VocabularyListCard.changeset(%VocabularyListCard{}, attrs1) |> Repo.insert()

      assert {:ok, _} =
               VocabularyListCard.changeset(%VocabularyListCard{}, attrs2) |> Repo.insert()
    end

    test "validates foreign key constraint for vocabulary_list_id" do
      {_vocabulary_list, card} = setup_vocabulary_list_and_card()
      attrs = %{vocabulary_list_id: Ecto.UUID.generate(), card_id: card.id}

      changeset = VocabularyListCard.changeset(%VocabularyListCard{}, attrs)
      assert changeset.valid?

      {:error, changeset} = Repo.insert(changeset)
      assert "does not exist" in errors_on(changeset).vocabulary_list_id
    end

    test "validates foreign key constraint for card_id" do
      {vocabulary_list, _card} = setup_vocabulary_list_and_card()
      attrs = %{vocabulary_list_id: vocabulary_list.id, card_id: Ecto.UUID.generate()}

      changeset = VocabularyListCard.changeset(%VocabularyListCard{}, attrs)
      assert changeset.valid?

      {:error, changeset} = Repo.insert(changeset)
      assert "does not exist" in errors_on(changeset).card_id
    end
  end

  # Test helpers
  defp setup_vocabulary_list_and_card(
         vocabulary_list_attrs \\ [],
         card_fields \\ [fields: %{"word" => "hello"}]
       ) do
    course = insert(:course)
    card_template = insert(:card_template)

    vocabulary_list =
      insert(:vocabulary_list, Keyword.merge([course: course], vocabulary_list_attrs))

    card =
      insert(
        :card,
        Keyword.merge([course: course, card_template: card_template], card_fields)
      )

    {vocabulary_list, card}
  end
end
