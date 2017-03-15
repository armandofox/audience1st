A1.select_special_report = function() {
  var report_name = $(this).val();
  var url = $(this).data('submit') + '?' + $.param({"special_report_name": report_name});
  $('#report_body').load(url);
};

$(function() {
  $('#special_report_name').on('change',A1.select_special_report);
});

  
