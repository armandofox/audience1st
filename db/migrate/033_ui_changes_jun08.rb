class UiChangesJun08 < ActiveRecord::Migration
  def self.up
    # add an "Accepts Amex" option to production DB
    o = Option.create!(:grp => "Ticket Sales",
                       :name => "accept_amex",
                       :value => "1",
                       :typ => :int,
                       :description => "Set to zero if you DON'T accept the AmEx card. Set to any non-zero value to accept AmEx.")
    cmd = "UPDATE options SET id=1070 WHERE id=#{o.id}"
  end

  def self.down
  end
end
