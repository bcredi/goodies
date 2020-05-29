defmodule GoodiesTest do
  use ExUnit.Case
  doctest Goodies

  test "greets the world" do
    assert Goodies.hello() == :world
  end
end
