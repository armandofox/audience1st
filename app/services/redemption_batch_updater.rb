class RedemptionBatchUpdater

  attr_reader :showdates, :vouchertypes, :performance_type
  attr_accessor :valid_voucher_params, :preserve

  def initialize(showdates, vouchertypes, valid_voucher_params: {}, preserve: {})
    @showdates = showdates
    @vouchertypes = vouchertypes
    @valid_voucher_params = valid_voucher_params.to_h.symbolize_keys
    @preserve = preserve.to_h.symbolize_keys
    @errs = Hash.new { |h,k| h[k] = [] } # vouchertype => showdate_id's to which it could NOT be added
    @possible_cause = {}
    @vv = nil
  end

  def update
    # Transactionally add one or more vouchertypes to multiple showdates.  
    # If errors, collate them intelligently and fail.
    # If +valid_voucher_params+ includes a key
    # <tt>:before_showtime => val</tt>, then each valid voucher's end-sales should be overridden to be
    # +val+ prior to its showtime (+val+ must be an object that can be added/subtracted from +Time+).
    @before_showtime = valid_voucher_params.delete(:before_showtime).to_i
    ValidVoucher.transaction do
      showdates.each do |showdate|
        # if this valid-voucher exists already, edit it in place; otherwise create new.
        vouchertypes.each do |vouchertype|
          if (@vv = ValidVoucher.find_by(:showdate => showdate, :vouchertype => vouchertype))
            selectively_assign_to_existing
          else
            @vv = build_new(showdate,vouchertype)
          end
          add_error unless @vv.save
        end
      end
      # if any errors occurred, commit none of the changes.
      raise ActiveRecord::Rollback unless @errs.empty?
    end
    @errs.empty?
  end

  def error_message
    @errs.map do |vouchertype,dates|
      "Can't add '#{vouchertype.name}' (possibly because #{@possible_cause[vouchertype]}) " <<
        "to #{dates.size} dates including #{dates.first}"
    end.join('; ')
  end

  private
  
  def selectively_assign_to_existing
    args = valid_voucher_params.clone
    # special case: to preserve start/end_sales args, delete datepicker parms (start_sales(1i), etc)
    args.reject!  { |k,v| k =~ /start_sales/ }  if preserve[:start_sales]
    args.reject!  { |k,v| k =~ /end_sales/   }  if preserve[:end_sales]
    preserve.keys.each { |k| args.delete(k.to_sym) }
    # assign all remaining (non-preserved) attributes
    @vv.assign_attributes(args)
    # special case: IF end_sales should be overwritten for live shows, use @before_showtime
    if !preserve[:end_sales] && @vv.showdate.live?
      @vv.end_sales = (@vv.showdate.thedate - @before_showtime).rounded_to(:minute)
    end
  end

  def build_new(showdate,vouchertype)
    params = valid_voucher_params.merge({:showdate => showdate, :vouchertype => vouchertype})
    @vv = ValidVoucher.new(params)
    # set end sales appropriately for performance type if live performance
    @vv.end_sales = (showdate.thedate - @before_showtime).rounded_to(:minute) if showdate.live?
    @vv
  end

  def add_error
    @errs[@vv.vouchertype] << @vv.showdate.thedate.to_formatted_s(:showtime_brief)
    @possible_cause[@vv.vouchertype] = @vv.errors.full_messages.join(', ')
  end
end
