A1.autocompleteOn = function(textFieldId,idFieldId,autoRedirect = false) {
    var textFieldSelector = $('#' + textFieldId);
    var idFieldSelector = $('#' + idFieldId);
    textFieldSelector.
        addClass('_autocomplete'). // so tests can find it
        autocomplete({
        minChars: 3,
        serviceUrl: '/ajax/customer_autocomplete',
        onSelect: function(suggestion) {
            /* if data is zero, it means there was no match, so ignore */
            if (suggestion.data == 0 && suggestion.url == '') {
                textFieldSelector.val('');
                idFieldSelector.val('');
            } else {
                textFieldSelector.val(suggestion.value);
                idFieldSelector.val(suggestion.data);
                if (autoRedirect && suggestion.url != '') {
                    window.location.assign(suggestion.url);
                }
            }
        }
    });
};
