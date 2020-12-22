class AddBoxOfficeEmail < ActiveRecord::Migration
  def change
    if Option.first && Option.first.boxoffice_daemon_notify.blank?
      Option.first.update_attribute(:boxoffice_daemon_notify, Option.first.help_email)
    end
    rename_column 'options', 'boxoffice_daemon_notify', 'box_office_email'
  end
end
