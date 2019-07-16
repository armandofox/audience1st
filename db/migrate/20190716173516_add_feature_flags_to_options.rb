class AddFeatureFlagsToOptions < ActiveRecord::Migration
  def change
    change_table 'options' do |t|
      t.string 'feature_flags', :null => true, :default => [].to_yaml
    end
  end
end
