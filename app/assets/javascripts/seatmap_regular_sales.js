A1.showSeatmapForShowdateRegularSales = function(evt) {
    // triggered when "Select Seats" is clicked, so disable default submit action on button
    evt.preventDefault();
    // if this show has a seatmap, the info is ALREADY ON THE PAGE as a hidden form field
    A1.seatmap.configureFrom(JSON.parse($('#seatmap_info').val()));
    A1.seatmap.max = A1.orderState.ticketCount;
    A1.seatmap.onSelect = function(seatNum) {
      $('.show-seatmap').html(A1.seatmap.selectCountPrompt);      // update "Select N seats" prompt
      $('.seat-display').val(A1.seatmap.selectedSeatsAsString); // display seats selected so far
      $('#submit').prop('disabled', true);
      }
    A1.seatmap.allSeatsSelected = function() {
      $('#submit').prop('disabled', false); // allow cart submission
      $('.show-seatmap').prop('disabled', true);
    }
    A1.seatmap.resetAfterCancel = function() {  window.location.reload(); }
    A1.seatmap.seats = $('#seatmap').seatCharts(A1.seatmap.settings);
    $('#seating-charts-wrapper').removeClass('d-none').slideDown();
    A1.seatmap.setupMap();
    // finally, disable selection from the ticket menu(s) or field(s).  Text inputs can
    // just have readonly set; selects have all options disabled except the selected option.
    // Both hacks enable the form value to be submitted.
    $('input.ticket').prop('readonly', true);
    $('select.ticket option').prop('disabled', true);
    $('select.ticket option:selected').prop('disabled', false);
  }

A1.getSeatingOptionsForRegularSales = function() {
    // triggered whenever the count of selected seats changes.
    // If nonzero number of seats is selected, enable "choose seats" button.
    var ct = A1.orderState.ticketCount;
    if (ct > 0) {
      $('.show-seatmap').prop('disabled', false);
    }
  }

A1.setupSeatmapRegularSales = function() {
  if ($('body#store_index').length) {  // only do these bindings on "Buy Tickets" page
    // when quantities change (triggering price recalc), determine whether to 
    // show reserved seating controls and hide general seating controls, or vice versa
    $('.ticket').change(A1.getSeatingOptionsForRegularSales);
    $('.show-seatmap').click(A1.showSeatmapForShowdateRegularSales);
  }
}

$(A1.setupSeatmapRegularSales);
