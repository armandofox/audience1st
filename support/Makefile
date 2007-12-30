# Audience1st nightly and monthly cleanups
# run 'make nightly' every night and 'make monthly' every month via cron

# must set VENUE properly!

NAME	   = audienc
HOME	   = /home/$(NAME)
APPROOT    = $(HOME)/rails/$(VENUE)/current
APPROOT_STAGE = $(HOME)/rails/$(VENUE)/stage
BACKUPDIR = $(HOME)/backup/$(VENUE)

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
MYSQL_OPTS = -u$(NAME) '-ps;ystrms'
MYSQL_DB   =  $(NAME)_vboproduction

# clean out sessions older than this many seconds
SESSION_CLEANOUT = 86400

# BUG: should deduce this as being same directory as Makefile
BINDIR     = $(APPROOT)/support

# syntax for "be quiet" in whatever shell (usually bash or sh)
QUIET      =  >/dev/null 2>&1

.PHONY: all nightly monthly clean_sessions backup rotate_logs kill_zombies receive_goldstar receive_goldstar_test

all: nightly
nightly: clean_sessions notify_pending_followups kill_zombies backup
monthly: rotate_logs

clean_sessions:
	@$(MYSQL) $(MYSQL_OPTS) -D$(MYSQL_DB) -e 'delete from sessions where now() - updated_at > $(SESSION_CLEANOUT)' $(QUIET)

backup:
	@$(MYSQLDUMP) $(MYSQL_OPTS) $(MYSQL_DB) | $(GZIP) > $(BACKUPDIR)/$(shell date +\%F).gz

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
