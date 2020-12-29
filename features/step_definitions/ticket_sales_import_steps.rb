module TicketSalesImportStepsHelper
  def find_import_row_for(name)
    page.find(:xpath, "//tr/td[text()='#{name}']/..")    
  end
end

World(TicketSalesImportStepsHelper)

When /I upload the "(.*)" will-call file "(.*)"/ do |vendor,file|
  visit ticket_sales_imports_path
  select vendor, :from => 'vendor'
  attach_file 'file', "#{TEST_FILES_DIR}/#{vendor.underscore}/#{file}", :visible => false
  click_button 'Upload'
end

When /I select the following options for each import:/ do |table|
  table.hashes.each do |h|
    # identify the table row for this customer
    tr = find_import_row_for h[:import_name]
    tr.find('select').select h[:action]
  end
end

# Checking the appearance/status of an importable order

Then /the default import action for "(.*)" should be "(.*)"/ do |name,action|
  tr = find_import_row_for name
  select = tr.find(:css, 'select')
  expect(select.find("option[@value='#{select.value}']").text).to eq(action)
end  

Then /the import for "(.*)" should show "(.*)"/ do |name,status|
  tr = find_import_row_for name
  expect(tr.find(:css, 'td.actions').text).to have_content(status)
end

Then /there should be no import with filename "(.*)"/ do |filename|
  expect(TicketSalesImport.where(:filename => filename)).to be_empty
end
