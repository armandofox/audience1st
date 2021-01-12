class RemoveRunDatesFromShow < ActiveRecord::Migration
  def change
    remove_column 'shows', 'opening_date'
    remove_column 'shows', 'closing_date'
  end
end
