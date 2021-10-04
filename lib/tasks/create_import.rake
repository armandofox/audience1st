namespace :create_import do

  desc <<eoDESC
Using information from TENANT (default 'a1-staging'), create Goldstar-format will-call 
list OUTFILE (default 'goldstar.json') based on INFILE (default import.yml), whose format is:

  showdate: Thu, 2 Oct 2021, 8pm
  orders:
    "Goldstar-General":
      - Bob Albrecht, 2
      - Cynthia Newcustomer, 1
    "Goldstar-Comp":
      - Donna Existing, 1

Showdate can be anything parsable by Time.parse.  Performance, voucher types, and redemptions
are all assumed to exist and be properly set up.  Customers may exist or not.
eoDESC
  task :goldstar => :environment do
    Apartment::Tenant.switch!(ENV['TENANT'] || 'a1-staging')
    outfile = ENV['OUTFILE'] || 'goldstar.json'
    y = YAML.load_file(ENV['INFILE'] || 'import.yml')
    erb = IO.read(File.join(Rails.root, 'lib', 'tasks', 'goldstar.json.erb'))
    json = ERB.new(erb).result(binding)
    File.open(outfile, "w") { |f|  f.puts json }
  end
end
