defmodule RoomsApiRouter do
  use Dynamo.Router
  import Ecto.Query
  import MogoChat.RouterUtils


  get "/:room_id/users" do
    authenticate_user!(conn)

    room_id = binary_to_integer(conn.params[:room_id])
    room = Repo.get Room, room_id
    now  = current_timestamp()
    seconds_ago = now.sec(now.sec - 7)
    query = from s in RoomUserState,
      where: s.room_id == ^room.id and s.last_pinged_at > ^seconds_ago,
      order_by: s.id,
      preload: :user

    users_attributes = lc room_user_state inlist Repo.all(query) do
      User.public_attributes(room_user_state.user.get)
    end

    json_response([users: users_attributes], conn)
  end


  get "/" do
    authenticate_user!(conn)

    rooms = Repo.all Room
    rooms_attributes = lc room inlist rooms do
      Room.public_attributes(room)
      end
    json_response([rooms: rooms_attributes], conn)
  end


  get "/:room_id" do
    authenticate_user!(conn)

    room_id = conn.params[:room_id]
    room = Repo.get Room, room_id

    [room: Room.public_attributes(room)]
    |> json_response(conn)
  end


  post "/" do
    authorize_user!(conn, ["admin"])

    params = json_decode conn.req_body

    room_params = whitelist_params(params["room"], ["name"])
    room = Room.new room_params

    case Room.validate(room) do
      [] ->
        room = Repo.create(room)
        json_response [room: Room.public_attributes(room)], conn
      errors ->
        json_response [errors: errors], conn, 422
    end
  end


  put "/:room_id" do
    authorize_user!(conn, ["admin"])

    room_id = conn.params[:room_id]
    params = json_decode conn.req_body

    room_params = whitelist_params(params["room"], ["name"])
    room = Repo.get(Room, room_id).update(room_params)

    case Room.validate(room) do
      [] ->
        :ok = Repo.update(room)
        json_response [user: Room.public_attributes(room)], conn
      errors ->
        json_response [errors: errors], conn, 422
    end
  end


  delete "/:room_id" do
    authorize_user!(conn, ["admin"])

    room_id = binary_to_integer(conn.params["room_id"])

    # Note instead of fetching it and deleting it
    # just create a new record and delete it
    room = Room.new(id: room_id)
    Repo.delete room

    # Delete all messages
    Repo.delete_all(from m in Message, where: m.room_id == ^room_id)

    # Delete the room user states
    Repo.delete_all(from rus in RoomUserState, where: rus.room_id == ^room_id)

    json_response("", conn)
  end

end
