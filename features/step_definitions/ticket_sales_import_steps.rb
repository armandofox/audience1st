When /I upload the "(.*)" will-call file "(.*)"/ do |vendor,file|
  visit ticket_sales_imports_path
  select vendor, :from => 'vendor'
  attach_file 'file', "#{Rails.root}/spec/import_test_files/#{vendor.underscore}/#{file}", :visible => false
  click_button 'Upload'
end

When /I select the following options for each import:/ do |table|
  table.hashes.each do |h|
    # identify the table row for this customer
    tr = page.find(:xpath, "//tr/td[text()='#{h[:import_name]}']/..")
    tr.find('select').select h[:action]
  end
end
