class ShowdateMaxSalesIsNonzero < ActiveRecord::Migration
  def self.up
    Showdate.connection.execute('UPDATE showdates LEFT JOIN shows on showdates.show_id = shows.id SET showdates.max_sales=shows.house_capacity WHERE showdates.max_sales = 0')
  end

  def self.down
  end
end
