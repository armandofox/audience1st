# CocoaMySQL dump
# Version 0.7b4
# http://cocoamysql.sourceforge.net
#
# Host: localhost (MySQL 4.0.17)
# Database: audience_vbodevelopment
# Generation Time: 2006-08-20 15:55:48 -0700
# ************************************************************

# Dump of table config_params
# ------------------------------------------------------------

DROP TABLE IF EXISTS `config_params`;

CREATE TABLE `config_params` (
  `id` int(11) NOT NULL auto_increment,
  `param_name` varchar(255) NOT NULL default '',
  `param_value` varchar(255) NOT NULL default '',
  `param_desc` varchar(255) NOT NULL default '',
  `updated_at` datetime default NULL,
  PRIMARY KEY  (`id`)
) TYPE=MyISAM;



# Dump of table customers
# ------------------------------------------------------------

DROP TABLE IF EXISTS `customers`;

CREATE TABLE `customers` (
  `id` int(16) NOT NULL auto_increment,
  `first_name` varchar(64) default '',
  `last_name` varchar(64) default '',
  `street` varchar(80) default '',
  `city` varchar(64) default '',
  `state` varchar(8) default 'CA',
  `zip` varchar(12) default NULL,
  `day_phone` varchar(50) default '',
  `eve_phone` varchar(50) default '',
  `phplist_user_user_id` int(11) default '0',
  `login` varchar(30) default NULL,
  `hashed_password` varchar(255) default NULL,
  `salt` varchar(12) default NULL,
  `role` varchar(8) default NULL,
  `subscriber_since` int(11) NOT NULL default '2004',
  `subscriber_until` int(11) NOT NULL default '2004',
  `created_on` datetime default NULL,
  `updated_on` datetime default NULL,
  PRIMARY KEY  (`id`)
) TYPE=MyISAM;

