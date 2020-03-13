defmodule Islands.GameTest do
  use ExUnit.Case, async: true

  alias Islands.{Game, Player}

  doctest Game

  setup_all do
    this = self()
    eden = Game.new("Eden", "Adam", :m, this)

    poison =
      ~s<{\"state\":{\"player2_state\":\"islands_not_set\",\"player1_state\":\"islands_not_set\",\"game_state\":\"initialized\"},\"response\":[],\"request\":[],\"player2\":{\"name\":\"?\",\"gender\":\"f\"},\"player1\":{\"name\":\"Adam\",\"gender\":\"m\"},\"name\":\"Eden\"}>

    jason =
      ~s<{\"name\":\"Eden\",\"player1\":{\"name\":\"Adam\",\"gender\":\"m\"},\"player2\":{\"name\":\"?\",\"gender\":\"f\"},\"request\":[],\"response\":[],\"state\":{\"game_state\":\"initialized\",\"player1_state\":\"islands_not_set\",\"player2_state\":\"islands_not_set\"}}>

    decoded = %{
      "name" => "Eden",
      "player1" => %{
        "gender" => "m",
        "name" => "Adam"
      },
      "player2" => %{
        "gender" => "f",
        "name" => "?"
      },
      "request" => [],
      "response" => [],
      "state" => %{
        "game_state" => "initialized",
        "player1_state" => "islands_not_set",
        "player2_state" => "islands_not_set"
      }
    }

    {:ok, json: %{poison: poison, jason: jason, decoded: decoded}, game: eden}
  end

  describe "A game struct" do
    test "can be encoded by Poison", %{game: eden, json: json} do
      assert Poison.encode!(eden) == json.poison
      assert Poison.decode!(json.poison) == json.decoded
    end

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
               player1: %Player{name: "Jordan", gender: :m, pid: me}
             } = Game.new("Aveline", "Jordan", :m, me)
    end

    test "returns {:error, ...} given invalid args" do
      assert Game.new("Aveline", "Jordan", :m, :pid) ==
               {:error, :invalid_game_args}
    end
  end
end
