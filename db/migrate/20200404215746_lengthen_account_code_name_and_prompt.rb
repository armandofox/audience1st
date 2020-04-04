class LengthenAccountCodeNameAndPrompt < ActiveRecord::Migration
  def change
    change_column 'account_codes', 'name', :string, :limit => 255
  end
end
