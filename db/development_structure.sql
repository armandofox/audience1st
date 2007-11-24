CREATE TABLE `config_params` (
  `id` int(11) NOT NULL auto_increment,
  `param_name` varchar(255) NOT NULL default '',
  `param_value` varchar(255) NOT NULL default '',
  `param_desc` varchar(255) NOT NULL default '',
  `updated_at` datetime default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `customers` (
  `id` int(16) NOT NULL auto_increment,
  `first_name` varchar(64) NOT NULL default '',
  `last_name` varchar(64) NOT NULL default '',
  `street` varchar(255) default NULL,
  `city` varchar(255) default NULL,
  `state` varchar(8) NOT NULL default 'CA',
  `zip` varchar(255) default NULL,
  `day_phone` varchar(255) default NULL,
  `eve_phone` varchar(255) default NULL,
  `phplist_user_id` int(11) NOT NULL default '0',
  `login` varchar(255) default NULL,
  `hashed_password` varchar(255) NOT NULL default '',
  `salt` varchar(12) NOT NULL default '',
  `role` int(4) NOT NULL default '0',
  `created_on` datetime NOT NULL default '0000-00-00 00:00:00',
  `updated_on` datetime NOT NULL default '0000-00-00 00:00:00',
  `comments` longtext NOT NULL,
  `oldid` int(15) NOT NULL default '0',
  `blacklist` tinyint(1) default '0',
  `validation_level` int(11) default '0',
  `last_login` datetime NOT NULL default '2007-04-06 15:40:20',
  `e_blacklist` tinyint(1) default '0',
  `referred_by_id` int(11) default NULL,
  `referred_by_other` varchar(255) default NULL,
  `formal_relationship` enum('None','Board Member','Former Board Member','Board President','Former Board President','Honorary Board Member','Emeritus Board Member') default 'None',
  `member_type` enum('None','Regular','Sustaining','Life','Honorary Life') default 'None',
  `company` varchar(255) default NULL,
  `title` varchar(255) default NULL,
  `company_address_line_1` varchar(255) default NULL,
  `company_address_line_2` varchar(255) default NULL,
  `company_city` varchar(255) default NULL,
  `company_state` varchar(255) default NULL,
  `company_zip` varchar(255) default NULL,
  `work_phone` varchar(255) default NULL,
  `cell_phone` varchar(255) default NULL,
  `work_fax` varchar(255) default NULL,
  `company_url` varchar(255) default NULL,
  `best_way_to_contact` varchar(255) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2146723669 DEFAULT CHARSET=latin1;

CREATE TABLE `donation_funds` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(40) NOT NULL default '',
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=4 DEFAULT CHARSET=latin1;

CREATE TABLE `donation_types` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(40) NOT NULL default '',
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=5 DEFAULT CHARSET=latin1;

CREATE TABLE `donations` (
  `id` int(11) NOT NULL auto_increment,
  `date` date NOT NULL default '0000-00-00',
  `amount` float NOT NULL default '0',
  `donation_type_id` int(11) NOT NULL default '0',
  `donation_fund_id` int(11) NOT NULL default '0',
  `comment` varchar(255) default NULL,
  `customer_id` int(11) NOT NULL default '0',
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  `letter_sent` datetime default NULL,
  `processed_by` int(11) NOT NULL default '2146722771',
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=753 DEFAULT CHARSET=latin1;

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
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `purchasemethods` (
  `id` tinyint(11) unsigned NOT NULL auto_increment,
  `description` varchar(255) NOT NULL default '',
  `offer_public` tinyint(1) NOT NULL default '0',
  `shortdesc` varchar(10) NOT NULL default '?purch?',
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=16 DEFAULT CHARSET=latin1;

CREATE TABLE `schema_info` (
  `version` int(11) default NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `sessions` (
  `id` int(11) NOT NULL auto_increment,
  `session_id` varchar(255) default NULL,
  `data` text,
  `updated_at` datetime default NULL,
  PRIMARY KEY  (`id`),
  KEY `sessions_session_id_index` (`session_id`)
) ENGINE=InnoDB AUTO_INCREMENT=9303 DEFAULT CHARSET=latin1;

CREATE TABLE `showdates` (
  `thedate` datetime default NULL,
  `end_advance_sales` datetime default NULL,
  `max_sales` int(11) unsigned NOT NULL default '0',
  `show_id` int(11) unsigned NOT NULL default '0',
  `id` int(5) unsigned NOT NULL auto_increment,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=115 DEFAULT CHARSET=latin1;

CREATE TABLE `shows` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(255) default NULL,
  `opening_date` date default NULL,
  `closing_date` date default NULL,
  `house_capacity` smallint(5) unsigned NOT NULL default '0',
  `created_on` datetime NOT NULL default '0000-00-00 00:00:00',
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=latin1;

CREATE TABLE `txn_types` (
  `id` int(11) unsigned NOT NULL default '20',
  `desc` varchar(100) default 'Other',
  `shortdesc` varchar(10) NOT NULL default '???',
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `txns` (
  `id` int(11) NOT NULL auto_increment,
  `customer_id` int(11) NOT NULL default '1',
  `entered_by_id` int(11) NOT NULL default '1',
  `txn_date` datetime default NULL,
  `txn_type_id` int(10) unsigned NOT NULL default '0',
  `show_id` int(11) unsigned default NULL,
  `showdate_id` int(11) unsigned default NULL,
  `purchasemethod_id` int(11) unsigned default NULL,
  `voucher_id` int(11) NOT NULL default '0',
  `dollar_amount` float NOT NULL default '0',
  `comments` varchar(255) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=11439 DEFAULT CHARSET=latin1;

CREATE TABLE `valid_vouchers` (
  `showdate_id` int(11) unsigned default NULL,
  `vouchertype_id` int(11) unsigned default NULL,
  `password` varchar(255) default NULL,
  `start_sales` datetime default NULL,
  `end_sales` datetime default NULL,
  `max_sales_for_type` smallint(6) unsigned NOT NULL default '0',
  `id` smallint(6) unsigned NOT NULL auto_increment,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=922 DEFAULT CHARSET=latin1;

CREATE TABLE `visits` (
  `id` int(11) NOT NULL auto_increment,
  `updated_at` datetime default NULL,
  `visited_by_id` int(11) NOT NULL default '0',
  `contact_method` enum('Phone','Email','Letter/Fax','In person') default NULL,
  `location` varchar(255) default NULL,
  `purpose` enum('Preliminary','Followup','Presentation','Further Discussion','Close','Recognition','Other') default NULL,
  `result` enum('No interest','Further cultivation','Arrange for Gift','Gift Received') default NULL,
  `additional_notes` varchar(255) default NULL,
  `followup_date` date default NULL,
  `followup_action` varchar(255) default NULL,
  `next_ask_target` int(11) NOT NULL default '0',
  `followup_assigned_to_id` int(11) NOT NULL default '0',
  `customer_id` int(11) default NULL,
  `thedate` date NOT NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=latin1;

CREATE TABLE `vouchers` (
  `id` int(11) unsigned NOT NULL auto_increment,
  `vouchertype_id` int(10) unsigned NOT NULL default '0',
  `customer_id` int(12) NOT NULL default '0',
  `showdate_id` int(11) unsigned NOT NULL default '0',
  `purchasemethod_id` int(10) unsigned NOT NULL default '0',
  `comments` varchar(255) default NULL,
  `created_on` datetime default NULL,
  `updated_on` datetime default NULL,
  `changeable` tinyint(1) default '1',
  `fulfillment_needed` tinyint(1) default '0',
  `external_key` int(11) default '0',
  `no_show` tinyint(1) NOT NULL default '0',
  `promo_code` varchar(255) default NULL,
  `processed_by` int(11) NOT NULL default '2146722771',
  `expiration_date` datetime NOT NULL default '2008-12-31 00:00:00',
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=9837 DEFAULT CHARSET=latin1;

CREATE TABLE `vouchertypes` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(255) default NULL,
  `price` float default '0',
  `created_on` datetime default NULL,
  `comments` text,
  `offer_public` int(11) NOT NULL default '0',
  `is_bundle` tinyint(1) default '0',
  `is_subscription` tinyint(1) NOT NULL default '0',
  `included_vouchers` text,
  `promo_code` varchar(20) NOT NULL default '',
  `walkup_sale_allowed` tinyint(1) default '1',
  `valid_date` datetime NOT NULL default '2007-01-01 00:00:00',
  `expiration_date` datetime NOT NULL default '2008-01-01 00:00:00',
  `fulfillment_needed` tinyint(1) default '0',
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=61 DEFAULT CHARSET=latin1;

INSERT INTO schema_info (version) VALUES (21)