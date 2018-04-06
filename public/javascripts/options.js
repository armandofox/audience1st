A1.optionsSetup = function() {
  // disable the editing of 'integration' option values initially

  $('#configOptions input, #configOptions select').prop('disabled', true);

  // when enabled, disable the 'try these values' option until save & reload

  $('#allowChanges').click(function() {
    alert("Integration options can now be edited. Proceed with care."); 
    $('#configOptions input, #configOptions select').prop('disabled', false);
    $('#testIntegrations').prop('disabled', true);
  });
};

if ($('body#options_index').length > 0) { // only on Options page
  $(A1.optionsSetup);
}

