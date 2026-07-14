A1.autocompleteOn = function(textFieldSelector,idFieldSelector,autoRedirect = false) {
    textFieldSelector.
        addClass('_autocomplete'). // so tests can find it
        autocomplete({
        minChars: 3,
        serviceUrl: '/ajax/customer_autocomplete',
        paramName: 'q',
        onSelect: function(suggestion) {
            textFieldSelector.val(suggestion.value);
            idFieldSelector.val(suggestion.data);
            if (autoRedirect && suggestion.url != '') {
                window.location.assign(suggestion.url);
            }
        }
    });
};
