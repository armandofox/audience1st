# Audience1st nightly and monthly cleanups
# run 'make nightly' every night and 'make monthly' every month via cron

# must set VENUE properly!

NAME	   = audienc
HOME	   = /home/$(NAME)
APPROOT    = $(HOME)/rails/$(VENUE)/current
APPROOT_STAGE = $(HOME)/rails/$(VENUE)/stage
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
S3CONF	   = /home/audienc/.s3conf
S3CMD	   = S3CONF=$(S3CONF) /home/audienc/s3sync/s3cmd.rb
MYSQL_DB   = $(shell perl -ne 'print $$1 if /database: +(.*)$$/' $(APPROOT)/config/database.yml)
MYSQL_PASS = $(shell perl -ne 'print $$1 if /password: +(.*)$$/' $(APPROOT)/config/database.yml)
MYSQL_USER = $(shell perl -ne 'print $$1 if /username: +(.*)$$/' $(APPROOT)/config/database.yml)
MYSQL_OPTS = '-u$(MYSQL_USER)' '-p$(MYSQL_PASS)'

STATIC_TABLES = purchasemethods txn_types options 

# clean out sessions older than this many seconds
SESSION_CLEANOUT = 86400

# BUG: should deduce this as being same directory as Makefile
BINDIR     = $(APPROOT)/support

# syntax for "be quiet" in whatever shell (usually bash or sh)
# suppreses Cron daemon from sending you email, but also means you won't
# see error messages.  if you comment this out, you'll get those emails.
# QUIET      =  >/dev/null 2>&1

.PHONY: all nightly monthly clean_sessions backup run_sql dump_static_data rotate_logs kill_zombies receive_goldstar receive_goldstar_test

all: nightly
nightly: clean_sessions notify_pending_followups kill_zombies backup
monthly: rotate_logs

clean_sessions:
	@$(MYSQL) $(MYSQL_OPTS) -D$(MYSQL_DB) -e 'delete from sessions where now() - updated_at > $(SESSION_CLEANOUT)' $(QUIET)

backup:
	@$(MYSQLDUMP) $(MYSQL_OPTS) $(MYSQL_DB) | $(GZIP) > $(BACKUPDIR)/$(TODAY).gz
	@$(S3CMD) put a1_$(VENUE):db-$(TODAY).gz  $(BACKUPDIR)/$(TODAY).gz

dump_static_data:
	@$(MYSQLDUMP) $(MYSQL_OPTS) $(MYSQL_DB) $(STATIC_TABLES) > static.sql

rotate_logs:
	@$(PERL) $(BINDIR)/rotate_logs $(BACKUPDIR) $(QUIET)

kill_zombies:
	@killall -usr1 dispatch.fcgi $(QUIET)

receive_goldstar:
	@RAILS_ENV=production $(RUBY) $(APPROOT)/script/runner 'EmailGoldstar.receive(STDIN.read)' $(QUIET)

receive_goldstar_test:
	@RAILS_ENV=development $(RUBY) $(APPROOT)/script/runner 'EmailGoldstar.receive(STDIN.read)' $(QUIET)

notify_pending_followups:
	@RAILS_ENV=production $(RUBY) $(APPROOT)/script/runner 'Visit.notify_pending_followups' $(QUIET)
