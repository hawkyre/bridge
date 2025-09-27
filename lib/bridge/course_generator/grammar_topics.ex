defmodule Bridge.CourseGenerator.GrammarTopics do
  @moduledoc """
  AI service for generating comprehensive grammar topic lists for language learning courses.

  This module provides functionality to generate structured lists of grammar topics
  based on target language, instruction language, and proficiency level. It uses
  XML-structured prompts for clear organization while requesting JSON responses
  to ensure consistent, parseable data from AI providers.
  """

  alias Bridge.AI.Executor

  @type grammar_topic :: %{
          topic: String.t(),
          slug: String.t(),
          tags: [String.t()]
        }

  defstruct [:topics]

  @type t :: %__MODULE__{
          topics: [grammar_topic()]
        }

  @doc """
  Generates a comprehensive list of grammar topics for a given language and level.

  ## Parameters

    * `target_language` - The language being learned (e.g., "Spanish", "Chinese Simplified")
    * `instruction_language` - The student's native language (e.g., "English", "French")
    * `level` - The proficiency level (e.g., "A1", "B2", "HSK 1", "JLPT N5")
    * `opts` - Optional parameters for AI provider (model, temperature, etc.)

  ## Returns

    * `{:ok, [grammar_topic()]}` - List of grammar topics with structured data
    * `{:error, String.t()}` - Error message if generation fails

  ## Examples

      iex> Bridge.CourseGenerator.GrammarTopics.get_topics("Spanish", "English", "A1")
      {:ok, [
        %{
          topic: "Present Tense of Regular Verbs",
          slug: "present-tense-regular-verbs",
          tags: ["verbs", "present_tense", "regular_verbs"]
        },
        %{
          topic: "Definite and Indefinite Articles",
          slug: "definite-indefinite-articles",
          tags: ["articles", "determiners", "nouns"]
        }
      ]}

      iex> Bridge.CourseGenerator.GrammarTopics.get_topics("Chinese Simplified", "English", "HSK 1", model: "claude-3-haiku")
      {:ok, [%{topic: "Basic Word Order", slug: "basic-word-order", tags: ["word_order", "sentence_structure"]}]}
  """
  @spec get_topics(String.t(), String.t(), String.t(), Keyword.t()) ::
          {:ok, [grammar_topic()]} | {:error, String.t()}
  def get_topics(target_language, instruction_language, level, opts \\ []) do
    with {:ok, prompt} <- build_prompt(target_language, instruction_language, level),
         {:ok, response} <- Executor.call(:anthropic, prompt, opts),
         {:ok, topics} <- parse_response(response.content) do
      {:ok, topics}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @spec build_prompt(String.t(), String.t(), String.t()) ::
          {:ok, String.t()} | {:error, String.t()}
  defp build_prompt(target_language, instruction_language, level) do
    with :ok <- validate_inputs(target_language, instruction_language, level) do
      prompt = """
      <instruction>
        <role>You are an expert #{target_language} teacher with extensive experience in language pedagogy.</role>

        <task>
          <objective>Generate a complete, comprehensive list of grammar topics that a #{level} learner must master to become completely proficient at the #{level} level.</objective>

          <context>
            <student_language>#{instruction_language}</student_language>
            <target_language>#{target_language}</target_language>
            <proficiency_level>#{level}</proficiency_level>
          </context>

          <requirements>
            <structure>Structure the content to align with how a #{instruction_language}-speaking student would learn most effectively</structure>
            <ordering>The lessons must be ordered by optimal learning progression for the student</ordering>
            <comprehensiveness>Include all essential grammar topics for #{level} level mastery</comprehensiveness>
          </requirements>
        </task>

        <output_format>
          <format>JSON</format>
          <structure>
            Array of objects with the following keys:
            - topic: the topic of the grammar lesson (string)
            - slug: An SEO friendly slug for the lesson title (string)
            - tags: an array of tags that inform about the content of the lesson (array of strings)
          </structure>

          <tag_guidelines>
            <format>lowercase with underscores instead of spaces</format>
            <examples>nouns, verbs, past_tense, comparatives, sentence_structure</examples>
            <consistency>Tags must be general and normalized across different prompts</consistency>
            <quantity>Each topic should have 2-5 relevant tags</quantity>
          </tag_guidelines>

          <constraints>
            <output>Only output the JSON array, do not output anything else</output>
            <structure>No additional text or explanations</structure>
          </constraints>
        </output_format>
      </instruction>
      """

      {:ok, prompt}
    end
  end

  @spec validate_inputs(String.t(), String.t(), String.t()) :: :ok | {:error, String.t()}
  defp validate_inputs(target_language, instruction_language, level) do
    cond do
      not is_binary(target_language) or String.trim(target_language) == "" ->
        {:error, "Target language must be a non-empty string"}

      not is_binary(instruction_language) or String.trim(instruction_language) == "" ->
        {:error, "Instruction language must be a non-empty string"}

      not is_binary(level) or String.trim(level) == "" ->
        {:error, "Level must be a non-empty string"}

      true ->
        :ok
    end
  end

  @spec parse_response(String.t()) :: {:ok, [grammar_topic()]} | {:error, String.t()}
  defp parse_response(json_content) do
    # Extract JSON from mixed content (in case AI adds extra text)
    cleaned_content = extract_json_content(json_content)

    # Parse JSON
    topics =
      cleaned_content
      |> Jason.decode!()
      |> Enum.map(&format_topic/1)

    {:ok, topics}
  rescue
    Jason.DecodeError ->
      {:error, "Invalid JSON response from AI provider"}

    e ->
      {:error, "Failed to parse JSON response: #{Exception.message(e)}"}
  end

  @spec extract_json_content(String.t()) :: String.t()
  defp extract_json_content(content) do
    # Try to find JSON array in the content
    case Regex.run(~r/\[.*\]/s, content) do
      [json_match] -> json_match
      # Fallback to original content if no match
      nil -> content
    end
  end

  @spec format_topic(map()) :: grammar_topic()
  defp format_topic(topic_data) do
    %{
      topic: String.trim(topic_data["topic"] || ""),
      slug: String.trim(topic_data["slug"] || ""),
      tags:
        topic_data["tags"]
        |> Enum.map(&String.trim/1)
    }
  end
end
