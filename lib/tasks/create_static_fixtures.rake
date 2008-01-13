require 'yaml/encoding'
class String
  alias :old_to_yaml :to_yaml
  def to_yaml(opts = {}) ; YAML.escape(self).old_to_yaml(opts) ; end
end

desc 'Create fixture files from static data tables for testing'
task :create_static_fixtures => :environment do |env|
  ActiveRecord::Base.establish_connection
  tables = %w(options purchasemethods donation_types donation_funds txn_types)
  tables.each do |t|
    outfile = "#{RAILS_ROOT}/test/fixtures/#{t}.yml"
    data = ActiveRecord::Base.connection.select_all("SELECT * FROM #{t}")
    i = "000"
    File.open(outfile,'w') do |f|
      data.each do |row|
        f.write Hash["option_#{i.succ!}" => row].to_yaml
      end
    end
  end
end
