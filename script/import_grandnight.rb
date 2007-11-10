require 'rubygems'
require 'faster_csv'
require_gem 'activerecord'
RAILS_ROOT = '/Users/fox/Documents/fox/projects/vbo/vbo'
%w[customer voucher vouchertype showdate show valid_voucher].each do |f| 
  require "#{RAILS_ROOT}/app/models/#{f}.rb"
end
db_config = YAML::load(File.open("#{RAILS_ROOT}/config/database.yml"))
ActiveRecord::Base.establish_connection(db_config['production'])

def go(filename)
  count = 0
  bad = 0
  bad_date =  File.open("bad_date.csv", "wb")
  bad_cust = File.open("bad_cust.csv", "wb")
  bad_vouch = File.open("bad_vouch.csv", "wb")
  FasterCSV.foreach(filename, :headers => true) do |r|
    if r.field('Admission Level').match(/season/i)
      f = r.field('Attendee F Name')
      l = r.field('Attendee L Name')
      d = Time.parse(r.field('Event Start Date'))
      sd = Showdate.find_by_thedate(d)
      unless (sd.is_a?(Showdate))
        bad_date << r
        bad += 1
        putc "d"
      else
        if ((c = Customer.find(:all, :conditions => ['last_name LIKE ? AND first_name LIKE ?', l, f])).length == 1) ||
          ((c = Customer.find(:all, :conditions =>  "last_name LIKE '#{l}' AND first_name LIKE '%#{f}%'")).length == 1)
          c = c.first
          cv = c.vouchers
          if nil && cv && cv.select { |v| v.showdate_id > 0 && v.showdate.show_id == 5 }.length > 0
            putc ","            # cust already taken care of
          else
            v = cv.find(:first, :conditions => 'vouchertype_id = 19 AND showdate_id = 0')
            if (v.kind_of?(Voucher)) # go ahead
              v.showdate_id = sd.id
              v.save!
              count += 1
              putc "."
            else
              bad_vouch << r
              bad += 1
              putc "v"
            end
          end
        else                      # cust not found
          bad_cust << r
          bad += 1
          putc "c"
        end
      end
    else
      putc "-"
    end
    $stdout.flush
  end
  puts "\n#{count} processed, #{bad} need attention"
  bad_cust.close
  bad_vouch.close
  bad_date.close
end

go("grandnight_subscriber.csv")


