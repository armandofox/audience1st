class Setup < Test::Unit::TestCase

  def self.validate_interactive
    str = 1000 + rand(9000)
    puts "To really proceed, enter this number: #{str}"
    return (STDIN.readline.chomp.to_i == str)
  end

  def self.setup
    abort "Not interactive" unless validate_interactive
    # default customers to be created: first,last,role,login,pass
    STDERR.print "Creating default Customer table entries..."
    custs = [["Administrator", "Administrator", 100, "admin", "admin"],
             [" WALKUP", " CUSTOMER", -1, "", ""]]
    custs.each do |c|
      STDERR.print "#{c.first_name} "
      Customer.create!(:first_name => c[0], :last_name => c[1],
                       :role => c[2], :login => c[3], :password => c[4])
    end
    # default donation fund
    DonationFund.create!(:name => "General Fund")

    STDERR.puts "\nDone"
  end

end

