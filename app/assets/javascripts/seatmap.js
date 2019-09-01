A1.seatmap = {
  selectedSeats: []
  ,enclosingSelector: ''
  ,unavailable: []
  ,max: 0
  ,seats: null
  ,seatDisplayField: null
  ,confirmSeatsButton: null
  ,selectSeatsButton: null
  ,url: null
  ,settings: {
    seats: {}
    ,map: []
    ,naming: { top: false, left: false }
    ,click: function(evt) {
      switch(this.status()) {
      case 'available':           // select seat
        if (A1.seatmap.selectedSeats.length < A1.seatmap.max) {
          if (this.settings.character == "a") { // accessible seat: show warning
            alert($('#accessibility_advisory_for_reserved_seating').val());
          }
          A1.seatmap.select(this);
          return('selected');
        } else {
          return('available');
        }
      case 'selected':            // unselect seat
        A1.seatmap.unselect(this);
        return('available');
      case 'unavailable':         // ignore; seat is taken
        return('unavailable');
        break;
      }
      // update display
      if (A1.seatmap.seatDisplayField) {
        A1.seatmap.seatDisplayField.html(A1.seatmap.selectedSeats.join(','));
      }
    }
  }
  ,findDomElements: function(container) {
    // various important DOM elements, either for retrieving a value or modifying the
    // display, are relative to the enclosing container (since multiple such containers
    // may appear on the My Tickets page).
    // move the seatmap's display frame to just below this enclosing container
    $('#seating-charts-wrapper').
      insertAfter(container).
      removeClass('d-none').
      slideDown();
    // num seats to select
    var numSeatsMenu = container.find('.number');
    A1.seatmap.max = parseInt(numSeatsMenu.val());
    numSeatsMenu.prop('disabled', 'disabled');
    // where to display seats chosen so far, Confirm button, Select More Seats button
    A1.seatmap.seatDisplayField = container.find('.seat-display');
    A1.seatmap.confirmSeatsButton = container.find('.confirm-seats');
    A1.seatmap.selectSeatsButton = container.find('.show-seatmap');
    // URL to retrieve seatmap and unavailable seat info
    A1.seatmap.url = '/ajax/seatmap/' + container.find('.showdate').val();
  }
  ,showSeatmapForShowdateReservation: function(evt) {
    evt.preventDefault();
    A1.seatmap.findDomElements($(this).closest(A1.seatmap.enclosingSelector));
    // get the seatmap and list of unavailable seats for this showdate
    $.getJSON(A1.seatmap.url, function(json_data) { 
      A1.seatmap.configureFrom(json_data);
      A1.seatmap.seats = $('#seatmap').seatCharts(A1.seatmap.settings);
      A1.seatmap.setupMap();
    });
  }
  ,configureFrom: function(j) {
    A1.seatmap.settings.map = j.map; // the actual seat map
    A1.seatmap.settings.seats = j.seats; // metadata for seat types
    A1.seatmap.unavailable = j.unavailable; // list of unavailable seats
  }
  ,showSeatmapForShowdateRegularSales: function(evt) {
    // triggered when "Select Seats" is clicked, so disable default submit action on button
    evt.preventDefault();
    // if this show has a seatmap, the info is ALREADY ON THE PAGE as a hidden form field
    A1.seatmap.configureFrom(JSON.parse($('#seatmap_info').val()));
    A1.seatmap.max = A1.orderState.ticketCount;
    A1.seatmap.seatDisplayField = $('.seat-display');
    A1.seatmap.selectSeatsButton = $('.show-seatmap');
    A1.seatmap.confirmSeatsButton = $('#submit');
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
  ,setupMap: function() {
    A1.seatmap.unselectAll();
    A1.seatmap.centerMap();
    A1.seatmap.updateUI();
    A1.seatmap.unavailable.forEach(function(seat_num) {
      A1.seatmap.seats.status(seat_num, 'unavailable');
    });
    $('#seatmap')[0].addEventListener('click', A1.seatmap.updateUI);
    document.addEventListener('resize', A1.seatmap.centerMap);
    // floating "tooltips" that show each seat number on hover
    $('.seatCharts-seat').each(function(index) {
      $(this).attr('title', $(this).attr('id'));
    });
  }
  ,select: function(seat) {
    var seatNum = seat.settings.id;
    A1.seatmap.selectedSeats.push(seatNum);
  }
  ,unselectAll: function() {
    A1.seatmap.seats.status(A1.seatmap.selectedSeats,'available');
    A1.seatmap.selectedSeats = [];
  }
  ,unselect: function(seat) {
    var seatNum = seat.settings.id;
    var idx = A1.seatmap.selectedSeats.indexOf(seatNum);
    A1.seatmap.selectedSeats.splice(idx,1);
  }
  ,updateUI: function() {
    // refresh display of which seats chosen so far
    A1.seatmap.seatDisplayField.val(A1.seatmap.selectedSeats.sort().join(', '));
    // if exact # seats selected, allow proceed
    if (A1.seatmap.selectedSeats.length == A1.seatmap.max) {
      A1.seatmap.confirmSeatsButton.removeClass('d-none');
      A1.seatmap.selectSeatsButton.addClass('d-none');
    } else {
      A1.seatmap.confirmSeatsButton.addClass('d-none');
      A1.seatmap.selectSeatsButton.removeClass('d-none');
    }      
  }
  ,centerMap: function() {
    var mapWidth = $('#seatmap').width(); // computed width
    var left = ($('#seating-charts-wrapper').width() - mapWidth) / 2;
    $('#seating-charts-wrapper img.seating-charts-overlay').css({"left": left+55});
    $('#seatmap').css({"left": left});
    $('#seating-charts-wrapper').height($('#seatmap').height());
  }
  // triggered whenever showdate dropdown menu changes
  ,getSeatingOptionsForSubscriberReservation: function() {
    var container = $(this).closest(A1.seatmap.enclosingSelector); // the enclosing element that contains the relevant form fields
    var showdateId = parseInt($(this).val());
    var showdatesWithReservedSeating = JSON.parse($('#showdates_with_reserved_seating').val());
    if (showdatesWithReservedSeating.indexOf(showdateId) !== -1) {
      $(container).find('.reserved-seating').removeClass('d-none');
      $(container).find('.general-seating').addClass('d-none');
    } else {
      $(container).find('.general-seating').removeClass('d-none');
      $(container).find('.reserved-seating').addClass('d-none');
    }
    // in any case, clear out seat info from previous selection
    $(container).find('.seat-display').val('')
    // in any case, hide seat map in case it was shown before from previous selection
    $('#seating-charts-wrapper').slideUp().addClass('d-none');
  }
  ,setupReservations: function() {
    if ($('body#customers_show').length > 0) { // only do these bindings on "My Tickets" page
      // when a showdate is selected, show either "Select seats" button or "Confirm" button (for Gen Adm)
      A1.seatmap.enclosingSelector = '.form-row';
      $('select.showdate').change(A1.seatmap.getSeatingOptionsForSubscriberReservation);
      $(document).on('click', '.show-seatmap', A1.seatmap.showSeatmapForShowdateReservation);
      // updating staff comments field (form-remote)
      $('.save_comment').on('ajax:success', function() { alert("Comment saved") });
      $('.save_comment').on('ajax:error', function() { alert("Error, comment NOT saved") });
    }
  }
  ,getSeatingOptionsForRegularSales: function() {
    // triggered whenever the count of selected seats changes.
    // If nonzero number of seats is selected, enable "choose seats" button.
    if (A1.orderState.ticketCount > 0) {
      $('.show-seatmap').prop('disabled', false);
    }
  }
  ,setupRegularSales: function() {
    if ($('body#store_index').length) {  // only do these bindings on "Buy Tickets" page
      // when quantities change (triggering price recalc), determine whether to 
      // show reserved seating controls and hide general seating controls, or vice versa
      A1.seatmap.enclosingSelector = '#ticket_menus';
      $('.ticket').change(A1.seatmap.getSeatingOptionsForRegularSales);
      $('.show-seatmap').click(A1.seatmap.showSeatmapForShowdateRegularSales);
    }
  }
  ,setupWalkupSales: function() {
    // bindings only for Walkup Sales page
  }
};

// at most one of the three Ready functions will actually do anything.
$(A1.seatmap.setupReservations);
$(A1.seatmap.setupRegularSales);
$(A1.seatmap.setupWalkupSales);

