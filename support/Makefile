# Audience1st nightly and monthly cleanups
# run 'make nightly' every night and 'make monthly' every month via cron

# must set VENUE properly!

NAME	   = audienc
HOME	   = /home/$(NAME)
SVNROOT	   = $(HOME)/svn
APPROOT    = $(HOME)/rails/$(VENUE)/current
BACKUPDIR = $(HOME)/backup/$(VENUE)
TODAY	   = $(shell date +\%d)

#  IMPORTANT:  Binary path names below refer to the binary's path ON THE
#   DEPLOYMENT SYSTEM, not on your (development) system.  Many of these
#   commands are run from a cron job (which runs in an uncertain
#   environment) so it's best to fully qualify the path name (you can't
#   rely on /usr/bin/env in these cases).
GZIP	   = /bin/gzip
RUBY	   = /usr/local/bin/ruby
PERL	   = /usr/local/bin/perl
MYSQL      = /usr/bin/mysql
MYSQLDUMP  = /usr/bin/mysqldump
S3CMD	   = S3CONF=$(HOME)/.s3conf /home/audienc/s3sync/s3cmd.rb
A1_DB   = $(shell perl -ne 'print $$1 if /database: +(.*)$$/' $(APPROOT)/config/database.yml)
A1_DBPASS = $(shell perl -ne 'print $$1 if /password: +(.*)$$/' $(APPROOT)/config/database.yml)
A1_DBUSER = $(shell perl -ne 'print $$1 if /username: +(.*)$$/' $(APPROOT)/config/database.yml)
A1_MYSQL_OPTS = '-u$(A1_DBUSER)' '-p$(A1_DBPASS)'

WP_CONFIG  = $(HOME)/public_html/$(VENUE)web/wp-config.php
#WP_CONFIG = /tmp/wp.php
WP_DB      = $(shell perl -ne 'print $$1 if /DB_NAME.,\s*'"'([^']+"')/' $(WP_CONFIG))
WP_DBPASS  =  $(shell perl -ne 'print $$1 if /DB_PASSWORD.,\s*'"'([^']+"')/' $(WP_CONFIG))
WP_DBUSER  =  $(shell perl -ne 'print $$1 if /DB_USER.,\s*'"'([^']+"')/' $(WP_CONFIG))
WP_MYSQL_OPTS = '-u$(WP_DBUSER)' '-p$(WP_DBPASS)'

STATIC_TABLES = purchasemethods txn_types options 

# clean out sessions older than this many seconds
SESSION_CLEANOUT = 86400

# BUG: should deduce this as being same directory as Makefile
BINDIR     = $(APPROOT)/support

# syntax for "be quiet" in whatever shell (usually bash or sh)
# suppreses Cron daemon from sending you email, but also means you won't
# see error messages.  if you comment this out, you'll get those emails.
# QUIET      =  >/dev/null 2>&1

.PHONY: all nightly monthly clean_sessions backup_db backup_wp backup_svn run_sql dump_static_data rotate_logs kill_zombies receive_goldstar receive_goldstar_test

all: nightly
nightly: clean_sessions notify_pending_followups kill_zombies backup_db
monthly: rotate_logs

dev:
	-mv ../config/database.yml.dev ../config/database.yml
	mkdir ../log
	touch ../log/development.log

backup_svn: 
	@tar -zcf $(BACKUPDIR)/svn-$(TODAY).tgz $(SVNROOT)
	@$(S3CMD) put a1_svn:svn-$(TODAY).tgz $(BACKUPDIR)/svn-$(TODAY).tgz

clean_sessions:
	@$(MYSQL) $(A1_MYSQL_OPTS) -D$(A1_DB) -e 'delete from sessions where now() - updated_at > $(SESSION_CLEANOUT)' $(QUIET)

backup_db:
	@$(MYSQLDUMP) $(A1_MYSQL_OPTS) $(A1_DB) | $(GZIP) > $(BACKUPDIR)/db-$(TODAY).gz
	@$(S3CMD) put a1_$(VENUE):db-$(TODAY).gz  $(BACKUPDIR)/db-$(TODAY).gz

backup_wp:
	@$(MYSQLDUMP) $(WP_MYSQL_OPTS) $(WP_DB) | $(GZIP) > $(BACKUPDIR)/wp-$(TODAY).gz
	@$(S3CMD) put a1_$(VENUE):wp-$(TODAY).gz  $(BACKUPDIR)/wp-$(TODAY).gz

restore_db:
	$(MYSQL) $(A1_MYSQL_OPTS) $(A1_DB)

restore_wp:
	$(MYSQL) $(WP_MYSQL_OPTS) $(WP_DB)

dump_static_data:
	@$(MYSQLDUMP) $(MYSQL_OPTS) $(A1_DB) $(STATIC_TABLES) > static.sql

rotate_logs:
	@$(PERL) $(BINDIR)/rotate_logs $(BACKUPDIR) $(QUIET)

kill_zombies:
	@killall -u audienc -s SIGUSR1 dispatch.fcgi $(QUIET)

receive_goldstar:
	@RAILS_ENV=production $(RUBY) $(APPROOT)/script/runner 'EmailGoldstar.receive(STDIN.read)' $(QUIET)

receive_goldstar_test:
	@RAILS_ENV=development $(RUBY) $(APPROOT)/script/runner 'EmailGoldstar.receive(STDIN.read)' $(QUIET)

notify_pending_followups:
	@RAILS_ENV=production $(RUBY) $(APPROOT)/script/runner 'Visit.notify_pending_followups' $(QUIET)
