class Cart
  require 'set'
  attr_accessor :items
  attr_accessor :total_price
  attr_accessor :comments

  private

  # number of seconds from the epoch to 1/1/2008, used to offset order ID's
  TIMEBASE = 1230796800 unless defined?(TIMEBASE)
  def self.generate_order_id
    sprintf("%02d%d%02d", Option.value(:venue_id), Time.now.to_i - TIMEBASE,
           Time.now.usec % 37).to_i
  end

  public
  
  def initialize
    @items = []
    @total_price = 0.0
    @comments = ''
  end

  def order_number
    @order_number ||= Cart.generate_order_id
  end

  def workaround_rails_bug_2298!
    # Rails Bug 2298: when a db txn fails, the id's of the instantiated objects
    # that were not saved are NOT reset to nil, which causes problems when they are
    # successfully saved later on (eg when transaction is rerun).  Also, new_record is
    # not correctly reset to true.
    # the fix is based on a patch shown here:
    # http://s3.amazonaws.com/activereload-lighthouse/assets/fe67deaf98bb15d58218acdbbdf7d4f166255ad3/after_transaction.diff?AWSAccessKeyId=1AJ9W2TX1B2Z7C2KYB82&Expires=1263784877&Signature=ZxQebT1e9lG8hqexXb6IMvlfw4Q%3D
    self.items.each do |i|
      i.instance_eval {
        @attributes.delete(self.class.primary_key)
        @attributes_cache.delete(self.class.primary_key)
        @new_record = true
      }
    end
  end

  def empty!
    @items = []
    @total_price = 0.0
    @comments = ''
  end

  def empty?
    self.items.empty?
  end

  def vouchers_only
    self.items.select { |i| i.kind_of?(Voucher) }
  end

  def donations_only
    self.items.select { |i| i.kind_of?(Donation) }
  end

  def nondonations_only
    self.items.reject { |i| i.kind_of?(Donation) }
  end

  def gift_from(buyer)
    # mark all Vouchers (but not Donations or other stuff in cart) as a gift
    # for the given customer.
    raise "Invalid gift recipient record" unless buyer.kind_of?(Customer)
    self.vouchers_only.map { |v|  v.gift_purchaser_id = buyer.id }
  end

  def to_s
    notes = {}
    txt = self.items.map do |i|
      case
      when i.kind_of?(Voucher)
        if i.showdate_id.to_i > 0
          s=sprintf("$%6.2f  %s\n         %s - ticket \##{i.id}",
            i.vouchertype.price,
            i.showdate.printable_name,
            i.vouchertype.name)
          s << "\n         Seating request: #{i.comments}" unless i.comments.to_s.empty?
          unless i.showdate.show.patron_notes.blank?
            notes[i.showdate.show.name] = i.showdate.show.patron_notes
          end
          s
        else
          sprintf("$%6.2f  %s - voucher \##{i.id}",
            i.vouchertype.price,
            i.vouchertype.name)
        end
      when i.kind_of?(Donation)
        sprintf("$%6.2f  Donation to General Fund (confirmation \##{i.id})", i.amount)
      end
    end.join("\n")
    txt << "\n"
    # add per-show notes if there
    notes.each_pair do |showname,note|
      txt << "\nSPECIAL NOTE for #{showname}:\n#{note.wrap(60)}"
    end
    txt
  end

  def add(itm,qty=1)
    self.items << itm
    self.items.sort! do |a,b|
      if a.class != b.class
        b.class.to_s <=> a.class.to_s
      elsif a.kind_of?(Voucher) 
        a <=> b
      else
        a.donation_fund_id <=> b.donation_fund_id
      end
    end
    self.total_price += itm.price
  end

  def donation
    self.items.detect { |i| i.kind_of?(Donation) }
  end

  def include_donation?
    self.items.detect { |i| i.kind_of?(Donation) }
  end
  def include_vouchers?
    self.items.detect { |i| i.kind_of?(Voucher) }
  end
end
