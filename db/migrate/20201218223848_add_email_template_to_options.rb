class AddEmailTemplateToOptions < ActiveRecord::Migration
  def change
    change_table :options do |t|
      t.text 'html_email_template', :null => false, :default => ERB.new(IO.read(File.join(Rails.root, 'app', 'views', 'mailer', 'default_template.html.erb'))).result(binding)
    end
  end
end
