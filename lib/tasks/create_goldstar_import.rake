namespace :create_import do
  task :goldstar => :environment do
    desc "Create FILE.json (default 'goldstar.json') containing 2 fake Goldstar orders for SHOWDATE_ID.  The showdate must be associated with a valid vouchertype whose name starts with 'Goldstar'."
    showdate_id = ENV['SHOWDATE_ID'] or abort "Must specify valid SHOWDATE_ID"
    file = ENV['FILE'] || 'goldstar.json'
    Apartment::Tenant.switch! 'a1-staging'
    showdate = Showdate.find showdate_id
    date = showdate.thedate
    # pick a Goldstar vouchertype that's valid for this show date
    vouchertype = showdate.valid_vouchers.map(&:vouchertype).detect { |v| v.name =~ /^Goldstar/ } or
                  abort "No vouchertypes beginning with 'Goldstar' found for showdate ID #{showdate_id}"
    erb = IO.read(File.join(Rails.root, 'lib', 'tasks', 'goldstar.json.erb'))
    json = ERB.new(erb).result(binding)
    File.open(file, "w") { |f|  f.puts json }
  end
end
