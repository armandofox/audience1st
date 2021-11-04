class AddImportTimeoutToOptions < ActiveRecord::Migration
  def change
    change_table 'options' do |t|
      t.integer 'import_timeout', :null => false, :default => 15
    end
  end
end
