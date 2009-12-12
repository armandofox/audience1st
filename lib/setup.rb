# To setup a new venue:
# - setup its production DB, regular username & pass, RO username & pass
# - create and svn add database.yml.<venue> and public/.htaccess.<venue>
# - run 'cap deploy:setup'
# - mysql '-uaudienc' '-ps;ystrms' --database=audienc_vbodevelopment < dumpfile
# - copy a schema.rb from somewhere
# - setenv SETUP=1 and then rake db:schema:load
# - copy entire table contents from source DB: Options, purchasemethods, schema_info, schema_migrations
# - create an Admin user with role 100
# - set a password(?) using basicauth/.htaccess for initial config
# - create symlink to public_html dir

require 'application.rb'

class Setup < Test::Unit::TestCase

  def self.validate_interactive
    str = 1000 + rand(9000)
    abort "No venue name" if ENV[:venue].blank?
    puts "Setup for venue '#{ENV[:venue]}'"
    puts "To really proceed, enter this number: #{str}"
    return (STDIN.readline.chomp.to_i == str)
  end

  def self.get_value(prompt=">")
    puts prompt
    return STDIN.readline.chomp
  end
  
  def self.setup
    abort "Not interactive" unless validate_interactive
    venue_id = self.get_value("Venue ID").to_i
    # default customers to be created: first,last,role,login,pass
    admin = Customer.create!(:first_name => "Administrator",
                             :last_name => "",
                             :login => "admin",
                             :password => "admin")
    admin.update_attribute(:role, 100) # God


  end

end

