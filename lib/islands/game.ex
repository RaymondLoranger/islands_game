# ┌───────────────────────────────────────────────────────────────────────┐
# │ Inspired by the book "Functional Web Development" by Lance Halvorsen. │
# └───────────────────────────────────────────────────────────────────────┘
defmodule Islands.Game do
  @behaviour Access

  use PersistConfig

  @book_ref Application.get_env(@app, :book_ref)

  @moduledoc """
  Models a `game` for the _Game of Islands_.
  \n##### #{@book_ref}
  """

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

  @derive [Poison.Encoder]
  @derive Jason.Encoder
  @enforce_keys [:name, :player1, :player2]
  defstruct name: nil,
            player1: nil,
            player2: nil,
            request: {},
            response: {},
            state: State.new()

  @type t :: %Game{
          name: String.t(),
          player1: Player.t(),
          player2: Player.t(),
          request: Request.t(),
          response: Response.t(),
          state: State.t()
        }

  @genders [:f, :m]
  @hit_or_miss [:hit, :miss]
  @player_ids [:player1, :player2]

  # Access behaviour
  defdelegate fetch(game, key), to: Map
  defdelegate get(game, key, default), to: Map
  defdelegate get_and_update(game, key, fun), to: Map
  defdelegate pop(game, key), to: Map

  @spec new(String.t(), String.t(), Player.gender(), pid) :: t | {:error, atom}
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

  @spec update_player_name(t, PlayerID.t(), String.t()) :: t
  def update_player_name(%Game{} = game, player_id, name)
      when player_id in @player_ids and is_binary(name),
      do: put_in(game[player_id].name, name)

  @spec update_player_gender(t, PlayerID.t(), Player.gender()) :: t
  def update_player_gender(%Game{} = game, player_id, gender)
      when player_id in @player_ids and gender in @genders,
      do: put_in(game[player_id].gender, gender)

  @spec update_player_pid(t, PlayerID.t(), pid) :: t
  def update_player_pid(%Game{} = game, player_id, pid)
      when player_id in @player_ids and is_pid(pid),
      do: put_in(game[player_id].pid, pid)

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

  defimpl Poison.Encoder, for: Tuple do
    def encode(data, options) when is_tuple(data) do
      data |> Tuple.to_list() |> Poison.Encoder.List.encode(options)
    end
  end

  defimpl Jason.Encoder, for: Tuple do
    def encode(data, opts) when is_tuple(data) do
      data |> Tuple.to_list() |> Jason.Encode.list(opts)
    end
  end
end