INSERT INTO `customers` (`id`,`first_name`,`last_name`,`street`,`city`,`state`,`zip`,`day_phone`,`eve_phone`,`phplist_user_user_id`,`login`,`hashed_password`,`salt`,`role`,`subscriber_since`,`subscriber_until`,`created_on`,`updated_on`) VALUES ('1','Administrator','','','','','','','','0','admin','47ed300c33ffff956995ce13b5d4f6384cbfe0db','KCf7Clsg4e','admin','2004','0',NULL,'2006-07-26 12:54:17');
INSERT INTO `customers` (`id`,`first_name`,`last_name`,`street`,`city`,`state`,`zip`,`day_phone`,`eve_phone`,`phplist_user_user_id`,`login`,`hashed_password`,`salt`,`role`,`subscriber_since`,`subscriber_until`,`created_on`,`updated_on`) VALUES ('2','Tom','Foolery','45226 High St','Oakland','CA','','','','0','tom@foolery.com','da12d8a5dab6c0b70cb67bd1927058f50a9e2227','L425RCbNXf',NULL,'2004','2006',NULL,'2006-08-18 13:28:17');
INSERT INTO `customers` (`id`,`first_name`,`last_name`,`street`,`city`,`state`,`zip`,`day_phone`,`eve_phone`,`phplist_user_user_id`,`login`,`hashed_password`,`salt`,`role`,`subscriber_since`,`subscriber_until`,`created_on`,`updated_on`) VALUES ('17627153','Carolyn','Zola','399 Dolores','San Francisco','CA','94110','4153550585','4153550585','0','zolac@earthlink.net','e7ec6a7ef57a6d98292238c1130b48e81b3d8fa8','MC4vhthSRW','','2004','0','2005-02-03 00:00:00',NULL);
INSERT INTO `customers` (`id`,`first_name`,`last_name`,`street`,`city`,`state`,`zip`,`day_phone`,`eve_phone`,`phplist_user_user_id`,`login`,`hashed_password`,`salt`,`role`,`subscriber_since`,`subscriber_until`,`created_on`,`updated_on`) VALUES ('56450184','John','Zanakis','2217 San Jose Ave','Alameda','CA','94501','5105233378','5105233378','0',NULL,'d1f52259606c9b68f5beae05eb8832a8144f5ca4','Eyf9QVYH6E','','2004','0','2005-09-24 00:00:00',NULL);
INSERT INTO `customers` (`id`,`first_name`,`last_name`,`street`,`city`,`state`,`zip`,`day_phone`,`eve_phone`,`phplist_user_user_id`,`login`,`hashed_password`,`salt`,`role`,`subscriber_since`,`subscriber_until`,`created_on`,`updated_on`) VALUES ('124556082','Jennie','Zuniga','3020 Bateman Street','Berkeley','CA','94705','9175386352','9175386352','0','jenniezuniga@yahoo.com','a05eaf2083e8b95b6d0cf5788224ca9fed286057','yF4dFPiWsq','','2004','0','2005-08-06 00:00:00',NULL);
INSERT INTO `customers` (`id`,`first_name`,`last_name`,`street`,`city`,`state`,`zip`,`day_phone`,`eve_phone`,`phplist_user_user_id`,`login`,`hashed_password`,`salt`,`role`,`subscriber_since`,`subscriber_until`,`created_on`,`updated_on`) VALUES ('230040961','Jim & Yana','Zimmerman','223 27th Street','San Francisco','CA','94131','4156483117','','0','jimandyana@msn.com','9f38f185dbdd8f4899766844d3c907deeac78fb5','BtmVgVZXer','','2004','0','2005-09-29 00:00:00',NULL);
INSERT INTO `customers` (`id`,`first_name`,`last_name`,`street`,`city`,`state`,`zip`,`day_phone`,`eve_phone`,`phplist_user_user_id`,`login`,`hashed_password`,`salt`,`role`,`subscriber_since`,`subscriber_until`,`created_on`,`updated_on`) VALUES ('388819764','Beverly','Zinn','35 Craig Avenue','Piedmont','CA','94611','5105473422','','0',NULL,'5913fb732415233c9be365ee468343c19522f029','gbNNeiRnYg','','2004','0','2003-07-24 00:00:00',NULL);
INSERT INTO `customers` (`id`,`first_name`,`last_name`,`street`,`city`,`state`,`zip`,`day_phone`,`eve_phone`,`phplist_user_user_id`,`login`,`hashed_password`,`salt`,`role`,`subscriber_since`,`subscriber_until`,`created_on`,`updated_on`) VALUES ('463297003','Steve','Zimmerman','','','CA','0','5105227673','5105227673','0',NULL,'ff786f83dd004b492e93871e541b216d0ba03ab5','cieYFCos4X','','2004','0','2003-08-04 00:00:00',NULL);
INSERT INTO `customers` (`id`,`first_name`,`last_name`,`street`,`city`,`state`,`zip`,`day_phone`,`eve_phone`,`phplist_user_user_id`,`login`,`hashed_password`,`salt`,`role`,`subscriber_since`,`subscriber_until`,`created_on`,`updated_on`) VALUES ('757597765','Tony','Zizzo',NULL,NULL,'CA','0','5105555555',NULL,'0',NULL,'994b2c389997527cd24017d4514235c45bc734ba','tGLuIkwD7q','','2004','0','2004-01-21 00:00:00',NULL);
INSERT INTO `customers` (`id`,`first_name`,`last_name`,`street`,`city`,`state`,`zip`,`day_phone`,`eve_phone`,`phplist_user_user_id`,`login`,`hashed_password`,`salt`,`role`,`subscriber_since`,`subscriber_until`,`created_on`,`updated_on`) VALUES ('786025975','Mark','Zuzinec','334 lexington street','san francisco','CA','94110','4155551212','4155551212','0','sfmark@hotmail.com','9da70ba6e918fe59b71e9d6111414465abfa88a8','IeQRfzRQSX','','2004','0','2005-02-22 00:00:00',NULL);
INSERT INTO `customers` (`id`,`first_name`,`last_name`,`street`,`city`,`state`,`zip`,`day_phone`,`eve_phone`,`phplist_user_user_id`,`login`,`hashed_password`,`salt`,`role`,`subscriber_since`,`subscriber_until`,`created_on`,`updated_on`) VALUES ('926289957','Michael and Diane','Zumbrunnen','1316 East Shore Drive','Alameda','CA','94501','5105555555','','0','musicduo@pacbell.net','4a449d8f4174d6ea9cb4ecf06f7d2a30a8c38d7e','hrTKRKMXPu','','2004','0','2003-07-24 00:00:00',NULL);
INSERT INTO `customers` (`id`,`first_name`,`last_name`,`street`,`city`,`state`,`zip`,`day_phone`,`eve_phone`,`phplist_user_user_id`,`login`,`hashed_password`,`salt`,`role`,`subscriber_since`,`subscriber_until`,`created_on`,`updated_on`) VALUES ('1003639519','Stephen','Zimmerman','3323 Central Avenue','Alameda','CA','94501','5105227673','','0','alamedaphoto@aol.com','4d9e074419ba794308d9f731cbd8103cf2655598','jUbhpDKE09','','2004','0','2003-07-24 00:00:00',NULL);
INSERT INTO `customers` (`id`,`first_name`,`last_name`,`street`,`city`,`state`,`zip`,`day_phone`,`eve_phone`,`phplist_user_user_id`,`login`,`hashed_password`,`salt`,`role`,`subscriber_since`,`subscriber_until`,`created_on`,`updated_on`) VALUES ('1081968540','Beverly','Zellick','105 Ironwood Road','Alameda','CA','94502','5107490808','5107490808','0','bzellick@aol.com','b06ba73aca753a8690f7ec6838ef839baf26d41d','wzcaTjYBsx','','2004','0','2004-04-14 00:00:00',NULL);
INSERT INTO `customers` (`id`,`first_name`,`last_name`,`street`,`city`,`state`,`zip`,`day_phone`,`eve_phone`,`phplist_user_user_id`,`login`,`hashed_password`,`salt`,`role`,`subscriber_since`,`subscriber_until`,`created_on`,`updated_on`) VALUES ('1136762039','Vicki','Zabarte','1006 Baywood Lane','Hercules','CA','94547','5103341256','5109640250','0','vzabarte@sbcglobal.net','0060a03bbb1fc31ff6de33573bfd2e4390af63ec','RKNgbUkPwt','','2004','0','2006-01-08 00:00:00',NULL);
INSERT INTO `customers` (`id`,`first_name`,`last_name`,`street`,`city`,`state`,`zip`,`day_phone`,`eve_phone`,`phplist_user_user_id`,`login`,`hashed_password`,`salt`,`role`,`subscriber_since`,`subscriber_until`,`created_on`,`updated_on`) VALUES ('1173214050','Margaret','Zechman','25 Gleneden Avenue','Oakland','CA','94611','5105555555','','0',NULL,'9ba6d4d976d7f33ca4ff760d26e90624105e61e8','rqPgyjW875','','2004','0','2004-08-29 00:00:00',NULL);
INSERT INTO `customers` (`id`,`first_name`,`last_name`,`street`,`city`,`state`,`zip`,`day_phone`,`eve_phone`,`phplist_user_user_id`,`login`,`hashed_password`,`salt`,`role`,`subscriber_since`,`subscriber_until`,`created_on`,`updated_on`) VALUES ('1223268608','Carrie','Zoller','P.O. Box 370080','montara','CA','94037','4158658829','6505639264','0','carrie.zoller@sbcglobal.net','b30b2c286eb2aad5606befd8d3f15d36446d014e','c5eMAcd8K2','','2004','0','2005-09-22 00:00:00',NULL);
INSERT INTO `customers` (`id`,`first_name`,`last_name`,`street`,`city`,`state`,`zip`,`day_phone`,`eve_phone`,`phplist_user_user_id`,`login`,`hashed_password`,`salt`,`role`,`subscriber_since`,`subscriber_until`,`created_on`,`updated_on`) VALUES ('1426793782','Beverely J','Zellick','105 Ironwood Wd.','Alameda','CA','94502','5107490808','','0',NULL,'668d3a514b43bdaa926ec3a86eba1fa162f72d6a','uJ2MmzmMd2','','2004','0','2004-02-13 00:00:00',NULL);
INSERT INTO `customers` (`id`,`first_name`,`last_name`,`street`,`city`,`state`,`zip`,`day_phone`,`eve_phone`,`phplist_user_user_id`,`login`,`hashed_password`,`salt`,`role`,`subscriber_since`,`subscriber_until`,`created_on`,`updated_on`) VALUES ('1583691583','Bev','Zonderman',NULL,NULL,'CA','0','5104513231','5104513231','0',NULL,'d2efdc4b52682750d2b508d7b8d446b3692ad26f','ebsv7rwAOG','','2004','0','2003-09-08 00:00:00',NULL);
INSERT INTO `customers` (`id`,`first_name`,`last_name`,`street`,`city`,`state`,`zip`,`day_phone`,`eve_phone`,`phplist_user_user_id`,`login`,`hashed_password`,`salt`,`role`,`subscriber_since`,`subscriber_until`,`created_on`,`updated_on`) VALUES ('1826968679',' Derryl','Zeller','205 Sherwoood Lane','Alameda','CA','94502','5105232015','','0',NULL,'bdc97c0f94eaef02a15d0bd738800469465cf927','BXH8PCSDlH','','2004','0','2004-04-15 00:00:00',NULL);
INSERT INTO `customers` (`id`,`first_name`,`last_name`,`street`,`city`,`state`,`zip`,`day_phone`,`eve_phone`,`phplist_user_user_id`,`login`,`hashed_password`,`salt`,`role`,`subscriber_since`,`subscriber_until`,`created_on`,`updated_on`) VALUES ('1886483638','Patty','Zajec','4481 Hillsborough Drive','Castro Valley','CA','94546','5105378333','5105378333','0','','3ad4417b2a73cfd80f3df2263ed208f98a9590a2','cGxeWU1zEG','','2004','0','2003-07-20 00:00:00',NULL);
INSERT INTO `customers` (`id`,`first_name`,`last_name`,`street`,`city`,`state`,`zip`,`day_phone`,`eve_phone`,`phplist_user_user_id`,`login`,`hashed_password`,`salt`,`role`,`subscriber_since`,`subscriber_until`,`created_on`,`updated_on`) VALUES ('1925395366','Steve','Zhang','1357 11th Ave','San Francisco','CA','94122','4088916319','4088916319','0','steveyz@hotmail.com','3e6e149c9b133c954db640376069b2cc0eefbed5','SFVgpSg097','','2004','0','2005-07-28 00:00:00',NULL);


