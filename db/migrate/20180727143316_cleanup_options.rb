class CleanupOptions < ActiveRecord::Migration
  def change
    # remove unused venue_id and venue_shortname fields
    remove_column :options, :venue_id
    remove_column :options, :venue_shortname
    remove_column :options, :sendgrid_key_name
  end
end
