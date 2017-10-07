namespace :import do
  task :customers => :environment do
    require 'csv'
    count = 1
    begin
      ActiveRecord::Base.transaction do
        CSV.open(ENV['FILE'], 'r', ?,, ?\r) do |field|
          field.map!(&:to_s)
          c = Customer.new(
            :first_name => field[0], :last_name => field[1],
            :street => field[2], :city => field[3], :state => field[4],
            :zip => field[5], :email => field[6], :day_phone => field[7])
          c.created_by_admin = true
          c.force_valid = true
          c.save!
          unless field[9].blank?  # label
            field[9].strip.split(/\s*,\s*/).each do |label|
              l = Label.find_by_name(label) || Label.create!(:name => label)
              puts "Adding label #{l.name} to customer #{c.first_name} #{c.last_name}"
              c.labels << l
            end
          end
          count += 1
        end
      end
    rescue StandardError => e
      puts "Error at line #{count}: #{e.message}"
    end
  end
end