# Dump of table orders
# ------------------------------------------------------------

DROP TABLE IF EXISTS `orders`;

CREATE TABLE `orders` (
  `id` int(11) NOT NULL auto_increment,
  `customer_id` int(11) NOT NULL default '1',
  `show_id` int(11) default NULL,
  `showdate_id` int(11) default NULL,
  `transaction_date` datetime default NULL,
  `purchasemethod_id` int(11) default NULL,
  `comments` varchar(255) default NULL,
  `txn_type` int(10) unsigned NOT NULL default '0',
  PRIMARY KEY  (`id`)
) TYPE=MyISAM;



# Dump of table purchasemethods
# ------------------------------------------------------------

DROP TABLE IF EXISTS `purchasemethods`;

CREATE TABLE `purchasemethods` (
  `id` tinyint(11) unsigned NOT NULL auto_increment,
  `description` varchar(255) NOT NULL default '',
  `included_vouchers` varchar(255) NOT NULL default '',
  `offer_public?` tinyint(1) NOT NULL default '0',
  `is_subscription?` tinyint(1) default NULL,
  `info_url` varchar(255) default NULL,
  PRIMARY KEY  (`id`)
) TYPE=MyISAM;

INSERT INTO `purchasemethods` (`id`,`description`,`included_vouchers`,`offer_public?`,`is_subscription?`,`info_url`) VALUES ('1','Customer purchase','--- !map:HashWithIndifferentAccess \n\"6\": \"0\"\n\"7\": \"0\"\n\"1\": \"0\"\n\"2\": \"0\"\n\"3\": \"0\"\n\"4\": \"0\"\n\"5\": \"0\"\n','0','0',NULL);
INSERT INTO `purchasemethods` (`id`,`description`,`included_vouchers`,`offer_public?`,`is_subscription?`,`info_url`) VALUES ('3','Gift certificate','--- !map:HashWithIndifferentAccess \n\"6\": \"0\"\n\"7\": \"0\"\n\"1\": \"0\"\n\"2\": \"0\"\n\"3\": \"0\"\n\"4\": \"0\"\n\"5\": \"0\"\n','1','0',NULL);
INSERT INTO `purchasemethods` (`id`,`description`,`included_vouchers`,`offer_public?`,`is_subscription?`,`info_url`) VALUES ('6','Other','--- !map:HashWithIndifferentAccess \n\"6\": \"0\"\n\"7\": \"0\"\n\"1\": \"0\"\n\"2\": \"0\"\n\"3\": \"0\"\n\"4\": \"0\"\n\"5\": \"0\"\n','0','0',NULL);
INSERT INTO `purchasemethods` (`id`,`description`,`included_vouchers`,`offer_public?`,`is_subscription?`,`info_url`) VALUES ('7','Comp','--- !map:HashWithIndifferentAccess \n\"6\": \"0\"\n\"7\": \"0\"\n\"1\": \"0\"\n\"2\": \"0\"\n\"3\": \"0\"\n\"4\": \"0\"\n\"5\": \"0\"\n','0','0',NULL);
INSERT INTO `purchasemethods` (`id`,`description`,`included_vouchers`,`offer_public?`,`is_subscription?`,`info_url`) VALUES ('8','Entered by staff','--- !map:HashWithIndifferentAccess \n\"6\": \"0\"\n\"7\": \"0\"\n\"1\": \"0\"\n\"2\": \"0\"\n\"3\": \"0\"\n\"4\": \"0\"\n\"5\": \"0\"\n','0','0',NULL);
INSERT INTO `purchasemethods` (`id`,`description`,`included_vouchers`,`offer_public?`,`is_subscription?`,`info_url`) VALUES ('9','2006 Mini-Subscription','--- !map:HashWithIndifferentAccess \n\"6\": \"1\"\n\"7\": \"2\"\n\"1\": \"0\"\n\"2\": \"0\"\n\"3\": \"0\"\n\"4\": \"0\"\n\"5\": \"0\"\n','1','1',NULL);
INSERT INTO `purchasemethods` (`id`,`description`,`included_vouchers`,`offer_public?`,`is_subscription?`,`info_url`) VALUES ('10','2006 5-show Subscription','--- !map:HashWithIndifferentAccess \n\"6\": \"2\"\n\"7\": \"3\"\n\"1\": \"0\"\n\"2\": \"0\"\n\"3\": \"0\"\n\"4\": \"0\"\n\"5\": \"0\"\n','1','1',NULL);


