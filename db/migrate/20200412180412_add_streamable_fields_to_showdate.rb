class AddStreamableFieldsToShowdate < ActiveRecord::Migration
  def change
    change_table 'showdates' do |t|
      t.boolean 'live_stream', :null => true, :default => nil
      t.boolean 'stream_anytime', :null => true, :default => nil
      t.text 'access_instructions', :null => true, :default => nil
    end
  end
end
