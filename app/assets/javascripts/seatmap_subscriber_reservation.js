// triggered whenever showdate dropdown menu changes on subscriber reservations screen
A1.getSeatingOptionsForSubscriberReservation = function() {
  var container = $(this).closest('.form-row'); // the enclosing element that contains the relevant form fields
  var confirmButton = container.find('.confirm-seats');
  var specialSeating = container.find('.special-seating');
  var selectedSeats = container.find('.seat-display');
  var showdateId = Number($(this).val());
  var showdateMenu = $(this)[0];
  var showdatesWithReservedSeating = JSON.parse($('#showdates_with_reserved_seating').val());

  // first, disable ALL other showdate rows on page (so disable all, then re-enable us)
  $('.confirm-seats').prop('disabled', true);
  $('.special-seating').addClass('invisible');

  // now selectively re-display stuff in our own container
  specialSeating.removeClass('invisible');    // show 'special seating needs' field for both G/A and R/S showdates
  selectedSeats.val(''); //  clear seat info from previous selection
  // in any case, hide seat map in case it was shown before from previous selection
  $('#seating-charts-wrapper').slideUp().addClass('d-none');

  if (showdatesWithReservedSeating.indexOf(showdateId) == -1) {
    // general admission show
    confirmButton.prop('disabled', false);
  } else {
    // reserved seating: hide 'Confirm' button, and show seatmap for the div we are in
    confirmButton.prop('disabled', true);
    $('#seating-charts-wrapper').insertAfter(container).removeClass('d-none').slideDown();
    // make it impossible to change # of selected seats while seat dialog active
    container.find('select.number option').prop('disabled', true);
    container.find('select.number option:selected').prop('disabled', false);
    A1.seatmap.max = Number(container.find('.number').val());
    A1.seatmap.onSelect = function() {
      selectedSeats.val(A1.seatmap.selectedSeatsAsString);
      confirmButton.prop('disabled', true);
    }
    A1.seatmap.allSeatsSelected = function() {
      confirmButton.prop('disabled', false);
    }
    A1.seatmap.resetAfterCancel = function() {
      selectedSeats.val('');
      showdateMenu.selectedIndex = 0;        // reset showdate menu to "Select..."
      confirmButton.prop('disabled', true); // disable 'Confirm' button
      specialSeating.addClass('invisible'); // hide 'Special seating needs' comment field
    };
    // get the seatmap and list of unavailable seats for this showdate
    $.getJSON('/ajax/seatmap/' + showdateId.toString(), function(json_data) { 
      A1.seatmap.configureFrom(json_data);
      A1.seatmap.seats = $('#seatmap').seatCharts(A1.seatmap.settings);
      A1.seatmap.setupMap();
    });
  }
}

A1.setupReservations = function() {
  if ($('body#customers_show').length > 0) { // only do these bindings on "My Tickets" page
    // when a showdate is selected, show either "Select seats" button or "Confirm" button (for Gen Adm)
    $('select.showdate').change(A1.getSeatingOptionsForSubscriberReservation);
    // updating staff comments field (form-remote)
    $('.save_comment').on('ajax:success', function() { alert("Comment saved") });
    $('.save_comment').on('ajax:error', function() { alert("Error, comment NOT saved") });
  }
}

$(A1.setupReservations);
