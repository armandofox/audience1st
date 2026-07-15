/* Find all text fields that have a 'data-autocompleteResult' attribute and enable
   them as autocomplete fields. The ID of the chosen element is populated into the field
   whose ID is given by data-autocompleteResult.  If data-autocompleteRedirect is true,
   choosing a value goes straight to its associated URL. */

A1.setupAutocomplete = function() {
    $('input[type="text"][data-autocomplete-id]').each(function() {
        var textField = $(this);
        var idField = $('#' + textField.data('autocomplete-id'));
        textField.attr('autocomplete', 'off');
        textField.autocomplete({
            minChars: 3,
            serviceUrl: '/ajax/customer_autocomplete',
            showNoSuggestionNotice: true,
            noSuggestionNotice: '(no matches)',
            onSelect: function(suggestion) {
                textField.val(suggestion.value).trigger('change');
                idField.val(suggestion.data).trigger('change');
            }
        });
    });
}
            
$(A1.setupAutocomplete);
