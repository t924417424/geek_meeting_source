CREATE TABLE `users` (
  `Id` bigint(20) NOT NULL AUTO_INCREMENT,
  `email` varchar(50) NOT NULL DEFAULT '' COMMENT '邮箱',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`Id`),
  UNIQUE KEY `mail` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `room` (
  `Id` bigint(20) NOT NULL AUTO_INCREMENT,
  `start_time` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `end_time` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `password` varchar(32) NOT NULL DEFAULT '' COMMENT '会议密码',
  `master_id` bigint(20) NOT NULL DEFAULT '0',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `expand` varchar(1) NOT NULL DEFAULT '' COMMENT '不做任何功能，用于查询结果添加字段',
  PRIMARY KEY (`Id`),
  KEY `master_index` (`master_id`),
  CONSTRAINT `room_ibfk_1` FOREIGN KEY (`master_id`) REFERENCES `users` (`Id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB AUTO_INCREMENT=1000 DEFAULT CHARSET=utf8 COMMENT='会议房间';


CREATE TABLE `recond` (
  `Id` bigint(20) NOT NULL AUTO_INCREMENT,
  `user_id` bigint(20) NOT NULL DEFAULT '0',
  `name` varchar(50) DEFAULT NULL COMMENT '会议昵称',
  `room_id` bigint(20) NOT NULL DEFAULT '0' COMMENT '会议ID',
  PRIMARY KEY (`Id`),
  KEY `user_id` (`user_id`),
  KEY `recond_ibfk_2` (`room_id`),
  CONSTRAINT `recond_ibfk_2` FOREIGN KEY (`room_id`) REFERENCES `room` (`Id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `recond_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`Id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='参会记录';
