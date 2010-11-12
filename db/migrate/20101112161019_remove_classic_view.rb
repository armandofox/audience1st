class RemoveClassicView < ActiveRecord::Migration
  def self.up
    Option.find_by_name('force_classic_view').destroy
  end

  def self.down
  end
end
