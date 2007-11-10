# Audience1st nightly and monthly cleanups
# run 'make nightly' every night and 'make monthly' every month via cron

MYSQL      = mysql
MYSQL_OPTS= -uaudience_admin '-p,rtto;u'
MYSQL_DB=    audience_vboproduction
MYSQLDUMP  = mysqldump

# clean out sessions older than this many seconds
SESSION_CLEANOUT = 86400

# home dir
HOME = /home/audience

# directory for storing backup files
BACKUPDIR = $(HOME)/backup

# directory where utility scripts live
BINDIR = $(HOME)/bin

all: nightly
nightly: clean_sessions kill_zombies backup
monthly: rotate_logs

clean_sessions:
        $(MYSQL) $(MYSQL_OPTS) -D$(MYSQL_DB) -e 'delete from sessions where now() - updated_at > $(SESSION_CLEA\
NOUT)'

backup:
        $(MYSQLDUMP) $(MYSQL_OPTS) $(MYSQL_DB) | gzip > $(BACKUPDIR)/$(shell date +\%F).gz

rotate_logs:
        $(BINDIR)/rotate_logs

kill_zombies:
	killall -9 ruby
