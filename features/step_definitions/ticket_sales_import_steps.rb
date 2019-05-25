When /I upload the "(.*)" will-call file "(.*)"/ do |vendor,file|
  visit ticket_sales_imports_path
  select vendor, :from => 'vendor'
  attach_file 'file', "#{Rails.root}/spec/import_test_files/#{vendor.underscore}"
  click_button 'Continue'
end
