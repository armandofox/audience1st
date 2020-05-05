class ForceBooleanValuesOnStreamingAttributes < ActiveRecord::Migration
  def change
    Showdate.where(:live_stream => nil).where(:stream_anytime => nil).
      update_all(:live_stream => false, :stream_anytime => false)
    change_column :showdates, :live_stream, :boolean, :null => false, :default => false
    change_column :showdates, :stream_anytime, :boolean, :null => false, :default => false
  end
end
