A1.optionsSetup = function() {
  // see if a maintenance password is set now, so we can warn if maintenance mode changes
  A1.staffOnly = $('#option_staff_access_only').val(); // "true" or "false"
  $('form#edit_option_1').submit(A1.maintenanceModeWarning);
  // disable the editing of 'integration' option values initially
  $('#configOptions input, #configOptions select').prop('disabled', true);

  // when enabled, disable the 'try these values' option until save & reload
  $('#allowChanges').click(function() {
    alert($('#integrationWarning').text());
    $('#configOptions input, #configOptions select').prop('disabled', false);
    $('#testIntegrations').hide();
  });
};

A1.maintenanceModeWarning = function() {
  // did we change from non-maintenance to maintenance mode?
  var newStaffOnly = $('#option_staff_access_only').val();
  if (A1.staffOnly == 'false' &&  newStaffOnly == 'true') {
    A1.staffOnly = 'true';     // re-trigger warning in case change
    return(confirm($('#enableMaintenanceWarning').text()));
  } else if (A1.staffOnly == 'true' && newStaffOnly == 'false') {
    A1.staffOnly = 'false';      // in case admin changes it to diff value, re-trigger warning
    return(confirm($('#disableMaintenanceWarning').text()));
  } else {
    return(true);
  }
}


$(function() {
  if ($('body#options_index').length) { // only on Options page
    $(A1.optionsSetup);
  }
});


