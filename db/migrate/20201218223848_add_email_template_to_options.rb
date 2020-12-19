class AddEmailTemplateToOptions < ActiveRecord::Migration
  def change
    change_table :options do |t|
      t.text 'html_email_template', :null => false, :default => Mailer::MINIMAL_TEMPLATE
    end
  end
end
