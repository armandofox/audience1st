class Walkup < ActiveRecord::Migration
  def self.up
    # add 'walkup' customer with role=-1 (and optionally validation=-1)
    unless Customer.find_by_role(-1)
      Customer.create(:first_name => 'WALKUP',
                      :last_name => 'WALKUP',
                      :role => -1,
                      :validation_level => -1)
    end
    # add 'walk_cc' and 'walk_cash' purchasemethods if not present
    {'walk_cc' => 'Walkup sale (credit card)',
      'walk_cash' => 'Walkup sale (cash or check)'}.each_pair do |k,v|
      Purchasemethod.create(:shortdesc => k,:description => v) unless
        Purchasemethod.find_by_shortdesc(k)
    end
  end

  def self.down
    # no harm in leaving these, so do nothing here
  end
end
