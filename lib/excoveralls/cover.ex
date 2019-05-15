defmodule ExCoveralls.Cover do
  @moduledoc """
  Wrapper class for Erlang's cover tool.
  """

  @doc """
  Compile the beam files for coverage analysis.
  """
  def compile(compile_paths) do
    compile_paths = List.wrap(compile_paths)
    :cover.stop()
    :cover.start()

    Enum.each(compile_paths, fn compile_path ->
      :cover.compile_beam_directory(compile_path |> to_charlist)
    end)
  end

  @doc """
  Returns the relative file path of the specified module.
  """
  def module_path(module) do
    module.module_info(:compile)[:source]
    |> List.to_string()
    |> Path.relative_to(ExCoveralls.PathReader.base_path())
  end

  @doc "Wrapper for :cover.modules"
  def modules do
    :cover.modules() |> Enum.filter(&has_compile_info?/1)
  end

  def has_compile_info?(module) do
    case module.module_info(:compile) do
      nil ->
        false

      info ->
        path = Keyword.get(info, :source)

        if File.exists?(path) do
          true
        else
          log_missing_source(module)
          false
        end
    end
  rescue
    _e in UndefinedFunctionError ->
      log_missing_source(module)
      false
  end

  @doc "Wrapper for :cover.analyse"
  def analyze(module) do
    :cover.analyse(module, :calls, :line)
  end

  defp log_missing_source(module) do
    IO.puts(
      :stderr,
      "[warning] skipping the module '#{module}' because source information for the module is not available."
    )
  end
end
