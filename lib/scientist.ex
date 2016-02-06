defmodule Scientist do
  require Logger
  defmodule Experiment do
    @attributes [
      name: nil,
      control: nil, candidates: [],
      enabled: true,
    ]
    defstruct @attributes

    defmodule SetupError do
      defexception ~w(message experiment)a
    end
  end


  defmacro __using__(_opts) do
    quote do
      require unquote(__MODULE__)
      import unquote(__MODULE__)#, only: [experiment: 2]
    end
  end
  defmacro experiment(name, opts) do
    quote bind_quoted: [name: name, opts: opts] do
      control = Keyword.get(opts, :control, nil)
      candidates = Keyword.get(opts, :candidates, [])
      %Experiment{name: name, control: control, candidates: candidates}
    end
  end

  defmacro experiment(name) do
    quote bind_quoted: [name: name] do
      %Experiment{name: name}
    end
  end
  defmacro set_control(exp, do: block) do
    quote bind_quoted: [exp: exp, block: Macro.escape(block)], unquote: true do
      set_control(exp, fn -> unquote(block) end)
    end
  end
  defmacro set_control(exp, fun) do
    quote bind_quoted: [exp: exp, fun: fun] do
      case {is_nil(exp.control), is_function(fun)} do
        {true, true}  -> %Experiment{exp | control: fun}
        {true, false} -> 
          msg = "Control must be a do block or a function, got: #{inspect fun}"
          raise Experiment.SetupError, message: msg, experiment: exp
        {false, _} ->
          msg = "An experiment can have only one control."
          raise Experiment.SetupError, message: msg, experiment: exp
      end
    end
  end

  defmacro add_candidate(exp, do: block) do
    quote bind_quoted: [exp: exp, block: Macro.escape(block)], unquote: true do
      fun = fn -> unquote(block) end
      add_candidate(exp, fun)
    end
  end
  defmacro add_candidate(exp, fun) do
    quote bind_quoted: [exp: exp, fun: fun] do
      if is_function(fun) do
        %Experiment{exp | candidates: [fun | exp.candidates]}
      else
        msg = "Control must be a do block or a function, got: #{inspect fun}"
        raise Experiment.SetupError, message: msg, experiment: exp
      end
    end
  end

  defmacro enable_for_fraction(exp, fraction) when is_float(fraction) do
    quote bind_quoted: [exp: exp, fraction: fraction] do
      fun = fn -> :rand.uniform < fraction end
      %Experiment{exp | enabled: fun}
    end
  end
  def set_enabled(exp, bool) do
    %Experiment{exp | enabled: bool}
  end
  def enable(exp) do
    set_enabled(exp, true)
  end
  def disable(exp) do
    set_enabled(exp, false)
  end

  defmacro perform(exp) do
    quote bind_quoted: [exp: exp] do
      control_result = eval_control(exp)
      candidate_results = eval_candidates(exp)
      case control_result do
        {:ok, res} ->
          # TODO: Check candidate results. They should all be res.
          res
        {:error, ex} ->
          # TODO: Check candidate results. They should have same exception
          # Let's reraise the exception
          raise ex
      end
    end
  end

  def eval_control(exp) do
    exp.control |> try_eval
  end
  def eval_candidates(exp) do
    should_check_candidates = Enum.any?([
      # Simplest case: enabled: true or false
      is_boolean(exp.enabled) and exp.enabled,
      # If it is a function, call it.
      is_function(exp.enabled) and exp.enabled.()
    ])
    if should_check_candidates
    do exp.candidates |> Enum.map(&try_eval/1)
    else []
    end
  end

  def try_eval(fun) do
    try do
      fun.()
    rescue
      ex -> {:error, ex}
    else
      res -> {:ok, res}
    end
  end

end
