defmodule ScientistTest do
  use ExUnit.Case

  ExUnit.configure exclude: :not_implemented, trace: true
  
  use Scientist
  doctest Scientist

  test "the test framework is setup" do
    assert 1 + 1 == 2
  end

  test "experiment returns the control's result" do
    result = perform experiment "function based test",
        control: fn -> :control end,
        candidates: [ fn -> :candidate end ]
    assert result == :control
  end


  test "alternate syntax" do
    result = experiment("block based test")
      |> set_control do :control end
      |> add_candidate do :candidate end
      |> add_candidate do nil end
      |> perform
    assert result == :control
  end

  test "experiment runs the candidates"

  test "experiment result is unaffected by candidate crashes"

  test "experiment crashes when control crashes"

end
