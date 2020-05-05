class AddStreamableFieldsToShowdate < ActiveRecord::Migration
  def change
    change_table 'showdates' do |t|
      t.boolean 'live_stream', :null => false, :default => false
      t.boolean 'stream_anytime', :null => false, :default => false
      t.text 'access_instructions', :null => true
    end
  end
end
