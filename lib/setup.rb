# the 'make setup' task should
# - prep directory structure (shared/log, shared/system)
# - copy a schema.rb from somewhere
# - setenv SETUP=1 and then rake db:schema:load
# - run script/runner Setup.setup
# - mysql dump_static from source dir and then mysql import into dest dir
# - set a password(?) using basicauth/.htaccess for initial config

require 'application.rb'

class Setup < Test::Unit::TestCase

  def self.validate_interactive
    str = 1000 + rand(9000)
    puts "To really proceed, enter this number: #{str}"
    return (STDIN.readline.chomp.to_i == str)
  end

  def self.setup
    abort "Not interactive" unless validate_interactive
    # default customers to be created: first,last,role,login,pass
    admin = Customer.create!(:first_name => "Administrator",
                             :last_name => "",
                             :login => "admin",
                             :password => "admin")
    admin.update_attribute(:role, 100) # God
    walkup = Customer.create!(:first_name => "WALKUP",
                              :last_name => "CUSTOMER",
                              :login => "----------",
                              :password => "-----------")
    walkup.update_attribute(:role, -1)
    walkup.update_attribute(:login, "")
    walkup.update_attribute(:password, nil)
    # default donation fund
    DonationFund.create!(:name => "General Fund")
  end

end

