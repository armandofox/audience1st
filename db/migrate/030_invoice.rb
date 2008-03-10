class Invoice < ActiveRecord::Migration
  def self.up
    id = 10
    options =
      [["monthly_fee", 0.0,],
       ["cc_fee_markup", 0.0],
       ["per_ticket_fee", 1.0],
       ["per_ticket_commission", 0.0],
       ["customer_service_per_hour", 25.00]]
    options.each do |o|
      ActiveRecord::Base.connection.insert <<EOQ1
       INSERT INTO options (id,grp,name,typ,value)
        VALUES (#{id},"Config", "#{o[0]}", "float", "#{o[1]}")
EOQ1
      id += 1
    end
  end

  def self.down
  end
end