# Dump of table schema_info
# ------------------------------------------------------------

DROP TABLE IF EXISTS `schema_info`;

CREATE TABLE `schema_info` (
  `version` int(11) default NULL
) TYPE=MyISAM;

INSERT INTO `schema_info` (`version`) VALUES ('6');


# Dump of table showdates
# ------------------------------------------------------------

DROP TABLE IF EXISTS `showdates`;

CREATE TABLE `showdates` (
  `thedate` datetime default NULL,
  `end_advance_sales` datetime default NULL,
  `max_sales` int(11) unsigned NOT NULL default '0',
  `show_id` int(11) unsigned NOT NULL default '0',
  `id` int(5) unsigned NOT NULL auto_increment,
  PRIMARY KEY  (`id`)
) TYPE=InnoDB;

INSERT INTO `showdates` (`thedate`,`end_advance_sales`,`max_sales`,`show_id`,`id`) VALUES ('2007-12-20 20:00:00','2007-12-20 17:00:00','0','1','4');
INSERT INTO `showdates` (`thedate`,`end_advance_sales`,`max_sales`,`show_id`,`id`) VALUES ('2007-07-20 11:23:00','2007-07-19 11:23:00','155','2','7');
INSERT INTO `showdates` (`thedate`,`end_advance_sales`,`max_sales`,`show_id`,`id`) VALUES ('2007-07-19 11:43:00','2007-07-19 11:43:00','215','2','13');
INSERT INTO `showdates` (`thedate`,`end_advance_sales`,`max_sales`,`show_id`,`id`) VALUES ('2006-07-19 12:11:00','2006-07-19 12:11:00','150','4','14');
INSERT INTO `showdates` (`thedate`,`end_advance_sales`,`max_sales`,`show_id`,`id`) VALUES ('2006-07-19 16:48:00','2006-07-19 16:48:00','160','4','15');
INSERT INTO `showdates` (`thedate`,`end_advance_sales`,`max_sales`,`show_id`,`id`) VALUES ('2006-07-20 17:35:00','2006-07-19 17:35:00','170','4','16');
INSERT INTO `showdates` (`thedate`,`end_advance_sales`,`max_sales`,`show_id`,`id`) VALUES ('2007-01-26 20:00:00','2007-01-25 00:00:00','250','1','17');
INSERT INTO `showdates` (`thedate`,`end_advance_sales`,`max_sales`,`show_id`,`id`) VALUES ('2006-07-27 17:09:00','2006-07-20 17:09:00','222','3','20');
INSERT INTO `showdates` (`thedate`,`end_advance_sales`,`max_sales`,`show_id`,`id`) VALUES ('2006-07-20 17:44:00','2006-07-20 17:44:00','5','3','23');
INSERT INTO `showdates` (`thedate`,`end_advance_sales`,`max_sales`,`show_id`,`id`) VALUES ('2006-07-15 18:52:00','2006-07-28 18:52:00','0','3','25');
INSERT INTO `showdates` (`thedate`,`end_advance_sales`,`max_sales`,`show_id`,`id`) VALUES ('2008-08-13 15:15:00','2006-08-13 15:15:00','0','4','27');
INSERT INTO `showdates` (`thedate`,`end_advance_sales`,`max_sales`,`show_id`,`id`) VALUES ('2010-08-13 15:17:00','2006-08-13 15:17:00','0','4','28');


