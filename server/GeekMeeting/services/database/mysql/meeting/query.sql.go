// Code generated by sqlc. DO NOT EDIT.
// source: query.sql

package meetingDb

import (
	"context"
	"database/sql"

	"GeekMeeting/internal/sqltime"
)

const createRoom = `-- name: CreateRoom :execresult
INSERT INTO room (` + "`" + `start_time` + "`" + `,` + "`" + `end_time` + "`" + `,` + "`" + `password` + "`" + `,` + "`" + `master_id` + "`" + `) VALUES (?,?,?,?)
`

type CreateRoomParams struct {
	StartTime sqltime.NullTime `json:"start_time"`
	EndTime   sqltime.NullTime `json:"end_time"`
	Password  string           `json:"password"`
	MasterID  int64            `json:"master_id"`
}

func (q *Queries) CreateRoom(ctx context.Context, arg CreateRoomParams) (sql.Result, error) {
	return q.db.ExecContext(ctx, createRoom,
		arg.StartTime,
		arg.EndTime,
		arg.Password,
		arg.MasterID,
	)
}

const createUser = `-- name: CreateUser :execresult
INSERT INTO users (` + "`" + `email` + "`" + `) VALUES (?)
`

func (q *Queries) CreateUser(ctx context.Context, email string) (sql.Result, error) {
	return q.db.ExecContext(ctx, createUser, email)
}

const findUserByEmail = `-- name: FindUserByEmail :one
SELECT Id FROM users WHERE ` + "`" + `email` + "`" + ` = ?
`

func (q *Queries) FindUserByEmail(ctx context.Context, email string) (int64, error) {
	row := q.db.QueryRowContext(ctx, findUserByEmail, email)
	var id int64
	err := row.Scan(&id)
	return id, err
}

const findUserById = `-- name: FindUserById :one
SELECT Id FROM users WHERE ` + "`" + `Id` + "`" + ` = ?
`

func (q *Queries) FindUserById(ctx context.Context, id int64) (int64, error) {
	row := q.db.QueryRowContext(ctx, findUserById, id)
	err := row.Scan(&id)
	return id, err
}

const findUserMeetRooms = `-- name: FindUserMeetRooms :many
SELECT room.` + "`" + `Id` + "`" + `,room.` + "`" + `start_time` + "`" + ` FROM room LEFT JOIN users ON users.` + "`" + `Id` + "`" + ` = room.` + "`" + `master_id` + "`" + ` WHERE users.` + "`" + `Id` + "`" + ` = ?
`

type FindUserMeetRoomsRow struct {
	ID        int64            `json:"id"`
	StartTime sqltime.NullTime `json:"start_time"`
}

func (q *Queries) FindUserMeetRooms(ctx context.Context, id int64) ([]FindUserMeetRoomsRow, error) {
	rows, err := q.db.QueryContext(ctx, findUserMeetRooms, id)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var items []FindUserMeetRoomsRow
	for rows.Next() {
		var i FindUserMeetRoomsRow
		if err := rows.Scan(&i.ID, &i.StartTime); err != nil {
			return nil, err
		}
		items = append(items, i)
	}
	if err := rows.Close(); err != nil {
		return nil, err
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}
	return items, nil
}

const insertRecond = `-- name: InsertRecond :exec
INSERT INTO recond (` + "`" + `user_id` + "`" + `,` + "`" + `name` + "`" + `,` + "`" + `room_id` + "`" + `) VALUES (?,?,?)
`

type InsertRecondParams struct {
	UserID int64          `json:"user_id"`
	Name   sql.NullString `json:"name"`
	RoomID int64          `json:"room_id"`
}

func (q *Queries) InsertRecond(ctx context.Context, arg InsertRecondParams) error {
	_, err := q.db.ExecContext(ctx, insertRecond, arg.UserID, arg.Name, arg.RoomID)
	return err
}

const roomInDayCount = `-- name: RoomInDayCount :one
SELECT count(Id) FROM room WHERE ` + "`" + `master_id` + "`" + ` = ? AND ` + "`" + `create_time` + "`" + ` BETWEEN ? AND ?
`

type RoomInDayCountParams struct {
	MasterID     int64            `json:"master_id"`
	CreateTime   sqltime.NullTime `json:"create_time"`
	CreateTime_2 sqltime.NullTime `json:"create_time_2"`
}

func (q *Queries) RoomInDayCount(ctx context.Context, arg RoomInDayCountParams) (int64, error) {
	row := q.db.QueryRowContext(ctx, roomInDayCount, arg.MasterID, arg.CreateTime, arg.CreateTime_2)
	var count int64
	err := row.Scan(&count)
	return count, err
}

