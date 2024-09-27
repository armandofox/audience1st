class ConvertStrongParamsToHashInDatabase < ActiveRecord::Migration[5.0]
  # in Rails 5, if things are stored as ActionController::Params hash in database, they will
  # cause in error when deserialized to Hash.  So, convert everything.  And we have to create a hacky
  # model since the real model insists on things being serialized as a hash...
  # https://stackoverflow.com/a/48775771/558723
  class VtHack < ActiveRecord::Base
    self.table_name = 'vouchertypes'
    serialize :included_vouchers
  end
  def change
    vt = VtHack.where.not(included_vouchers: nil)
    total_records = vt.count
    say "Updating #{total_records} vouchertypes:"
    vt.each_with_index do |vtype,index|
      unless vtype.included_vouchers.is_a?(ActiveSupport::HashWithIndifferentAccess)
        say "converting #{index+1} of #{total_records} (id=#{vtype.id})"
        vtype.included_vouchers = vtype.included_vouchers.to_unsafe_h
        vtype.included_vouchers_will_change!
        vtype.save!
      else
        say "skipping #{index+1} (id=#{vtype.id})"
      end
    end
  end
end