# Dump of table shows
# ------------------------------------------------------------

DROP TABLE IF EXISTS `shows`;

CREATE TABLE `shows` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(255) default NULL,
  `opening_date` date default NULL,
  `closing_date` date default NULL,
  `house_capacity` smallint(5) unsigned NOT NULL default '0',
  `created_on` datetime NOT NULL default '0000-00-00 00:00:00',
  PRIMARY KEY  (`id`)
) TYPE=InnoDB;

INSERT INTO `shows` (`id`,`name`,`opening_date`,`closing_date`,`house_capacity`,`created_on`) VALUES ('1','A Grand Night For Singing','2007-01-19','2007-02-17','160','2006-07-18 18:36:00');
INSERT INTO `shows` (`id`,`name`,`opening_date`,`closing_date`,`house_capacity`,`created_on`) VALUES ('2','Who\'s Afraid of Virginia Woolf?','2007-03-09','2007-04-07','150','2006-07-18 18:37:00');
INSERT INTO `shows` (`id`,`name`,`opening_date`,`closing_date`,`house_capacity`,`created_on`) VALUES ('3','The Last Five Years','2007-05-18','2007-06-16','180','2006-07-18 18:38:00');
INSERT INTO `shows` (`id`,`name`,`opening_date`,`closing_date`,`house_capacity`,`created_on`) VALUES ('4','Oh My Godmother!','2007-06-13','2007-07-17','0','2006-07-19 12:11:26');


