module CustomerSearchHelper

  # Search combobox: create a text field with the given id that will serve as an
  #  autocomplete for customer search.  Create the related datalist element based on
  #  the text field's id.  When a customer is selected:
  #  - result_field_id must be provided: the selected ID is copied to that field
  #  - If autosubmit is true, the associated customer's homepage URL (passed back by ajax)
  #    is visited
  #  - html_options are applied to the text field
  def customer_search_box(text_field_id, result_field_id, placeholder: '', autosubmit: false, html_options: {})
    html_options[:autocomplete] = 'off'
    tags = []
    tags << text_field_tag(text_field_id, placeholder, html_options)
    tags << hidden_field_tag(result_field_id)
    tags << javascript_tag(%Q{
A1.setupSearchBox('#{text_field_id}', '#{result_field_id}', '#{customer_autocomplete_path}', #{autosubmit});})
  end

end
