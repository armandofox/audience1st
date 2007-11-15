# Audience1st nightly and monthly cleanups
# run 'make nightly' every night and 'make monthly' every month via cron

NAME	   = audienc
HOME	   = /home/$(NAME)
MYSQL      = /usr/bin/mysql
MYSQLDUMP  = /usr/bin/mysqldump
MYSQL_OPTS = -u$(NAME) '-ps;ystrms'
MYSQL_DB   =  $(NAME)_vboproduction

# clean out sessions older than this many seconds
SESSION_CLEANOUT = 86400

# directory for storing backup files
BACKUPDIR = $(HOME)/backup

# directory where utility scripts live
# BUG: should deduce this as being same directory as Makefile
BINDIR = $(HOME)/rails/vbo/releases/current/support

all: nightly
nightly: clean_sessions kill_zombies backup
monthly: rotate_logs

clean_sessions:
        $(MYSQL) $(MYSQL_OPTS) -D$(MYSQL_DB) -e 'delete from sessions where now() - updated_at > $(SESSION_CLEANOUT)'

backup:
        $(MYSQLDUMP) $(MYSQL_OPTS) $(MYSQL_DB) | gzip > $(BACKUPDIR)/$(shell date +\%F).gz

rotate_logs:
        $(BINDIR)/rotate_logs

kill_zombies:
	killall -usr1 dispatch.fcgi


