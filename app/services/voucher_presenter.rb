class VoucherPresenter
  #
  # Presentation logic to show ValidVouchers in customer view.
  # Vouchers of same type and reserved for same showdate are grouped together.
  # For groups of vouchers that are unreserved, we display a dropdown menu so customer can select
  # how many of that voucher to confirm a reservation for.
  # For groups of vouchers that are reserved, we show the date and, if it's a self-cancelable-by-customer
  # voucher, a Cancel button.
  #
  # The presentation logic takes a whole batch of vouchers and returns an ordered list of
  # VoucherPresenter objects.
  #
  require 'set'
  attr_reader :vouchers, :reserved, :group_id, :size,  :vouchertype, :name, :redeemable_for_multiple_shows, :showdate, :voucherlist
  # Constructor takes a set of vouchers that should be part of a group, and constructs the
  # presentation logic for them.  It's an error for the provided vouchers not to "belong together"
  # (must all have same showdate and vouchertype, OR must all be unreserved and same vouchertype)
  class InvalidGroupError < StandardError ; end
  def initialize(vouchers,ignore_cutoff=false)
    @vouchers = vouchers.sort_by(&:id)
    raise InvalidGroupError.new("Vouchers don't belong together") unless vouchers_belong_together
    first = @vouchers[0]
    @ignore_cutoff = ignore_cutoff
    @reserved = first.reserved?
    @group_id = first.id
    @size = @vouchers.length
    @vouchertype = first.vouchertype
    @showdate = first.showdate
    @voucherlist = @vouchers.map { |v| v.id }.join(',')
    # group name: if ALL vouchers in group are redeemable for only a single production,
    #  the production's name is the group name.  otherwise, use the vouchertype name (all of
    #  them are guaranteed to be the same vouchertype anyway).
    show_names = @vouchertype.valid_vouchers.map(&:show_name).compact.uniq
    if show_names.length == 1
      @name = show_names.first
      @redeemable_for_multiple_shows = false
    else
      @name =  @vouchertype.name
      @redeemable_for_multiple_shows = true
    end
  end

  def redeemable_showdates
    @redeemable_showdates ||= if @vouchers[0].reservable? then @vouchers[0].redeemable_showdates(@ignore_cutoff) else [] end
  end

  def menu_label_function(admin_display = false)
    if admin_display
      if redeemable_for_multiple_shows
        :name_with_explanation_for_admin
      else
        # :name_and_date_with_capacity_stats
        :date_with_explanation_for_admin
      end
    elsif redeemable_for_multiple_shows
      # dropdown menu should include showname AND date
      :name_with_explanation
    else
      # dropdown menu should show ONLY the date
      :date_with_explanation
    end
  end

  def cancelable?
    vouchers.all?(&:can_be_changed?)
  end

  def voucher_comments
    vouchers.map(&:comments).map(&:to_s).reject(&:blank?).uniq.join('; ')
  end
  
  def seats
    if ! @vouchers.first.reserved?              then ''
    elsif  @vouchers.all? { |v| v.seat.blank? } then 'General Admission' 
    else                                        Voucher.seats_for(@vouchers)
    end
  end

  # Within a show category, OPEN VOUCHERS are listed last, others are shown by order of showdate
  # vouchers for DIFFERENT SHOWS are ordered by opening date of the show
  # vouchers NOT VALID FOR any show are ordered by their vouchertype's display_order
  def <=>(other)
    sd1,vt1 = self.showdate, self.vouchertype
    sd2,vt2 = other.showdate, other.vouchertype
    if vt1 == vt2
      # same vouchertype: order by OPENING DATE of the show for which reserved, or display order
      # if not reserved
      return (if (sd1 && sd2) then (sd1 <=> sd2) else (vt1.display_order <=> vt2.display_order) end)
    end
    # else different vouchertypes, so the rules are:
    # if same show, order by showdate
    if (sd1 && sd2 && (sd1.show  == sd2.show))
      return sd1 <=> sd2
    end
    # vouchertypes WITH assigned showdates always go first
    shows1,shows2 = vt1.showdates, vt2.showdates  # which showdates is vouchertype valid for?
    if    ! shows1.empty? && ! shows2.empty? then (shows1.min <=> shows2.min)
    elsif   shows1.empty? &&   shows2.empty? then (vt1.display_order <=> vt2.display_order) # voucher having show validity goes first
    elsif   shows1.empty? && ! shows2.empty? then 1    # voucher having show validity goes first
    else # !shows1.empty? &&  shows2.empty?
      -1
    end
  end

  def self.groups_from_vouchers(vouchers,ignore_cutoff=false)
    # Group the vouchers so that a set of vouchers sharing same vouchertype and showdate stay together
    groups = Set.new(vouchers).classify { |v| [v.showdate, v.vouchertype] }
    # Create a presenter object for each group
    formatted_groups = groups.keys.map { |k| VoucherPresenter.new(groups[k].to_a, ignore_cutoff) }
    # 
    # Ordering rules:
    # Subscriber vouchers all reserved for SAME SHOW (ie, same subscriber vouchertype) are grouped.
    # 
    formatted_groups.sort
  end

  private
  
  def vouchers_belong_together
    first = @vouchers.first
    if @vouchers.any?(&:reserved?)
      @vouchers.all? { |v| v.showdate == first.showdate && v.vouchertype == first.vouchertype }
    else
      @vouchers.all? { |v| v.vouchertype == first.vouchertype }
    end
  end
end