const selectRecondByRoomIdAndUserId = `-- name: SelectRecondByRoomIdAndUserId :one
SELECT recond.` + "`" + `room_id` + "`" + `,recond.` + "`" + `name` + "`" + ` FROM recond LEFT JOIN room ON room.` + "`" + `Id` + "`" + ` = recond.` + "`" + `room_id` + "`" + ` WHERE room.` + "`" + `Id` + "`" + ` = ? AND recond.` + "`" + `user_id` + "`" + ` = ?
`

type SelectRecondByRoomIdAndUserIdParams struct {
	ID     int64 `json:"id"`
	UserID int64 `json:"user_id"`
}

type SelectRecondByRoomIdAndUserIdRow struct {
	RoomID int64          `json:"room_id"`
	Name   sql.NullString `json:"name"`
}

func (q *Queries) SelectRecondByRoomIdAndUserId(ctx context.Context, arg SelectRecondByRoomIdAndUserIdParams) (SelectRecondByRoomIdAndUserIdRow, error) {
	row := q.db.QueryRowContext(ctx, selectRecondByRoomIdAndUserId, arg.ID, arg.UserID)
	var i SelectRecondByRoomIdAndUserIdRow
	err := row.Scan(&i.RoomID, &i.Name)
	return i, err
}

const selectRecondByUserId = `-- name: SelectRecondByUserId :many
SELECT ` + "`" + `Id` + "`" + `,` + "`" + `start_time` + "`" + `,` + "`" + `end_time` + "`" + ` FROM ` + "`" + `room` + "`" + ` WHERE ` + "`" + `master_id` + "`" + ` = ? ORDER BY ` + "`" + `Id` + "`" + ` DESC LIMIT ?,?
`

type SelectRecondByUserIdParams struct {
	MasterID int64 `json:"master_id"`
	Offset   int32 `json:"offset"`
	Limit    int32 `json:"limit"`
}

type SelectRecondByUserIdRow struct {
	ID        int64            `json:"id"`
	StartTime sqltime.NullTime `json:"start_time"`
	EndTime   sqltime.NullTime `json:"end_time"`
}

func (q *Queries) SelectRecondByUserId(ctx context.Context, arg SelectRecondByUserIdParams) ([]SelectRecondByUserIdRow, error) {
	rows, err := q.db.QueryContext(ctx, selectRecondByUserId, arg.MasterID, arg.Offset, arg.Limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var items []SelectRecondByUserIdRow
	for rows.Next() {
		var i SelectRecondByUserIdRow
		if err := rows.Scan(&i.ID, &i.StartTime, &i.EndTime); err != nil {
			return nil, err
		}
		items = append(items, i)
	}
	if err := rows.Close(); err != nil {
		return nil, err
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}
	return items, nil
}

const selectRoomInfoByIdAndPassword = `-- name: SelectRoomInfoByIdAndPassword :one
SELECT Id,start_time,end_time,master_id,expand FROM room WHERE ` + "`" + `Id` + "`" + ` = ? AND ` + "`" + `password` + "`" + ` = ?
`

type SelectRoomInfoByIdAndPasswordParams struct {
	ID       int64  `json:"id"`
	Password string `json:"password"`
}

type SelectRoomInfoByIdAndPasswordRow struct {
	ID        int64            `json:"id"`
	StartTime sqltime.NullTime `json:"start_time"`
	EndTime   sqltime.NullTime `json:"end_time"`
	MasterID  int64            `json:"master_id"`
	Expand    string           `json:"expand"`
}

func (q *Queries) SelectRoomInfoByIdAndPassword(ctx context.Context, arg SelectRoomInfoByIdAndPasswordParams) (SelectRoomInfoByIdAndPasswordRow, error) {
	row := q.db.QueryRowContext(ctx, selectRoomInfoByIdAndPassword, arg.ID, arg.Password)
	var i SelectRoomInfoByIdAndPasswordRow
	err := row.Scan(
		&i.ID,
		&i.StartTime,
		&i.EndTime,
		&i.MasterID,
		&i.Expand,
	)
	return i, err
}

const selectRoomInfoByNo = `-- name: SelectRoomInfoByNo :one
SELECT Id,start_time,end_time FROM room WHERE ` + "`" + `Id` + "`" + ` = ?
`

type SelectRoomInfoByNoRow struct {
	ID        int64            `json:"id"`
	StartTime sqltime.NullTime `json:"start_time"`
	EndTime   sqltime.NullTime `json:"end_time"`
}

func (q *Queries) SelectRoomInfoByNo(ctx context.Context, id int64) (SelectRoomInfoByNoRow, error) {
	row := q.db.QueryRowContext(ctx, selectRoomInfoByNo, id)
	var i SelectRoomInfoByNoRow
	err := row.Scan(&i.ID, &i.StartTime, &i.EndTime)
	return i, err
}