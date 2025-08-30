defmodule Bridge.Courses.CardField do
  @moduledoc """
  Validates a card field against a card template.
  """
  alias Bridge.Courses.CardTemplate

  @spec validate({binary(), term()}, CardTemplate.t() | nil) :: :ok | {:error, String.t()}
  def validate(_field, nil), do: {:error, "Card template not found"}

  def validate({key, value}, template) do
    field = Enum.find(template.fields, &(&1["key"] == key))

    if field do
      %{"type" => type} = field
      metadata = Map.get(field, "metadata", %{})

      case type do
        "single_choice" -> validate_single_choice(value, metadata)
        "multiple_choice" -> validate_multiple_choice(value, metadata)
        "examples" -> validate_examples(value, metadata)
        url_type when url_type in ["image_url", "audio_url"] -> validate_url(value)
        _ -> :ok
      end
    end
  end

  defp validate_single_choice(value, metadata) do
    choices = Map.get(metadata, "choices", [])

    if value in choices do
      :ok
    else
      {:error, "Invalid choice"}
    end
  end

  defp validate_multiple_choice(values, metadata) do
    choices = Map.get(metadata, "choices", [])

    if Enum.all?(values, &(&1 in choices)) do
      :ok
    else
      {:error, "Invalid choice"}
    end
  end

  defp validate_examples(values, _metadata) do
    if Enum.all?(values, &is_map/1) and Enum.all?(values, &valid_example?(&1)) do
      :ok
    else
      {:error, "Invalid example"}
    end
  end

  defp valid_example?(%{"taught_language_example" => _, "instruction_language_example" => _}),
    do: true

  defp valid_example?(_), do: false

  defp validate_url(value) do
    case URI.new(value) do
      {:ok, %URI{scheme: scheme, host: host}} when is_binary(scheme) and is_binary(host) -> :ok
      _ -> {:error, "Invalid URL"}
    end
  end
end
