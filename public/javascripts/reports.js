A1.select_special_report = function() {
  var report_name = $(this).val();
  var url = $(this).data('submit') + '?' + $.param({"report_name": report_name});
  $('#report_body').load(url);
};

A1.estimate_or_run_report = function(evt) {
  evt.preventDefault();
  $(this).prop('disabled', true);
  var form = $('form#special_report');
  var url = (form.attr('action') + '?' + form.serialize());
  $('#report_preview').text('Estimating...');
  $('#report_preview').load(form.attr('action'), form.serialize(), (function() { $('#estimate').prop('disabled', false) }));
  return(false);
};

A1.report_bindings = function() {
  $('#report_name').on('change',A1.select_special_report);
  $(document).on('click', '#estimate', null, A1.estimate_or_run_report); // since partial not created til later!
}

$(A1.report_bindings);


  