# Dump of table valid_vouchers
# ------------------------------------------------------------

DROP TABLE IF EXISTS `valid_vouchers`;

CREATE TABLE `valid_vouchers` (
  `offer_public?` tinyint(1) default NULL,
  `showdate_id` int(11) unsigned default NULL,
  `vouchertype_id` int(11) unsigned default NULL,
  `password` varchar(255) default NULL,
  `start_sales` datetime default NULL,
  `end_sales` datetime default NULL,
  `max_sales_for_type` smallint(6) unsigned NOT NULL default '0',
  `id` smallint(6) unsigned NOT NULL auto_increment,
  PRIMARY KEY  (`id`)
) TYPE=InnoDB;

INSERT INTO `valid_vouchers` (`offer_public?`,`showdate_id`,`vouchertype_id`,`password`,`start_sales`,`end_sales`,`max_sales_for_type`,`id`) VALUES ('0','4','1','','2006-07-28 16:26:00','2007-01-01 16:26:00','55','38');
INSERT INTO `valid_vouchers` (`offer_public?`,`showdate_id`,`vouchertype_id`,`password`,`start_sales`,`end_sales`,`max_sales_for_type`,`id`) VALUES ('0','17','1','','2006-07-28 16:26:00','2006-07-28 16:26:00','0','39');
INSERT INTO `valid_vouchers` (`offer_public?`,`showdate_id`,`vouchertype_id`,`password`,`start_sales`,`end_sales`,`max_sales_for_type`,`id`) VALUES ('0','24','1','','2006-07-28 16:26:00','2006-07-28 16:26:00','0','40');
INSERT INTO `valid_vouchers` (`offer_public?`,`showdate_id`,`vouchertype_id`,`password`,`start_sales`,`end_sales`,`max_sales_for_type`,`id`) VALUES ('0','4','3','','2006-07-28 16:27:00','2006-07-28 16:27:00','0','41');
INSERT INTO `valid_vouchers` (`offer_public?`,`showdate_id`,`vouchertype_id`,`password`,`start_sales`,`end_sales`,`max_sales_for_type`,`id`) VALUES ('0','17','3','','2006-07-28 16:27:00','2006-07-28 16:27:00','0','42');
INSERT INTO `valid_vouchers` (`offer_public?`,`showdate_id`,`vouchertype_id`,`password`,`start_sales`,`end_sales`,`max_sales_for_type`,`id`) VALUES ('0','24','3','','2006-07-28 16:27:00','2006-07-28 16:27:00','0','43');
INSERT INTO `valid_vouchers` (`offer_public?`,`showdate_id`,`vouchertype_id`,`password`,`start_sales`,`end_sales`,`max_sales_for_type`,`id`) VALUES ('0','24','5','','2006-07-28 16:27:00','2006-07-28 16:27:00','0','44');
INSERT INTO `valid_vouchers` (`offer_public?`,`showdate_id`,`vouchertype_id`,`password`,`start_sales`,`end_sales`,`max_sales_for_type`,`id`) VALUES ('0','18','5','','2006-07-28 18:52:00','2006-07-28 18:52:00','0','45');
INSERT INTO `valid_vouchers` (`offer_public?`,`showdate_id`,`vouchertype_id`,`password`,`start_sales`,`end_sales`,`max_sales_for_type`,`id`) VALUES ('1','18','1','','2006-07-28 18:52:00','2006-07-28 18:52:00','0','46');
INSERT INTO `valid_vouchers` (`offer_public?`,`showdate_id`,`vouchertype_id`,`password`,`start_sales`,`end_sales`,`max_sales_for_type`,`id`) VALUES ('1','20','1','','2006-07-28 18:52:00','2006-07-28 18:52:00','0','47');
INSERT INTO `valid_vouchers` (`offer_public?`,`showdate_id`,`vouchertype_id`,`password`,`start_sales`,`end_sales`,`max_sales_for_type`,`id`) VALUES ('1','23','1','','2006-07-28 18:52:00','2006-07-28 18:52:00','0','48');
INSERT INTO `valid_vouchers` (`offer_public?`,`showdate_id`,`vouchertype_id`,`password`,`start_sales`,`end_sales`,`max_sales_for_type`,`id`) VALUES ('1','25','1','','2006-07-28 18:52:00','2006-07-28 18:52:00','0','49');
INSERT INTO `valid_vouchers` (`offer_public?`,`showdate_id`,`vouchertype_id`,`password`,`start_sales`,`end_sales`,`max_sales_for_type`,`id`) VALUES ('0','20','7','','2006-08-01 14:18:00','2006-08-01 14:18:00','0','50');
INSERT INTO `valid_vouchers` (`offer_public?`,`showdate_id`,`vouchertype_id`,`password`,`start_sales`,`end_sales`,`max_sales_for_type`,`id`) VALUES ('0','23','7','','2006-08-01 14:18:00','2006-08-01 14:18:00','0','51');
INSERT INTO `valid_vouchers` (`offer_public?`,`showdate_id`,`vouchertype_id`,`password`,`start_sales`,`end_sales`,`max_sales_for_type`,`id`) VALUES ('0','25','7','','2006-08-01 14:18:00','2006-08-01 14:18:00','0','52');
INSERT INTO `valid_vouchers` (`offer_public?`,`showdate_id`,`vouchertype_id`,`password`,`start_sales`,`end_sales`,`max_sales_for_type`,`id`) VALUES ('0','4','2','','2006-08-04 08:33:00','2006-08-04 08:33:00','0','53');
INSERT INTO `valid_vouchers` (`offer_public?`,`showdate_id`,`vouchertype_id`,`password`,`start_sales`,`end_sales`,`max_sales_for_type`,`id`) VALUES ('0','7','1','','2006-08-05 11:45:00','2007-08-05 11:45:00','0','54');
INSERT INTO `valid_vouchers` (`offer_public?`,`showdate_id`,`vouchertype_id`,`password`,`start_sales`,`end_sales`,`max_sales_for_type`,`id`) VALUES ('0','13','1','','2006-08-05 11:45:00','2007-08-05 11:45:00','0','55');
INSERT INTO `valid_vouchers` (`offer_public?`,`showdate_id`,`vouchertype_id`,`password`,`start_sales`,`end_sales`,`max_sales_for_type`,`id`) VALUES ('0','7','7','','2006-08-05 11:45:00','2007-08-05 11:45:00','0','56');
INSERT INTO `valid_vouchers` (`offer_public?`,`showdate_id`,`vouchertype_id`,`password`,`start_sales`,`end_sales`,`max_sales_for_type`,`id`) VALUES ('0','13','5','','2006-08-05 11:46:00','2007-08-05 11:46:00','0','57');
INSERT INTO `valid_vouchers` (`offer_public?`,`showdate_id`,`vouchertype_id`,`password`,`start_sales`,`end_sales`,`max_sales_for_type`,`id`) VALUES ('0','20','5','','2006-08-13 14:45:00','2006-08-13 14:45:00','0','58');
INSERT INTO `valid_vouchers` (`offer_public?`,`showdate_id`,`vouchertype_id`,`password`,`start_sales`,`end_sales`,`max_sales_for_type`,`id`) VALUES ('0','23','5','','2006-08-13 14:45:00','2006-08-13 14:45:00','0','59');
INSERT INTO `valid_vouchers` (`offer_public?`,`showdate_id`,`vouchertype_id`,`password`,`start_sales`,`end_sales`,`max_sales_for_type`,`id`) VALUES ('0','25','5','','2006-08-13 14:45:00','2006-08-13 14:45:00','0','60');
INSERT INTO `valid_vouchers` (`offer_public?`,`showdate_id`,`vouchertype_id`,`password`,`start_sales`,`end_sales`,`max_sales_for_type`,`id`) VALUES ('0','23','4','','2006-08-13 15:02:00','2006-08-13 15:02:00','0','61');


