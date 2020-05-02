class AddStreamableFieldsToShowdate < ActiveRecord::Migration
  def change
    change_table 'showdates' do |t|
      t.boolean 'live_stream', :null => true, :default => false
      t.boolean 'stream_anytime', :null => true, :default => false
      t.text 'access_instructions', :null => true, :default => false
    end
    Showdate.update_all(:live_stream => false, :stream_anytime => false)
  end
end
