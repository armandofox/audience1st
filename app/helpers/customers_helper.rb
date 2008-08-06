module CustomersHelper

  def number_to_phone_2(s)
    (!s.blank? && s.strip.match(/^([-0-9.()\/ ]{10,})([EXText.0-9]+)?$/) ?
     number_to_phone($1.gsub(/[^0-9]/,'').to_i, :delimiter=>'.') << h($2.to_s) :
     h(s))
  end

  def multiple_voucher_comments(vouchers)
    vouchers.map { |v| v.comments unless v.comments.blank? }.compact.join('; ')
  end
  
  
  def group_subscriber_vouchers(v1,v2)
    # each of v1 and v2 is an array of [showdate,vouchertype].
    # showdate is nil for open voucher.
    # this function is used to "sort" them for presenting on customer
    # welcome page.
    # VOuchers for SAME SHOW (ie, same vouchertype) stay together
    # Within a show category, OPEN VOUCHERS are listed last, others
    # are shown by order of showdate
    # vouchers for DIFFERENT SHOWS are ordered by opening date of the show
    sd1,vt1 = v1
    sd2,vt2 = v2
    if vt1 != vt2
      vt1.showdates.min <=> vt2.showdates.min
    else
      sd1 ? sd1 <=> sd2 : -1
    end
  end

end
