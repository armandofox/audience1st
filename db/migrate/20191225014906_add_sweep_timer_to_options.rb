class AddSweepTimerToOptions < ActiveRecord::Migration
  def change
    change_table 'options' do |t|
      t.datetime 'last_sweep', :null => false, :default => Time.zone.now
    end
  end
end
