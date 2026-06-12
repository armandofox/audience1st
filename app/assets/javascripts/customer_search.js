A1.setupSearchBox = function(textFieldId, datalistId, cidFieldId, ajaxUrl, autoSubmit) {
    const datalist = $('#' + datalistId);
    const textField = $('#' + textFieldId);
    const cidField = $('#' + cidFieldId);
    textField.on('input', function() {
        const val = $(this).val().trim();
        if (val.length < 3) { return; }
        /* if something selected from datalist, populate cidFieldId from data-cid attribute */
        const match = $('#' + datalistId + ' option').filter(function() {
            return $(this).val() === val;
        });
        if (match.length) {
            if (false && autoSubmit) {
                window.location.assign(match.attr('data-url'));
            } else {
                cidField.val(match.attr('data-cid') || '');
            }
        } 
        /* no selection from menu: refresh completion list via ajax */
        $.ajax({url: ajaxUrl,
                data: { term: val },
                success: function(resp) { datalist.html(resp); }
               });
    });
}

A1.load_customer_page = function(datalistId) {
    const match = $(datalistId + ' option[value="' + $(this).val() + '"]');
    window.location.assign(match.attr('data-url'));
}

A1.select_search_result = function(customer,textField,idField) {
  // User has selected a customer using autocomplete.
  // The customer object has label and value properties, where value is
  //   the customer id and label (in our case) is the customer full name.
  // Populate the '#id' field with the id, and the autocomplete text field
  //   with the chosen name.
  textField.val(customer.item.label);
  idField.val(customer.item.value);
  // If the text field ALSO has the class '_autosubmit', visit the 
  //   customer's page.
  if (textField.hasClass('_autosubmit')) {  
      window.location.assign($('#id').val());
  }
};

A1.setup_autocomplete_fields = function() {
  if (! $('#autocomplete_route').length) {
    return;
  }
  var autocomplete_url = $('#autocomplete_route').val().toString();
  $(A1.autocomplete_selector).each(function(i,elt) {
    var e = $(elt);
    // which ID field is associated with this autocomplete element?
    var idField = $('#' + e.data('resultfield'));
    // Blank out the ID field when search box gets focus
    e.focus(function(e) { idField.val(''); });
    // turn off browser autocompletion for text box
    e.attr('autocomplete', 'off');
    // set up autocompletion
    e.autocomplete({
      source: autocomplete_url,
      minLength: 2,
      select: function(event, selection) { 
        A1.select_search_result(selection,e,idField);   
        return(false);
      }
    });
  });
};

// $(A1.setup_autocomplete_fields);

