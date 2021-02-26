CREATE TABLE IF NOT EXISTS `invite_code` (
  `identifier` varchar(25) DEFAULT NULL,
  `code` varchar(20) DEFAULT '00000000',
  `used` tinyint(1) DEFAULT 0,
  `used_by` varchar(25) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;