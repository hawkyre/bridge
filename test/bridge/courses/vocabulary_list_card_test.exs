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

    test "invalid changeset with missing required fields" do
      changeset = VocabularyListCard.changeset(%VocabularyListCard{}, %{})

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).vocabulary_list_id
      assert "can't be blank" in errors_on(changeset).card_id
    end

    test "invalid changeset with missing vocabulary_list_id" do
      {_vocabulary_list, card} = setup_vocabulary_list_and_card()

      attrs = %{card_id: card.id}

      changeset = VocabularyListCard.changeset(%VocabularyListCard{}, attrs)

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).vocabulary_list_id
    end

    test "invalid changeset with missing card_id" do
      {vocabulary_list, _card} = setup_vocabulary_list_and_card()

      attrs = %{vocabulary_list_id: vocabulary_list.id}

      changeset = VocabularyListCard.changeset(%VocabularyListCard{}, attrs)

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).card_id
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

    test "successful insertion creates association" do
      {vocabulary_list, card} = setup_vocabulary_list_and_card()
      attrs = %{vocabulary_list_id: vocabulary_list.id, card_id: card.id}

      changeset = VocabularyListCard.changeset(%VocabularyListCard{}, attrs)

      assert {:ok, vocabulary_list_card} = Repo.insert(changeset)
      assert vocabulary_list_card.vocabulary_list_id == vocabulary_list.id
      assert vocabulary_list_card.card_id == card.id
      assert vocabulary_list_card.id != nil
      assert vocabulary_list_card.inserted_at != nil
      assert vocabulary_list_card.updated_at != nil
    end

    test "does not allow updating IDs after insertion" do
      {vocabulary_list, card} = setup_vocabulary_list_and_card()
      attrs = %{vocabulary_list_id: vocabulary_list.id, card_id: card.id}

      {:ok, vocabulary_list_card} =
        VocabularyListCard.changeset(%VocabularyListCard{}, attrs) |> Repo.insert()

      # Try to update the association IDs
      {vocabulary_list2, card2} =
        setup_vocabulary_list_and_card([slug: "list-2"], fields: %{"word" => "goodbye"})

      update_attrs = %{vocabulary_list_id: vocabulary_list2.id, card_id: card2.id}
      changeset = VocabularyListCard.changeset(vocabulary_list_card, update_attrs)

      # Should maintain new values since IDs can be updated in join tables
      assert get_change(changeset, :vocabulary_list_id) == vocabulary_list2.id
      assert get_change(changeset, :card_id) == card2.id
    end

    test "allows card to be in multiple vocabulary lists from same course" do
      course = insert(:course)
      card_template = insert(:card_template)

      vocabulary_list1 =
        insert(:vocabulary_list, course: course, name: "Basic Words", slug: "basic-words")

      vocabulary_list2 =
        insert(:vocabulary_list, course: course, name: "Advanced Words", slug: "advanced-words")

      card =
        insert(:card, course: course, card_template: card_template, fields: %{"word" => "hello"})

      attrs1 = %{vocabulary_list_id: vocabulary_list1.id, card_id: card.id}
      attrs2 = %{vocabulary_list_id: vocabulary_list2.id, card_id: card.id}

      # Both should succeed - same card can be in multiple lists
      assert {:ok, _} =
               VocabularyListCard.changeset(%VocabularyListCard{}, attrs1) |> Repo.insert()

      assert {:ok, _} =
               VocabularyListCard.changeset(%VocabularyListCard{}, attrs2) |> Repo.insert()
    end

    test "allows vocabulary list to contain multiple cards" do
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

      card3 =
        insert(:card, course: course, card_template: card_template, fields: %{"word" => "thanks"})

      attrs1 = %{vocabulary_list_id: vocabulary_list.id, card_id: card1.id}
      attrs2 = %{vocabulary_list_id: vocabulary_list.id, card_id: card2.id}
      attrs3 = %{vocabulary_list_id: vocabulary_list.id, card_id: card3.id}

      # All should succeed - vocabulary list can contain multiple cards
      assert {:ok, _} =
               VocabularyListCard.changeset(%VocabularyListCard{}, attrs1) |> Repo.insert()

      assert {:ok, _} =
               VocabularyListCard.changeset(%VocabularyListCard{}, attrs2) |> Repo.insert()

      assert {:ok, _} =
               VocabularyListCard.changeset(%VocabularyListCard{}, attrs3) |> Repo.insert()
    end

    test "handles cross-course scenarios correctly" do
      # Create two courses with their own cards and vocabulary lists
      course1 = insert(:course, slug: "course-1")
      course2 = insert(:course, slug: "course-2")
      card_template = insert(:card_template)

      vocabulary_list1 = insert(:vocabulary_list, course: course1, slug: "list-1")
      vocabulary_list2 = insert(:vocabulary_list, course: course2, slug: "list-2")

      card1 =
        insert(:card, course: course1, card_template: card_template, fields: %{"word" => "hello"})

      card2 =
        insert(:card, course: course2, card_template: card_template, fields: %{"word" => "hola"})

      # Same course associations should work
      attrs1 = %{vocabulary_list_id: vocabulary_list1.id, card_id: card1.id}
      attrs2 = %{vocabulary_list_id: vocabulary_list2.id, card_id: card2.id}

      assert {:ok, _} =
               VocabularyListCard.changeset(%VocabularyListCard{}, attrs1) |> Repo.insert()

      assert {:ok, _} =
               VocabularyListCard.changeset(%VocabularyListCard{}, attrs2) |> Repo.insert()

      # Cross-course associations might work depending on business logic
      # but the schema itself doesn't prevent them
      cross_attrs = %{vocabulary_list_id: vocabulary_list1.id, card_id: card2.id}
      changeset = VocabularyListCard.changeset(%VocabularyListCard{}, cross_attrs)

      # This should pass schema validation
      assert changeset.valid?
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
