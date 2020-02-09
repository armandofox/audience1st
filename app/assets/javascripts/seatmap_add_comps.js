A1.getSeatingOptionsForAddComps = function() {
  // triggered when a new perf is selected during Add Comps flow
  var showdateID = $('#comp_order_showdate_id').val();
  var resetAfter = function() {
    $('#seating-charts-wrapper').addClass('d-none');
    $('#comp_order_howmany').prop('readonly', false); // allow changing ticket count
    $('.seat-display').addClass('d-none');
    $('.confirm-seats').prop('disabled', false);
  };
  // if it's not a valid showdate, do nothing:
  if (showdateID == '' ||  isNaN(showdateID) )  {
    resetAfter();
    return;
  }
  $.getJSON('/ajax/seatmap/' + showdateID, function(jsonData) {
    if (jsonData.map == null) { 
      resetAfter();
    } else {
      $('.seat-display').removeClass('d-none');
      A1.seatmap.resetAfterCancel = resetAfter;
      A1.seatmap.onSelect = function() {
        $('.confirm-seats').prop('disabled', true);
        $('.seat-display').val(A1.seatmap.selectedSeatsAsString);
      };
      A1.seatmap.allSeatsSelected = function() {
        $('.confirm-seats').prop('disabled', false);
      }
      A1.seatmap.configureFrom(jsonData); // setup unavailable seats, etc
      A1.seatmap.max = Number($('#comp_order_howmany').val());
      $('#comp_order_howmany').prop('readonly', true); // still submits as part of form, but can't change
      A1.seatmap.seats = $('#seatmap').seatCharts(A1.seatmap.settings);
      $('#seating-charts-wrapper').removeClass('d-none').slideDown();
      A1.seatmap.setupMap();
    }
  });
}
A1.setupAddComps = function() {
  if ($('body#vouchers_new').length) { // only do these bindings on "Add Comps" page
    $('#add_comps_form').on('change', '#comp_order_showdate_id', A1.getSeatingOptionsForAddComps);
  }
}

$(A1.setupAddComps);
