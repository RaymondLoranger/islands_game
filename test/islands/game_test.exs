defmodule Islands.GameTest do
  use ExUnit.Case, async: true

  alias Islands.{Game, Player}

  doctest Game

  setup_all do
    this = self()
    eden = Game.new("Eden", "Adam", :m, this)

    jason =
      ~s<{"name":"Eden","request":[],"state":{"game_state":"initialized","player1_state":"islands_not_set","player2_state":"islands_not_set"},"response":[],"player1":{"name":"Adam","gender":"m","board":{"islands":{},"misses":[]},"guesses":{"hits":[],"misses":[]}},"player2":{"name":"?","gender":"f","board":{"islands":{},"misses":[]},"guesses":{"hits":[],"misses":[]}}}>

    decoded = %{
      "name" => "Eden",
      "player1" => %{
        "gender" => "m",
        "name" => "Adam",
        "board" => %{"islands" => %{}, "misses" => []},
        "guesses" => %{"hits" => [], "misses" => []}
      },
      "player2" => %{
        "gender" => "f",
        "name" => "?",
        "board" => %{"islands" => %{}, "misses" => []},
        "guesses" => %{"hits" => [], "misses" => []}
      },
      "request" => [],
      "response" => [],
      "state" => %{
        "game_state" => "initialized",
        "player1_state" => "islands_not_set",
        "player2_state" => "islands_not_set"
      }
    }

    %{json: %{jason: jason, decoded: decoded}, game: eden}
  end

  describe "A game struct" do
    test "can be encoded by Jason", %{game: eden, json: json} do
      assert Jason.encode!(eden) == json.jason
      assert Jason.decode!(json.jason) == json.decoded
    end
  end

  describe "Game.new/3" do
    test "returns %Game{} given valid args" do
      me = self()

      assert %Game{
               name: "Aveline",
               player1: %Player{name: "Jordan", gender: :m, pid: ^me}
             } = Game.new("Aveline", "Jordan", :m, me)
    end

    test "returns {:error, reason} given invalid args" do
      assert Game.new("Aveline", "Jordan", :m, :pid) ==
               {:error, :invalid_game_args}
    end
  end

  describe "Game.overview/1" do
    test "returns a game overview" do
      me = self()
      game = Game.new("Avatar", "Neytiri", :f, me)

      assert Game.overview(game) == %{
               game_name: "Avatar",
               player1: %{name: "Neytiri", gender: :f},
               player2: %{name: "?", gender: :f}
             }
    end
  end
end
