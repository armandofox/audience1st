A1.autocomplete = {
  textField: '#autocomplete',
  idField:   '#id',
  url: '/ajax/customer_autocomplete'
};

A1.select_search_result = function(event, customer) {
  // User has selected a customer using autocomplete.
  // The customer object has label and value properties, where value is
  //   the customer id and label (in our case) is the customer full name.
  // Populate the '#id' field with the id, and the autocomplete text field
  //   with the chosen name.
  jQuery(A1.autocomplete.textField).val(customer.item.label);
  jQuery(A1.autocomplete.idField).val(customer.item.value);
  return(false);
};

      
jQuery(function() {
  jQuery(A1.autocomplete.textField).autocomplete({
    source: A1.autocomplete.url,
    minLength: 2,
    select: A1.select_search_result
  });
});
