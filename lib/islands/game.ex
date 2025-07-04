# ┌────────────────────────────────────────────────────────────────────┐
# │ Based on the book "Functional Web Development" by Lance Halvorsen. │
# └────────────────────────────────────────────────────────────────────┘
defmodule Islands.Game do
  @moduledoc """
  A game struct and functions for the _Game of Islands_.

  The game struct contains the fields `name`, `player1`, `player2`, `request`,
  `response` and `state` representing the properties of a game in the _Game of
  Islands_.

  ##### Based on the book [Functional Web Development](https://pragprog.com/titles/lhelph/functional-web-development-with-elixir-otp-and-phoenix/) by Lance Halvorsen.
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

  @derive JSON.Encoder
  @enforce_keys [:name, :player1, :player2]
  defstruct name: nil,
            player1: nil,
            player2: nil,
            request: {},
            response: {},
            state: State.new()

  @typedoc "Game name"
  @type name :: String.t()
  @typedoc "A game overview map"
  @type overview :: %{
          game_name: name,
          player1: overview_player,
          player2: overview_player
        }
  @typedoc "A game overview player map"
  @type overview_player :: %{name: Player.name(), gender: Player.gender()}
  @typedoc "A game struct for the Game of Islands"
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

  @doc """
  Creates a game struct from `name`, `player1_name`, `gender` and `pid`.

  ## Examples

      iex> alias Islands.{Game, Player}
      iex> {player_name, gender, pid} = {"James", :m, self()}
      iex> game = Game.new("Sky Fall", player_name, gender, pid)
      iex> %Game{name: name, player1: player1} = game
      iex> %Player{name: ^player_name, gender: ^gender, pid: ^pid} = player1
      iex> {name, is_struct(player1, Player), is_struct(game.player2, Player)}
      {"Sky Fall", true, true}

      iex> alias Islands.Game
      iex> {player_name, gender, pid} = {"James", :m, self()}
      iex> Game.new(~c'Sky Fall', player_name, gender, pid)
      {:error, :invalid_game_args}
  """
  @spec new(name, Player.name(), Player.gender(), pid) :: t | {:error, atom}
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

  @doc """
  Updates a player's board struct with `board`.
  """
  @spec update_board(t, PlayerID.t(), Board.t()) :: t
  def update_board(%Game{} = game, player_id, %Board{} = board)
      when player_id in @player_ids,
      do: put_in(game[player_id].board, board)

  @doc """
  Updates a player's guesses struct using `hit_or_miss` and `guess`.
  """
  @spec update_guesses(t, PlayerID.t(), Guesses.type(), Coord.t()) :: t
  def update_guesses(%Game{} = game, player_id, hit_or_miss, %Coord{} = guess)
      when player_id in @player_ids and hit_or_miss in @hit_or_miss do
    update_in(game[player_id].guesses, &Guesses.add(&1, hit_or_miss, guess))
  end

  @doc """
  Updates a player struct using `name`, `gender` and `pid`.
  """
  @spec update_player(t, PlayerID.t(), Player.name(), Player.gender(), pid) :: t
  def update_player(%Game{} = game, player_id, name, gender, pid)
      when player_id in @player_ids and is_binary(name) and is_pid(pid) and
             gender in @genders do
    player = %Player{game[player_id] | name: name, gender: gender, pid: pid}
    put_in(game[player_id], player)
  end

  @doc """
  Sends the game state to a player's process.
  """
  @spec notify_player(t, PlayerID.t()) :: t
  def notify_player(%Game{} = game, player_id) when player_id in @player_ids do
    send(game[player_id].pid, game.state.game_state)
    game
  end

  @doc """
  Returns a player's board struct.
  """
  @spec player_board(t, PlayerID.t()) :: Board.t()
  def player_board(%Game{} = game, player_id) when player_id in @player_ids,
    do: game[player_id].board

  @doc """
  Returns a player's opponent ID.
  """
  @spec opponent_id(PlayerID.t()) :: PlayerID.t()
  def opponent_id(:player1), do: :player2
  def opponent_id(:player2), do: :player1

  @doc """
  Updates the state struct.
  """
  @spec update_state(t, State.t()) :: t
  def update_state(%Game{} = game, %State{} = state),
    do: put_in(game.state, state)

  @doc """
  Updates the request tuple.
  """
  @spec update_request(t, Request.t()) :: t
  def update_request(%Game{} = game, request) when is_tuple(request),
    do: put_in(game.request, request)

  @doc """
  Updates the response tuple.
  """
  @spec update_response(t, Response.t()) :: t
  def update_response(%Game{} = game, response) when is_tuple(response),
    do: put_in(game.response, response)

  @doc """
  Returns a random name of 4 to 10 characters.
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
  Returns a unique, URL-friendly name such as "bold-frog-8249".
  """
  @spec haiku_name :: name
  def haiku_name do
    [Enum.random(@adjectives), Enum.random(@nouns), :rand.uniform(9999)]
    |> Enum.join("-")
  end

  @doc """
  Returns the game overview map of `game`.
  """
  @spec overview(t) :: overview
  def overview(%Game{} = game) do
    %{
      game_name: game.name,
      player1: %{name: game.player1.name, gender: game.player1.gender},
      player2: %{name: game.player2.name, gender: game.player2.gender}
    }
  end

  ## Helpers

  # {1, 2, 3} -> [91, "1", 44, "2", 44, "3", 93]
  # IO.iodata_to_binary ==> "[1,2,3]"
  defimpl JSON.Encoder, for: Tuple do
    @spec encode(tuple, JSON.encoder()) :: iodata
    def encode(tuple, encoder)
        when is_tuple(tuple) and is_function(encoder, 2) do
      Tuple.to_list(tuple) |> JSON.Encoder.encode(encoder)
    end
  end
end
