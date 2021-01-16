# ┌────────────────────────────────────────────────────────────────────┐
# │ Based on the book "Functional Web Development" by Lance Halvorsen. │
# └────────────────────────────────────────────────────────────────────┘
defmodule Islands.Game do
  @moduledoc """
  Models a `game` in the _Game of Islands_.

  ##### Based on the book [Functional Web Development](https://pragprog.com/book/lhelph/functional-web-development-with-elixir-otp-and-phoenix) by Lance Halvorsen.
  """

  @behaviour Access

  use PersistConfig

  alias __MODULE__

  alias Islands.{
    Board,
    Coord,
    Guesses,
    Player,
    PlayerID,
    Request,
    Response,
    State
  }

  @adjectives get_env(:haiku_adjectives)
  @genders [:f, :m]
  @hit_or_miss [:hit, :miss]
  @nouns get_env(:haiku_nouns)
  @player_ids [:player1, :player2]

  @derive [Poison.Encoder]
  @derive Jason.Encoder
  @enforce_keys [:name, :player1, :player2]
  defstruct name: nil,
            player1: nil,
            player2: nil,
            request: {},
            response: {},
            state: State.new()

  @type name :: String.t()
  @type t :: %Game{
          name: name,
          player1: Player.t(),
          player2: Player.t(),
          request: Request.t(),
          response: Response.t(),
          state: State.t()
        }

  # Access behaviour
  defdelegate fetch(game, key), to: Map
  defdelegate get_and_update(game, key, fun), to: Map
  defdelegate pop(game, key), to: Map

  @spec new(name, String.t(), Player.gender(), pid) :: t | {:error, atom}
  def new(name, player1_name, gender, pid)
      when is_binary(name) and is_binary(player1_name) and is_pid(pid) and
             gender in @genders do
    %Game{
      name: name,
      player1: Player.new(player1_name, gender, pid),
      player2: Player.new("?", :f, nil)
    }
  end

  def new(_name, _player1_name, _gender, _pid), do: {:error, :invalid_game_args}

  @spec update_board(t, PlayerID.t(), Board.t()) :: t
  def update_board(%Game{} = game, player_id, %Board{} = board)
      when player_id in @player_ids,
      do: put_in(game[player_id].board, board)

  @spec update_guesses(t, PlayerID.t(), Guesses.type(), Coord.t()) :: t
  def update_guesses(%Game{} = game, player_id, hit_or_miss, %Coord{} = guess)
      when player_id in @player_ids and hit_or_miss in @hit_or_miss do
    update_in(game[player_id].guesses, &Guesses.add(&1, hit_or_miss, guess))
  end

  @spec update_player(t, PlayerID.t(), Player.name(), Player.gender(), pid) :: t
  def update_player(%Game{} = game, player_id, name, gender, pid)
      when player_id in @player_ids and is_binary(name) and is_pid(pid) and
             gender in @genders do
    player = %Player{game[player_id] | name: name, gender: gender, pid: pid}
    put_in(game[player_id], player)
  end

  @spec notify_player(t, PlayerID.t()) :: t
  def notify_player(%Game{} = game, player_id) when player_id in @player_ids do
    send(game[player_id].pid, game.state.game_state)
    game
  end

  @spec player_board(t, PlayerID.t()) :: Board.t()
  def player_board(%Game{} = game, player_id) when player_id in @player_ids,
    do: game[player_id].board

  @spec opponent_id(PlayerID.t()) :: PlayerID.t()
  def opponent_id(:player1), do: :player2
  def opponent_id(:player2), do: :player1

  @spec update_state(t, State.t()) :: t
  def update_state(%Game{} = game, %State{} = state),
    do: put_in(game.state, state)

  @spec update_request(t, Request.t()) :: t
  def update_request(%Game{} = game, request) when is_tuple(request),
    do: put_in(game.request, request)

  @spec update_response(t, Response.t()) :: t
  def update_response(%Game{} = game, response) when is_tuple(response),
    do: put_in(game.response, response)

  @doc """
  Generates a random name.
  """
  @spec random_name :: name
  def random_name do
    length = Enum.random(4..10)

    :crypto.strong_rand_bytes(length)
    |> Base.url_encode64()
    # Starting at 0 with length "length"...
    |> binary_part(0, length)
  end

  @doc """
  Generates a unique, URL-friendly name such as "bold-frog-8249".
  """
  @spec haiku_name :: String.t()
  def haiku_name do
    [Enum.random(@adjectives), Enum.random(@nouns), :rand.uniform(9999)]
    |> Enum.join("-")
  end

  defimpl Poison.Encoder, for: Tuple do
    def encode(data, options) when is_tuple(data) do
      Tuple.to_list(data) |> Poison.Encoder.List.encode(options)
    end
  end

  defimpl Jason.Encoder, for: Tuple do
    def encode(data, opts) when is_tuple(data) do
      Tuple.to_list(data) |> Jason.Encode.list(opts)
    end
  end
end
