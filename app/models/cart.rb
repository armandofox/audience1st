class Cart

  attr_accessor :items
  attr_accessor :total_price

  def initialize
    @items = []
    @total_price = 0.0
  end
  
  def empty!
    @items = []
    @total_price = 0.0
  end

  def is_empty?
    self.items.empty?
  end

  def to_s
    notes = {}
    txt = self.items.map do |i|
      case
      when i.kind_of?(Voucher)
        if i.showdate_id.to_i > 0
          s=sprintf("$%6.2f  %s\n         %s",
                    i.vouchertype.price,
                    i.showdate.printable_name,
                    i.vouchertype.name)
          s << "\n         Seating request: #{i.comments}" unless i.comments.to_s.empty?
          unless i.showdate.show.patron_notes.blank?
            notes[i.showdate.show.name] = i.showdate.show.patron_notes
          end
          s
        else
          sprintf("$%6.2f  %s",
                  i.vouchertype.price,
                  i.vouchertype.name)
        end
      when i.kind_of?(Donation)
        sprintf("$%6.2f  Donation to General Fund", i.amount)
      end
    end.join("\n")
    txt << "\n"
    # add per-show notes if there
    notes.each_pair do |showname,note|
      txt << "\nSPECIAL NOTE for #{showname}:\n#{note.wrap(60)}"
    end
    txt
  end

  def add(itm)
    if itm.kind_of?(Voucher)
      price = itm.vouchertype.price
    elsif itm.kind_of?(Donation)
      price = itm.amount
    else
      raise "Invalid item added to cart!"
    end
    self.items << itm
    self.items.sort! do |a,b|
      if a.class != b.class
        b.class.to_s <=> a.class.to_s
      elsif a.kind_of?(Voucher) && a.showdate_id.to_i > 0 && b.showdate_id.to_i > 0
        (a.showdate.show.name <=> b.showdate.show.name ||
         a.showdate.thedate <=> b.showdate.thedate)
      elsif a.kind_of?(Voucher) # subscription voucher(s)
        (a.showdate_id.to_i <=> b.showdate_id.to_i)
      else
        a.donation_fund_id <=> b.donation_fund_id
      end
    end
    self.total_price += price
  end

  def remove_index(itm)
    if (removed = self.items.delete_at(itm.to_i))
      if (removed.kind_of?(Voucher))
        self.total_price -= removed.vouchertype.price
      elsif (removed.kind_of?(Donation))
        self.total_price -= removed.amount
      else
        raise "Invalid item removed from cart!"
      end
    end
    self.total_price = [self.total_price, 0.0].max
  end

end
