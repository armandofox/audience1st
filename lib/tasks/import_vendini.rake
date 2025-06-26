require 'apartment/migrator'

namespace :a1client do
  desc "Import Vendini-format CSV customer data to TENANT from FILE"
  task :import_customers => :environment do
    raise "TENANT is required" unless ENV['TENANT']
    raise "FILE is required and must be checked into version control" unless ENV['FILE']
    Apartment::Tenant.switch! ENV['TENANT']
    begin
      Customer.transaction do
        sold_on = Time.current
        cust_count = order_count = 0
        ac = {
          2017 => AccountCode.create!(:name => '2017 Ticket Sales', :code => '7001'),
          2018 => AccountCode.create!(:name => '2018 Ticket Sales', :code => '8001'),
          2019 => AccountCode.create!(:name => '2019 Ticket Sales', :code => '9001')
        }
        params = {:category => 'nonticket', :price => 1, :offer_public => Vouchertype::BOXOFFICE, :walkup_sale_allowed =>  false, :subscription => false, :fulfillment_needed => false}
        vt = {
          2017 => Vouchertype.create!(params.merge({:name => '2017 Ticket Purchases', :season => 2017, :account_code => ac[2017]})),
          2018 => Vouchertype.create!(params.merge({:name => '2018 Ticket Purchases', :season => 2018, :account_code => ac[2018]})),
          2019 => Vouchertype.create!(params.merge({:name => '2019 Ticket Purchases', :season => 2019, :account_code => ac[2019]}))
        }
        CSV.foreach(ENV['FILE'], :headers => true) do |row|
          hrow = row.to_h
          params = {
            :first_name => hrow['First Name'],
            :last_name  => hrow['Last Name'],
            :street => (hrow['Address2'].blank? ? hrow['Address'] : "#{hrow['Address']} / #{hrow['Address2']}"),
            :city => hrow['City'],
            :state => hrow['State'],
            :zip => hrow['Zip'],
            :day_phone => hrow['Phone'],
            :email => hrow['Email'],
            :blacklist => !(hrow['Do Not Mail'].blank?),
            :e_blacklist => !(hrow['Do Not Email'].blank?),
            :comments => hrow['Patron ID']
          }
          cust = Customer.new(params)
          cust.zip = '?????' unless cust.zip.to_s.length.between?(5,10)
          cust.state = 'CA' if cust.state.blank?
          cust.created_by_admin = true
          if !cust.valid?
            if !cust.errors['email'].blank?
              cust.email = nil
            else
              raise cust.errors.full_messages.join(';')
            end
          end
          cust.save!
          cust_count += 1
          sales = {}
          [2017,2018,2019].each { |k| sales[k] = hrow["#{k} $ Sales"].to_s.gsub(/\$/,'').to_f }
          unless sales.values.all?(&:zero?)
            order = Order.create!(:customer => cust, :processed_by => cust, :purchaser => cust,
              :purchasemethod => Purchasemethod.get_type_by_name('box_cash'))
            [2017,2018,2019].each do |yr|
              next if sales[yr].zero?
              r = RetailItem.new(:amount => sales[yr], :comments => "#{yr} ticket sales", :account_code => ac[yr], :vouchertype => vt[yr])
              raise r.errors.full_messages.join(';') unless r.valid?
              order.add_retail_item(r)
            end
            unless order.ready_for_purchase?
              raise order.errors.full_messages.join(';')
            end
            order.finalize!
            order.sold_on = sold_on
            order.save!
            order_count += 1
          end
        end
        puts "#{cust_count} customers, #{order_count} orders created"
      rescue StandardError => e
        puts e.message
        puts e.backtrace
        abort
      end
    end
  end
end
