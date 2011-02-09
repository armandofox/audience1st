Given /a valid Goldstar will-call email "(.*)" for "(.*)" on (.*)/ do |raw_email, show, date|
  @email = IO.read("#{RAILS_ROOT}/spec/import_test_files/goldstar_auto_importer/#{raw_email}")
  Given "a performance of \"#{show}\" on #{date}"
end
