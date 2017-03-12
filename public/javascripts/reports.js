A1.select_special_report = function() {
  var report_name = $(this).val();
  var url = $(this).data('submit') + '?' + $.param({"report_name": report_name});
  $('#report_body').load(url);
};

$(function() {
  $('#report_name').on('change',A1.select_special_report);
});

  
