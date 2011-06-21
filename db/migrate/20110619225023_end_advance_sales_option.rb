class EndAdvanceSalesOption < ActiveRecord::Migration
  def self.up
    opt = Option.create!(:grp => 'Ticket Sales',
      :name =>     'advance_sales_cutoff',
      :value => '180',
      :typ => :int)
    ActiveRecord::Base.connection.execute("UPDATE options SET id=1005 WHERE id=#{opt.id}")
  end

  def self.down
    Option.find_by_name('advance_sales_cutoff').destroy
  end
end
