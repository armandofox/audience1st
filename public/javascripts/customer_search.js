A1.autocomplete_selector = '._autocomplete';

A1.select_search_result = function(customer,textField,idField) {
  // User has selected a customer using autocomplete.
  // The customer object has label and value properties, where value is
  //   the customer id and label (in our case) is the customer full name.
  // Populate the '#id' field with the id, and the autocomplete text field
  //   with the chosen name.
  textField.val(customer.item.label);
  idField.val(customer.item.value);
};

A1.setup_autocomplete_fields = function() {
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

$(A1.setup_autocomplete_fields);

