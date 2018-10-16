class AllowSelfServiceComps < ActiveRecord::Migration
  def change
    add_column :options, :allow_self_service_comps, :boolean, :default => false
  end
end
