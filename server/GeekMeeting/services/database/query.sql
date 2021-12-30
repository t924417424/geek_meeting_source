-- name: CreateUser :execresult
INSERT INTO users (`email`) VALUES (?);

-- name: FindUserByEmail :one
SELECT Id FROM users WHERE `email` = ?;

-- name: FindUserById :one
SELECT Id FROM users WHERE `Id` = ?;

-- name: FindUserMeetRooms :many
SELECT room.`Id`,room.`start_time` FROM room LEFT JOIN users ON users.`Id` = room.`master_id` WHERE users.`Id` = ?;

-- name: SelectRoomInfoByNo :one
SELECT Id,start_time,end_time FROM room WHERE `Id` = ?;

-- name: SelectRoomInfoByIdAndPassword :one
SELECT Id,start_time,end_time,master_id,expand FROM room WHERE `Id` = ? AND `password` = ?;

-- name: SelectRecondByUserId :many
SELECT `Id`,`start_time`,`end_time` FROM `room` WHERE `master_id` = ? ORDER BY `Id` DESC LIMIT ?,?;

-- name: SelectRecondByRoomIdAndUserId :one
SELECT recond.`room_id`,recond.`name` FROM recond LEFT JOIN room ON room.`Id` = recond.`room_id` WHERE room.`Id` = ? AND recond.`user_id` = ?;

-- name: CreateRoom :execresult
INSERT INTO room (`start_time`,`end_time`,`password`,`master_id`) VALUES (?,?,?,?);

-- name: InsertRecond :exec
INSERT INTO recond (`user_id`,`name`,`room_id`) VALUES (?,?,?);

-- name: RoomInDayCount :one
SELECT count(Id) FROM room WHERE `master_id` = ? AND `create_time` BETWEEN ? AND ?;