# Dump of table vouchers
# ------------------------------------------------------------

DROP TABLE IF EXISTS `vouchers`;

CREATE TABLE `vouchers` (
  `id` int(11) unsigned NOT NULL auto_increment,
  `vouchertype_id` int(10) unsigned NOT NULL default '0',
  `customer_id` int(10) unsigned NOT NULL default '0',
  `showdate_id` int(11) unsigned NOT NULL default '0',
  `expiration_date` datetime default NULL,
  `purchasemethod_id` int(10) unsigned NOT NULL default '0',
  `comments` varchar(255) default NULL,
  `created_on` datetime default NULL,
  `updated_on` datetime default NULL,
  PRIMARY KEY  (`id`)
) TYPE=MyISAM;

INSERT INTO `vouchers` (`id`,`vouchertype_id`,`customer_id`,`showdate_id`,`expiration_date`,`purchasemethod_id`,`comments`,`created_on`,`updated_on`) VALUES ('1','2','1','0',NULL,'9','','2006-07-21 17:28:20','2006-07-21 17:40:36');
INSERT INTO `vouchers` (`id`,`vouchertype_id`,`customer_id`,`showdate_id`,`expiration_date`,`purchasemethod_id`,`comments`,`created_on`,`updated_on`) VALUES ('2','4','1','0',NULL,'9','','2006-07-21 17:39:44','2006-07-21 17:41:23');
INSERT INTO `vouchers` (`id`,`vouchertype_id`,`customer_id`,`showdate_id`,`expiration_date`,`purchasemethod_id`,`comments`,`created_on`,`updated_on`) VALUES ('32','5','2','0',NULL,'1','','2006-08-19 16:01:48','2006-08-19 16:01:48');
INSERT INTO `vouchers` (`id`,`vouchertype_id`,`customer_id`,`showdate_id`,`expiration_date`,`purchasemethod_id`,`comments`,`created_on`,`updated_on`) VALUES ('31','5','2','0',NULL,'1','','2006-08-19 16:01:39','2006-08-19 16:01:39');
INSERT INTO `vouchers` (`id`,`vouchertype_id`,`customer_id`,`showdate_id`,`expiration_date`,`purchasemethod_id`,`comments`,`created_on`,`updated_on`) VALUES ('30','1','0','0',NULL,'1','','2006-08-19 15:15:43','2006-08-19 15:15:43');
INSERT INTO `vouchers` (`id`,`vouchertype_id`,`customer_id`,`showdate_id`,`expiration_date`,`purchasemethod_id`,`comments`,`created_on`,`updated_on`) VALUES ('20','6','2','0',NULL,'9','','2006-08-05 19:26:28','2006-08-05 19:26:28');
INSERT INTO `vouchers` (`id`,`vouchertype_id`,`customer_id`,`showdate_id`,`expiration_date`,`purchasemethod_id`,`comments`,`created_on`,`updated_on`) VALUES ('21','6','2','0',NULL,'9','','2006-08-05 19:26:28','2006-08-05 19:26:28');


