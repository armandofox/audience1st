class RemoveEndAdvanceSalesFromShowdate < ActiveRecord::Migration
  def change
    begin
      Showdate.transaction do
        Showdate.all.includes(:valid_vouchers).each do |sd|
          showdate_end_sales = sd.end_advance_sales
          sd.valid_vouchers.where('end_sales > ?', showdate_end_sales).
            update_all(end_sales: showdate_end_sales)
        end
      end
      remove_column :showdates, :end_advance_sales
    rescue StandardError => e
      raise e
    end
  end
end
