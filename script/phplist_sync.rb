# require 'rubygems'
# require_gem 'activerecord'

# db_config = YAML::load(File.open(File.dirname(__FILE__) + "/../config/database.yml"))
# ActiveRecord::Base.establish_connection(db_config['production'])
# ActiveRecord::Base.establish_connection(db_config['phplist'])
# require File.dirname(__FILE__) + '/../app/models/customer.rb'
# require File.dirname(__FILE__) + '/../app/models/phplist_user.rb'

require "../config/environment.rb"

cond = "login IS NOT NULL AND login != ''"
printf("Processing %d\n", Customer.count(:all,:conditions => cond))
fk_update = 0
email_fix = 0
creat = 0
creat_fail = 0
Customer.find(:all, :conditions => cond).each do |c|
  if (c.phplist_user_id > 0) &&
      (p = PhplistUser.find_by_id(c.phplist_user_id))
    if p.email.downcase != c.login.downcase
      begin
        c.update_attribute(:login, p.email)
      rescue Exception => e
        puts "Update email failed for PHP user #{p.id} (CID #{c.id}): #{e.message}\n"
      end
      #printf("%-9d / %5d  %-20.20s => %20.20s\n", c.id, p.id,
      #c.login, p.email)
      email_fix += 1
    end
    if p.foreignkey.to_i != c.id
      p.update_attribute(:foreignkey, c.id)
      #printf("%-9d / %5d  <= %-9d\n", c.id, p.id, c.id)
      fk_update += 1
    end
  else                      # no PHPlist entry
    if c.login.valid_email_address?
      p,msg = PhplistUser.find_by_email_or_create(c)
      #p=nil; printf("Create new for %-9d\n", c.id)
      if p
        c.update_attribute(:phplist_user_id, p) if p
        #printf("%-9d * %5d\n", c.id, p.id)
        creat += 1
      else
        printf("%-9d: Couldn't create for %s\n", c.id, c.login)
        creat_fail += 1
      end
    else
      printf("%-9d: nulling invalid email '%s'\n", c.id, c.login)
      c.update_attribute(:login, nil)
    end
  end
end
printf("%5d foreign keys updated\n%5d emails fixed\n%5d PHPlist records create\n%5d PHPlist records could not be created\n", fk_update, email_fix, creat, creat_fail)

