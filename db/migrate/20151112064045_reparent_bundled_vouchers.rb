class ReparentBundledVouchers < ActiveRecord::Migration

  # Reparent groups of "kids" (bundled subscriber vouchers) that need to be reparented.
  # This is complicated because due to changes in the way vouchers were instantiated when
  # buying bundles, a pair of bundles each containing 3 kids could
  # appear with consecutive ids in one of two ways:
  #     p1, c1,c2,c3, p2, c1,c2,c3
  # or  p1,p2,  c1,c2,c3, c1,c2,c3

  # reparenting means setting both the bundle_id AND the order_id of reparented vouchers to 
  #  match the parent (since originally the orphans might have been placed in separate orders)

  # DELETE all EMPTY orders (having no items)

  #   - verify that no Subscriber vouchers remain with bundle_id=0
  
  # - for each bundle that was REFUNDED but has children
  #   - mark the children as refunded

  def self.up
    # find all bundle vouchers that appear to be childless
    bundles = Voucher.find(:all, :include => :vouchertype, :order => 'items.id',
      :conditions => "items.category = 'bundle'")
    bundles.reject! { |v| ! v.vouchertype.num_included_vouchers == 0 ||
      !v.bundled_vouchers.empty? }
    say "#{bundles.size} childless bundles"
    rep = Reparenter.new(bundles)
    Voucher.record_timestamps = false
    Voucher.transaction do
      rep.walk_bundles
    end
    say "#{rep.complete.size} bundles completed"
    say "#{rep.incomplete.size} bundles may be short:"
    say self.id_list(rep.incomplete.map(&:id))
  end
  
  def self.id_list(ary)
    format = Array.new(ary.length, '%d').join(',')
    sprintf "SELECT * FROM items WHERE id IN (#{format})", *ary
  end

  class Reparenter
    attr_accessor :bundles, :complete, :incomplete
    def initialize(bundles)
      @bundles = bundles
      @complete = []
      @incomplete = []
    end
    def walk_bundles
      @bundles.each_with_index do |bundle,i|
        if i%100 == 0
          print "."
          STDOUT.flush
        end
        if (try_fill_bundle(bundle))
          @complete << bundle
        else
          @incomplete << bundle
        end
      end
    end
    private
    def stopping_point?(v)
      v.category != :subscriber && v.category != :bundle
    end
    def get_next_voucher(curr_id)
      # stop if we hit a voucher that is neither a bundle nor a subscriber-voucher        
      v = nil
      loop do
        curr_id += 1
        return nil,curr_id+1 if curr_id >= 137000
        v = Voucher.find_by_id(curr_id)
        next if v.nil?
        return v,curr_id if v.category == :subscriber && v.bundle_id == 0 # candidate
        return nil,curr_id if stopping_point?(v)
      end
    end
    def try_fill_bundle(bundle)
      included = bundle.vouchertype.get_included_vouchers
      count = bundle.vouchertype.num_included_vouchers
      current_id = bundle.id 
      # start walk ID's in increasing order from bundle voucher.
      # if we can "fill a slot" with an included voucher, do so.
      # continue walking until we hit a non-bundle & non-subscriber voucher
      loop do
        voucher,current_id = get_next_voucher(current_id)
        if voucher.nil?
          complete = (bundle.bundled_vouchers.count == count)
          puts "#{bundle.id}  #{bundle.bundled_vouchers.count}/#{bundle.num_included_vouchers}\n" if !complete
          return complete
        end
        # stop if all slots filled
        vtype_id = voucher.vouchertype_id
        if included.has_key?(vtype_id) &&
            bundle.bundled_vouchers.map(&:vouchertype_id).count(vtype_id) < included[vtype_id]
          bundle.bundled_vouchers << voucher
          voucher.update_attributes!(:bundle_id => bundle.id, :order_id => bundle.order_id)
          return true if (bundle.bundled_vouchers.count == count)
        end
      end
    end

  end
end