# Dump of table vouchertypes
# ------------------------------------------------------------

DROP TABLE IF EXISTS `vouchertypes`;

CREATE TABLE `vouchertypes` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(255) default NULL,
  `price` float default '0',
  `created_on` datetime default NULL,
  `comments` text,
  `offer_public?` tinyint(1) NOT NULL default '0',
  PRIMARY KEY  (`id`)
) TYPE=InnoDB;

INSERT INTO `vouchertypes` (`id`,`name`,`price`,`created_on`,`comments`,`offer_public?`) VALUES ('1','Gen Adm - Adv Purch','22','2006-07-18 19:05:00','','0');
INSERT INTO `vouchertypes` (`id`,`name`,`price`,`created_on`,`comments`,`offer_public?`) VALUES ('2','General Admission - At the Door','22','2006-07-18 19:05:00','','0');
INSERT INTO `vouchertypes` (`id`,`name`,`price`,`created_on`,`comments`,`offer_public?`) VALUES ('3','Student/Senior - Advance Purchase','17','2006-07-18 19:06:00','','0');
INSERT INTO `vouchertypes` (`id`,`name`,`price`,`created_on`,`comments`,`offer_public?`) VALUES ('4','Student/Senior - At the Door','19','2006-07-18 19:06:00','','0');
INSERT INTO `vouchertypes` (`id`,`name`,`price`,`created_on`,`comments`,`offer_public?`) VALUES ('5','1/2 Price','10','2006-07-18 19:09:00','','0');
INSERT INTO `vouchertypes` (`id`,`name`,`price`,`created_on`,`comments`,`offer_public?`) VALUES ('6','Subscriber (Play)','0','2006-07-19 14:14:00','','0');
INSERT INTO `vouchertypes` (`id`,`name`,`price`,`created_on`,`comments`,`offer_public?`) VALUES ('7','Subscriber (Musical)','0','2006-07-19 14:14:00','','0');


