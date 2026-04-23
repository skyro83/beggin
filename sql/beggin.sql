CREATE TABLE IF NOT EXISTS `users` (
  `identifier` VARCHAR(60) NOT NULL,
  `name`       VARCHAR(60) NOT NULL DEFAULT '',
  `accounts`   LONGTEXT    NOT NULL,
  `position`   LONGTEXT    NOT NULL,
  `metadata`   LONGTEXT    NOT NULL,
  `last_seen`  TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `created_at` TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `bans` (
  `id`         INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `identifier` VARCHAR(60)  NOT NULL,
  `name`       VARCHAR(60)  NOT NULL DEFAULT '',
  `reason`     VARCHAR(255) NOT NULL DEFAULT '',
  `banned_by`  VARCHAR(60)  NOT NULL DEFAULT '',
  `expires_at` TIMESTAMP    NULL DEFAULT NULL,
  `created_at` TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_identifier` (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `characters` (
  `id`          INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `identifier`  VARCHAR(60)  NOT NULL,
  `firstname`   VARCHAR(50)  NOT NULL DEFAULT '',
  `lastname`    VARCHAR(50)  NOT NULL DEFAULT '',
  `dateofbirth` VARCHAR(10)  NOT NULL DEFAULT '2000-01-01',
  `gender`      ENUM('male','female') NOT NULL DEFAULT 'male',
  `accounts`    LONGTEXT     NOT NULL,
  `position`    LONGTEXT     NOT NULL,
  `metadata`    LONGTEXT     NOT NULL,
  `appearance`  LONGTEXT     NOT NULL DEFAULT '{}',
  `inventory`   LONGTEXT     NOT NULL DEFAULT '{}',
  `created_at`  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `last_played` TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_identifier` (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `item_transactions` (
  `id`           INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `charid`       INT UNSIGNED NOT NULL,
  `item`         VARCHAR(60)  NOT NULL,
  `delta`        INT          NOT NULL,
  `balance`      INT          NOT NULL,
  `kind`         VARCHAR(20)  NOT NULL,
  `reason`       VARCHAR(120) NOT NULL DEFAULT '',
  `other_charid` INT UNSIGNED NULL,
  `created_at`   TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_charid_id` (`charid`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `money_transactions` (
  `id`           INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `charid`       INT UNSIGNED NOT NULL,
  `account`      VARCHAR(20)  NOT NULL,
  `delta`        BIGINT       NOT NULL,
  `balance`      BIGINT       NOT NULL,
  `kind`         VARCHAR(20)  NOT NULL,
  `reason`       VARCHAR(120) NOT NULL DEFAULT '',
  `other_charid` INT UNSIGNED NULL,
  `created_at`   TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_charid_id` (`charid`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `admin_logs` (
  `id`         INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `admin`      VARCHAR(60)  NOT NULL DEFAULT '',
  `action`     VARCHAR(60)  NOT NULL DEFAULT '',
  `target`     VARCHAR(60)  NOT NULL DEFAULT '',
  `details`    LONGTEXT     NULL,
  `created_at` TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_admin` (`admin`),
  KEY `idx_action` (`action`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
