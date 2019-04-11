# tabular data

World(XPath)

Then /^I should (not )?see a row "(.*)" within "(.*)"$/ do |flag, row, table|
  page.should have_xpath("//#{table}")
  @rows = page.all(:xpath, "//#{table}//tr").collect { |r| r.all(:xpath, './/th|td') }
  col_regexps = row.split('|').map { |s| Regexp.new(s) }
  matched = @rows.any? do |table_row|
    match = true
    col_regexps.each_with_index do |regexp,index|
      match &&= (regexp.blank? || table_row[index].text.match(regexp))
    end
    match
  end
  if flag =~ /not/
    matched.should be_falsey, "Expected #{table} NOT to contain a row matching <#{row}>"
  else
    matched.should be_truthy, "Expected #{table} to contain a row matching <#{row}>"
  end
end

# look for matching values within a particular column
Then /^column "(.*)" of table "(.*)" should include( only)?: (.*)/ do |col,tbl,only,list|
  list = list.split(/\s*,\s*/)
  table_container = page.find(:css, tbl)
  table_col_index = table_container.all(:xpath, "//tr//th").map(&:text).index(col)
  # verify column is present
  expect(table_col_index).not_to be_nil
  # extract column contents
  col_values = table_container.all(:xpath, "//tr/td[#{1+table_col_index}]").map(&:text)
  (expect(col_values.size).to eq(list.size)) if only
  list.each { |elt| expect(col_values).to include(elt) }
end

# match several rows
Then /^table "(.*)" should (not )?include:$/ do |result,negate,table|
  table_container = page.find(:css, result)

  # verify all column names specified are actually present in <th> elements
  result_headers = table_container.all(:xpath, "//tr//th").map(&:text)
  desired_headers = table.hashes.first.keys
  desired_headers.each { |column|  result_headers.should include(column) }

  # construct ColName => value hash for each result row, using ONLY the columns specified in desired results
  result_rows = table_container.all(:xpath, "//tbody/tr")
  result_hashes = Array.new(result_rows.length) { Hash.new }
  result_rows.each_with_index do |row,row_index|
    row.all(:xpath, "td").map(&:text).each_with_index do |col_value, col_position|
      col_name = result_headers[col_position]
      result_hashes[row_index][col_name] = col_value if desired_headers.include?(col_name)
    end
  end
  # verify all given results appear in table
  if negate =~ /not/
    table.hashes.all? { |hash| result_hashes.should_not include(hash) }
  else
    table.hashes.all? { |hash| result_hashes.should include(hash) }
  end
end

