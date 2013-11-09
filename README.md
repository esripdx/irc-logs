IRC Log Viewer
==============

This is a simple Sinatra app to view IRC logs in a MySQL database.

This assumes two tables exist:

### Logs
```
CREATE TABLE `irclog` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `channel` varchar(30) DEFAULT NULL,
  `nick` varchar(40) DEFAULT NULL,
  `type` varchar(200) DEFAULT NULL,
  `timestamp` int(11) DEFAULT NULL,
  `line` text,
  PRIMARY KEY (`id`),
  KEY `channel` (`channel`),
  KEY `history` (`channel`,`timestamp`)
)
```

### Channel List
```
CREATE TABLE `channels` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `channel` varchar(50) DEFAULT NULL,
  `opers` varchar(255) DEFAULT NULL,
  `date_created` datetime DEFAULT NULL,
  `timezone` varchar(50) NOT NULL DEFAULT 'America/Los_Angeles',
  PRIMARY KEY (`id`),
  UNIQUE KEY `channel` (`channel`)
)
```

