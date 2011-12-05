class CamelcaseToSnakeCase < ActiveRecord::Migration
  def self.up
    connection.execute "UPDATE imports SET type='TbaWebtixImport' WHERE type='TBAWebtixImport';"
    connection.execute "UPDATE bulk_downloads SET type='TbaDownload' WHERE type='TBADownload';"
  end

  def self.down
    connection.execute "UPDATE imports SET type='TBAWebtixImport' WHERE type='TbaWebtixImport';"
    connection.execute "UPDATE bulk_downloads SET type='TBADownload' WHERE type='TbaDownload';"
  end
end
