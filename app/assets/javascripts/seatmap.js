A1.seatmap = {
  selectedSeats: []
  ,enclosingSelector: ''
  ,unavailable: []
  ,max: 0
  ,seats: null
  ,seatDisplayField: null
  ,confirmSeatsButton: null
  ,selectSeatsButton: null
  ,resetAfterCancel: null
  ,url: null
  ,settings: {
    seats: {}
    ,map: []
    ,naming: { top: false, left: false }
    ,legend: {          // can't set statically above, since relies on character keys in items hash to be defined as local vars - ugh
      items: [
        ['r', 'available', 'Open'],
        ['a', 'available', 'Open, accessible']
      ]
    }
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
    // make it impossible to change # of selected seats while seat dialog active
    container.find('select.number option').prop('disabled', true);
    container.find('select.number option:selected').prop('disabled', false);
    A1.seatmap.max = Number(container.find('.number').val());
    // where to display seats chosen so far, Confirm button, Select More Seats button
    A1.seatmap.seatDisplayField = container.find('.seat-display');
    A1.seatmap.confirmSeatsButton = container.find('.confirm-seats');
    A1.seatmap.selectSeatsButton = container.find('.show-seatmap');
    // URL to retrieve seatmap and unavailable seat info
    A1.seatmap.url = '/ajax/seatmap/' + container.find('.showdate').val();
  }
  ,configureFrom: function(j) {
    $('#seatmap').removeData('seatCharts'); // flush old data
    $('#seatmap').html('');
    $('.seatCharts-legend').html('');
    A1.seatmap.settings.legend.node = $('.legend-container .legend');
    A1.seatmap.settings.map = j.map; // the actual seat map
    A1.seatmap.settings.seats = j.seats; // metadata for seat types
    A1.seatmap.unavailable = j.unavailable; // list of unavailable seats
    A1.seatmap.columns = j.columns;         // determines minimum displaywidth
    // set background image
    $('img.seating-charts-overlay').attr('src', j.image_url);
    // bind Cancel button
    $('.seat-select-cancel').click(A1.seatmap.cancel);
  }
  ,cancel: function(evt) {
    evt.preventDefault();
    // hide seatmap
    $('#seating-charts-wrapper').slideUp().addClass('d-none');
    // cancel all seat selections, then delegate to screen-specific cancellation
    A1.seatmap.selectedSeats = [];
    // erase any text showing selected seats
    if (A1.seatmap.seatDisplayField) {
      A1.seatmap.seatDisplayField.val('');
    }
    // call screen-specific cancellation function
    if (A1.seatmap.resetAfterCancel) {
      A1.seatmap.resetAfterCancel.call();
    }
  }
  ,selectCountPrompt: function() {
    var ct = A1.seatmap.max - A1.seatmap.selectedSeats.length;
    return('Choose ' + ct + ' Seat' + (ct > 1 ? 's' : '') + ' ...');
  }
  ,showSeatmapForPreviewOnly: function(evt) {
    // un-hilite all "Preview" buttons, then re-hilite us
    $('.preview').removeClass('active');
    $(this).addClass('active');
    evt.preventDefault();
    var seatmapId = $(this).data('seatmap-id');
    A1.seatmap.configureFrom(A1.seatmaps[seatmapId]);
    A1.seatmap.max = 0;         // don't allow seat selection
    A1.seatmap.seats = $('#seatmap').seatCharts(A1.seatmap.settings);
    $('#seating-charts-wrapper').removeClass('d-none').slideDown();
    A1.seatmap.setupMap("passive");
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
    A1.seatmap.resetAfterCancel = function() {
      window.location.reload();
    };
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
  ,setupMap: function(passive) {
    // reset seatmap: clear out selected seats, and visually mark all seats available
    A1.seatmap.selectedSeats = [];
    A1.seatmap.seats.find('selected').status('available'); 
    A1.seatmap.seats.find('unavailable').status('available');
    // now indicate unavailable seats for this new showdate
    A1.seatmap.unavailable.forEach(function(seat_num) {
      A1.seatmap.seats.status(seat_num, 'unavailable');
    });
    A1.seatmap.centerMap();
    if (typeof(passive) == 'undefined'  ||  !passive) {
      // unless passive, seatmap should respond to clicks etc
      A1.seatmap.updateUI();
      $('#seatmap')[0].addEventListener('click', A1.seatmap.updateUI);
    }
    $(window).resize(A1.seatmap.centerMap);
    // floating "tooltips" that show each seat number on hover
    $('.seatCharts-seat').each(function(index) {
      $(this).attr('data-seatnum', $(this).attr('id'));
    });
  }
  ,select: function(seat) {
    var seatNum = seat.settings.id;
    A1.seatmap.selectedSeats.push(seatNum);
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
      A1.seatmap.confirmSeatsButton.prop('disabled', false);
      if (A1.seatmap.selectSeatsButton) {
        A1.seatmap.selectSeatsButton.prop('disabled', true);
      }
    } else {
      // change button label to be prompt for how many seats to select
      $('.show-seatmap').html(A1.seatmap.selectCountPrompt);
      // disable Confirm; show but disable SelectSeats
      A1.seatmap.confirmSeatsButton.prop('disabled', true);
      if (A1.seatmap.selectSeatsButton) {
        A1.seatmap.selectSeatsButton.prop('disabled', true);
      }
    }      
  }
  ,centerMap: function() {
    // mandate a min-width on the seatmap container
    var screenWidth = $('#seating-charts-wrapper').width(); // computed width of container (should fill window)
    var seatWidth = $('div.seatCharts-cell').width();
    var seatMargin = parseInt($('div.seatCharts-cell').css('margin')); // eg "1px" => 1
    var mapMargin = parseInt($('#seating-charts-wrapper').css('margin'));
    var slop = 6;               // slop added to width to ensure rows don't wrap
    var left = 0;
    var seatmapHeight = $('#seatmap').height();
    var seatmapWidth = A1.seatmap.columns * (seatWidth + 2*seatMargin) +  (2*mapMargin);
    // enforce seatmap min width based on # of cols
    $('#seating-charts-wrapper').css('min-width', (slop + seatmapWidth).toString() + 'px');
    // if window wider than map, center map
    if (screenWidth > slop + seatmapWidth) {
      left = (screenWidth - seatmapWidth) / 2;
    } 
    var legend = $('.legend-container');
    $('#seating-charts-wrapper').height(legend.height() +
                                        parseInt(legend.css('padding-top')) +
                                        seatmapHeight);
    // always scale background image to match seatmap width.  image is expected to have
    // correct aspect ratio so vertical scaling will take care of itself.
    $('img.seating-charts-overlay').css({"left": left, "width": seatmapWidth - 4});
    $('#seatmap').css({"left": left});
    // reposition the legend as well
    $('.legend-container').css({"left": left, "top": 2 + seatmapHeight, "width": seatmapWidth - 4});
  }
  // triggered whenever showdate dropdown menu changes
  ,getSeatingOptionsForSubscriberReservation: function() {
    // first, disable ALL other showdate rows on page (so disable all, then re-enable us)
    $('.confirm-seats').prop('disabled', true);
    $('.special-seating').addClass('invisible');
    var container = $(this).closest(A1.seatmap.enclosingSelector); // the enclosing element that contains the relevant form fields
    var showdateId = Number($(this).val());
    var showdateMenu = $(this)[0];
    var showdatesWithReservedSeating = JSON.parse($('#showdates_with_reserved_seating').val());
    // show 'special seating needs' field for both G/A and R/S showdates
    container.find('.special-seating').removeClass('invisible');
    // in any case, clear out seat info from previous selection
    container.find('.seat-display').val('');
    // in any case, hide seat map in case it was shown before from previous selection
    $('#seating-charts-wrapper').slideUp().addClass('d-none');

    if (showdatesWithReservedSeating.indexOf(showdateId) == -1) {
      // general admission show
      container.find('.confirm-seats').prop('disabled', false);
    } else {
      // reserved seating: hide 'Confirm' button, and show seatmap for the div we are in
      container.find('.confirm-seats').prop('disabled', true);
      A1.seatmap.findDomElements($(this).closest(A1.seatmap.enclosingSelector));
      // get the seatmap and list of unavailable seats for this showdate
      A1.seatmap.resetAfterCancel = function() {
        // reset showdate menu to "Select..."
        showdateMenu.selectedIndex = 0;
        // hide 'Confirm' button
        container.find('.confirm-seats').prop('disabled', true);
      };
      $.getJSON(A1.seatmap.url, function(json_data) { 
        A1.seatmap.configureFrom(json_data);
        A1.seatmap.seats = $('#seatmap').seatCharts(A1.seatmap.settings);
        A1.seatmap.setupMap();
      });
    }
  }
  ,setupReservations: function() {
    if ($('body#customers_show').length > 0) { // only do these bindings on "My Tickets" page
      // when a showdate is selected, show either "Select seats" button or "Confirm" button (for Gen Adm)
      A1.seatmap.enclosingSelector = '.form-row';
      $('select.showdate').change(A1.seatmap.getSeatingOptionsForSubscriberReservation);
      // updating staff comments field (form-remote)
      $('.save_comment').on('ajax:success', function() { alert("Comment saved") });
      $('.save_comment').on('ajax:error', function() { alert("Error, comment NOT saved") });
    }
  }
  ,getSeatingOptionsForRegularSales: function() {
    // triggered whenever the count of selected seats changes.
    // If nonzero number of seats is selected, enable "choose seats" button.
    var ct = A1.orderState.ticketCount;
    if (ct > 0) {
      $('.show-seatmap').prop('disabled', false);
    }
  }
  ,getSeatingOptionsForAddComps: function() {
    // triggered when a new perf is selected during Add Comps flow
    var showdateID = $('#showdate_id').val();
    var resetAfter = function() {
      $('#seating-charts-wrapper').addClass('d-none');
      $('#howmany').prop('readonly', false); // allow changing ticket count
      $('.seat-display').addClass('d-none');
      $('.confirm-seats').prop('disabled', false);
    }
    // if it's not a valid showdate, do nothing:
    if (showdateID == '' ||  isNaN(showdateID) )  {
      resetAfter();
      return;
    }
    $.getJSON('/ajax/seatmap/' + showdateID, function(jsonData) {
      if (jsonData.map == null) { 
        resetAfter();
      } else {
        A1.seatmap.resetAfterCancel = resetAfter;
        A1.seatmap.confirmSeatsButton = $('.confirm-seats');
        A1.seatmap.configureFrom(jsonData); // setup unavailable seats, etc
        A1.seatmap.max = Number($('#howmany').val());
        $('#howmany').prop('readonly', true); // still submits as part of form, but can't change
        A1.seatmap.seatDisplayField = $('.seat-display').removeClass('d-none');
        A1.seatmap.seats = $('#seatmap').seatCharts(A1.seatmap.settings);
        $('#seating-charts-wrapper').removeClass('d-none').slideDown();
        A1.seatmap.setupMap();
      }
    });
  }
  ,setupAddComps: function() {
    if ($('body#vouchers_new').length) { // only do these bindings on "Add Comps" page
      A1.seatmap.enclosingSelector = '#add_comps_form';
      $('#add_comps_form').on('change', '#showdate_id', A1.seatmap.getSeatingOptionsForAddComps);
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
  ,setupSeatmapEditor: function() {
    // bindings only for Seatmap Editor
    if ($('body#seatmaps_index').length) {
      $('.preview').click(A1.seatmap.showSeatmapForPreviewOnly);
    }
  }
};

// at most one of the these Ready functions will actually do anything.
$(A1.seatmap.setupReservations);
$(A1.seatmap.setupRegularSales);
$(A1.seatmap.setupSeatmapEditor);
$(A1.seatmap.setupAddComps);

