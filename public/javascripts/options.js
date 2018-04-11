A1.optionsSetup = function() {
  // see if a maintenance password is set now, so we can warn if maintenance mode changes
  A1.maintPassword = $('#option_maintenance_password').val();
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
  debugger;
  var newMaintPw = $('#option_maintenance_password').val();
  if (A1.maintPassword == '' &&  newMaintPw != '') {
    A1.maintPassword = 'x';     // re-trigger warning in case change
    return(confirm($('#enableMaintenanceWarning').text()));
  } else if (A1.maintPassword != '' && newMaintPw == '') {
    A1.maintPassword = '';      // in case admin changes it to diff value, trigger warning
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


