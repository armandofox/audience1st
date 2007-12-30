
# In each option group, we give the name of the option, its default value,
# its type (or an array to be used as a select dropdown), a short description
# and a long description.

DEFAULT_OPTS = {

  "Ticket Sales" =>

  [[:sold_out_threshold, 95, "Sold out threshold",
    "Performance is listed as 'sold out' when this percentage of the house is sold."],
   [:nearly_sold_out_threshold, 85, "Nearly-sold-out threshold",
    "Performance is listed as 'nearly sold out' when this percentage of the house is sold."],
   [:season_start_month, 1, "What month the subscription season starts",
    "This is used to determine what ticket vouchers to show in customers' accounts and what the default dates for reporting are."],
   [:season_start_day, 1, "What day of the month the subscription season starts",
    "This is used to determine what ticket vouchers to show in customers' accounts and what the default dates for reporting are."],
  ],

  "Contact Information" =>

  [[:venue, "Altarena Playhouse", "Venue name",
    "Venue name as it will appear in confirmation emails, banners, etc."],
   [:venue_telephone, "510-523-1553", "Venue telephone number",
    "General information phone number for the venue"],
   [:boxoffice_telephone, "510-523-1553", 
    "Box office telephone number", "Box office telephone number"],
   [:donation_ack_from, "John Doe, Donations Chair",
    "Who acknowledges donations",
    "Auto-generated confirmation emails for online donations appear to be signed by this person."],
   [:help_email, "help@altarena.org", "Where patrons can get help",
    "Email address where patrons can get help; shown in confirmation emails for online orders"],
   [:privacy_policy_url, "http://", "Privacy policy URL",
    "URL of page describing the Privacy Policy regarding Venue's collection and use of patron information"],
   [:subscription_info, "http://", "Subscription/season info URL",
    "URL of page describing subscriber benefits and/or upcoming season"],
  ],

  "Email Notifications" =>

  [[:boxoffice_daemon_notify, "goldstar-reports@altarena.org", "Where to send automated boxoffice reports",
    "Whenever the box office does automatic background processing, such as when a third-party ticket list is received and parsed, an email report will be sent to this address.",
   ]]
}   


class Setup < Test::Unit::TestCase

  def self.validate_interactive
    str = 1000 + rand(9000)
    puts "To really proceed, enter this number: #{str}"
    return (STDIN.readline.chomp.to_i == str)
  end

  def self.setup_options
    STDERR.puts ""
    DEFAULT_OPTS.each_pair do |group,vars|
      vars.each do |s|
        name,val,shortdesc,longdesc = s
        n = name.to_s
        if (o = Option.find_by_name(n))
          o.update_attributes!(:group => group, :value => val,
                               :shortdesc => shortdesc,
                               :description => longdesc)
          op = "Update"
        else
          Option.create!(:group => group, :name => n, :value => val,
                         :shortdesc => shortdesc,
                         :description => longdesc)
          op = "Create"
        end
        STDERR.puts "  #{op} #{group}:#{name} => \"#{val}\" [#{typ.to_s}]"
      end
    end
  end

  def self.setup_customers
    # default customers to be created: first,last,role,login,pass
    custs = [["Administrator", "Administrator", 100, "admin", "admin"],
             [" WALKUP", " CUSTOMER", -1, "", ""]]
    custs.each do |c|
      STDERR.print "#{c.first_name} "
      Customer.create!(:first_name => c[0], :last_name => c[1],
                       :role => c[2], :login => c[3], :password => c[4])
    end
  end

  def self.setup_donation_funds
    # default donation fund
    DonationFund.create!(:name => "General Fund")
  end

  def self.setup_txn_types
    #Fixtures.create_fixtures("#{RAILS_ROOT}/lib/setup/", "txn_types")
  end
  
  def self.setup_purchasemethods
  end

  def self.setup
    abort "Not interactive" unless validate_interactive
    %w[options customers donation_funds txn_types purchasemethods].each do |s|
      STDERR.print "\nSetting up #{s}..."
      self.send("setup_#{s}".to_sym)
    end
    STDERR.puts "\nDone"
  end

end

