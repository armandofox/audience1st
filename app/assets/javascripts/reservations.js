A1.show_seating_options_for_showdate = function() {
  var container = $(this).closest('.row'); // the enclosing element that contains the relevant form fields
  $(container).find('.special-seating').removeClass('invisible');
  var url = '/ajax/seating_options/' + $(this).val();
  var targetDiv = $(container).find('.seating-options');
  // Remove once Option.feature_enabled? 'rs' is permanently false:
  $(container).find('.submit').prop('disabled', false);
  $.get(url, function(data) { targetDiv.html(data) });
};

A1.reservations_page_setup = function() {
  // when a showdate is selected, show either "Select seats" button or "Confirm" button (for Gen Adm)
  $('select.showdate').change(A1.show_seating_options_for_showdate);
  $(document).on('click', '.show-seatmap', A1.seatmap.showSeatmapForShowdate);
  // updating staff comments field (form-remote)
  $('.save_comment').on('ajax:success', function() { alert("Comment saved") });
  $('.save_comment').on('ajax:error', function() { alert("Error, comment NOT saved") });
};

$(A1.reservations_page_setup);

  
