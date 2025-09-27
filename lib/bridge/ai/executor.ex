defmodule Bridge.AI.Executor do
  @moduledoc """
  AI Service for integrating with multiple LLM providers.

  This module provides a simple, clean interface for calling AI providers
  without any pre-defined prompts. You can build your own prompts and
  use this service to execute them across different providers.
  """

  alias ExLLM.Types.LLMResponse

  @doc """
  Calls an AI provider with a custom prompt.

  ## Examples

      iex> Bridge.AI.Executor.call(:openai, "Hello, how are you?")
      {:ok, "I'm doing well, thank you for asking!"}

      iex> Bridge.AI.Executor.call(:anthropic, "Hello", model: "claude-3-haiku")
      {:ok, "Hello! How can I help you today?"}
  """
  @spec call(atom(), String.t(), Keyword.t()) :: {:ok, LLMResponse.t()} | {:error, String.t()}
  def call(provider, prompt, opts \\ []) when is_binary(prompt) do
    try do
      messages = [%{role: "user", content: prompt}]
      call_opts = Enum.reduce(opts, [], &build_call_opts/2)

      case ExLLM.chat(provider, messages, call_opts) do
        {:ok, %LLMResponse{} = response} ->
          {:ok, response}

        {:error, reason} ->
          {:error, "AI provider error: #{inspect(reason)}"}
      end
    rescue
      e -> {:error, "AI service error: #{Exception.message(e)}"}
    end
  end

  defp build_call_opts({:model, model}, acc) do
    [model: model] ++ acc
  end

  defp build_call_opts({:temperature, temperature}, acc) do
    [temperature: temperature] ++ acc
  end

  defp build_call_opts(_, opts) do
    opts
  end
end
