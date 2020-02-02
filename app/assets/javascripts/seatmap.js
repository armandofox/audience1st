A1.seatmap = {
  selectedSeats: []
  ,enclosingSelector: ''
  ,unavailable: []
  ,max: 0
  ,seats: null
  ,onSelect: null
  ,allSeatsSelected: null
  ,resetAfterCancel: null
  ,url: null
  ,settings: {
    seats: {}
    ,map: []
    ,naming: { top: false, left: false }
    ,legend: {          // can't set statically above, since relies on character keys in items hash to be defined as local vars - ugh
      items: [
        ['r', 'available', 'Available'],
        ['a', 'available', 'Available accessible']
      ]
    }
    ,click: function(evt) {
      var seatNum = this.settings.id;
      switch(this.status()) {
      case 'available':           // clicking on available seat selects it...
        if (A1.seatmap.selectedSeats.length < A1.seatmap.max) { // ...if still seats to select
          if (this.settings.character == "a") { // accessible seat: show warning
            alert($('#accessibility_advisory_for_reserved_seating').val());
          }
          A1.seatmap.selectedSeats.push(seatNum);
          A1.seatmap.selectedSeatsAsString = A1.seatmap.selectedSeats.sort().join(', ');
          A1.seatmap.onSelect.call(seatNum);
          if (A1.seatmap.selectedSeats.length == A1.seatmap.max) {
            A1.seatmap.allSeatsSelected.call();
          }
          return('selected');
        } else {
          return('available');
        }
      case 'selected':            // clicking on selected seat unselects it
        var idx = A1.seatmap.selectedSeats.indexOf(seatNum);
        A1.seatmap.selectedSeats.splice(idx,1);
        A1.seatmap.selectedSeatsAsString = A1.seatmap.selectedSeats.sort().join(', ');
        A1.seatmap.onSelect.call(seatNum);
        return('available');
      case 'unavailable':         // clicking on unavailable (taken) seat is ignored
        return('unavailable');
        break;
      default:
        return this.style();
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
    A1.seatmap.resetAfterCancel.call();
  }
  ,selectCountPrompt: function() {
    var ct = A1.seatmap.max - A1.seatmap.selectedSeats.length;
    switch(ct) {
    case 0: return("All Seats Selected");
    case 1: return("Choose 1 Seat...");
    default: return('Choose ' + ct + ' Seats...');
    }
  }
  ,showSeatmapForPreviewOnly: function(evt) {
    // un-hilite all "Preview" buttons, then re-hilite us
    $('.preview').removeClass('active');
    $(this).addClass('active');
    evt.preventDefault();
    var seatmapId = $(this).data('seatmap-id');
    A1.seatmap.configureFrom(A1.seatmaps[seatmapId]);
    A1.seatmap.max = 0;         // don't allow seat selection
    A1.seatmap.allSeatsSelected = function() {};
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
    A1.seatmap.onSelect = function(seatNum) {
      $('.show-seatmap').html(A1.seatmap.selectCountPrompt);      // update "Select N seats" prompt
      $('.seat-display').val(A1.seatmap.selectedSeatsAsString); // display seats selected so far
      $('#submit').prop('disabled', true);
      }
    A1.seatmap.allSeatsSelected = function() {
      $('#submit').prop('disabled', false); // allow cart submission
      $('.show-seatmap').prop('disabled', true);
    }
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
    $(window).resize(A1.seatmap.centerMap);
    // floating "tooltips" that show each seat number on hover
    $('.seatCharts-seat').each(function(index) {
      var id = $(this).attr('id');
      if ((typeof(id) != 'undefined')  &&  (id != '')) {
        $(this).attr('data-seatnum', id);
      }
    });
  }
  // Refresh list of chosen seats
  // Update prompt "select N seats"
  // Disable or hide "proceed" button
  // Disable or hide "Select Seats..." button
  ,centerMap: function() {
    // mandate a min-width on the seatmap container
    var screenWidth = $('#seating-charts-wrapper').width(); // computed width of container (should fill window)
    var seatWidth = $('div.seatCharts-cell').width();
    // CAUTION: because Firefox doesn't properly return the css 'margin' property (it returns
    // an empty string), the following 2 lines assume the left and right margins are the
    // same for div.seatCharts-cell and #seating-charts-wrapper.
    var seatMargin = parseInt($('div.seatCharts-cell').css('margin-left')); // eg "1px" => 1
    var mapMargin = parseInt($('#seating-charts-wrapper').css('margin-left'));
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
  ,setupReservations: function() {
    if ($('body#customers_show').length > 0) { // only do these bindings on "My Tickets" page
      // when a showdate is selected, show either "Select seats" button or "Confirm" button (for Gen Adm)
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
    var showdateID = $('#comp_order_showdate_id').val();
    var resetAfter = function() {
      $('#seating-charts-wrapper').addClass('d-none');
      $('#comp_order_howmany').prop('readonly', false); // allow changing ticket count
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
        A1.seatmap.max = Number($('#comp_order_howmany').val());
        $('#comp_order_howmany').prop('readonly', true); // still submits as part of form, but can't change
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
      $('#add_comps_form').on('change', '#comp_order_showdate_id', A1.seatmap.getSeatingOptionsForAddComps);
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
  ,setupWalkupSalesPreview: function() {
    if ($('#static-seatmap').length) {
      A1.seatmap.configureFrom(JSON.parse($('#seatmap_info').val()));
      A1.seatmap.seats = $('#seatmap').seatCharts(A1.seatmap.settings);
      $('#seating-charts-wrapper').removeClass('d-none');
      A1.seatmap.setupMap("passive");
      // cancel button can be hidden
      $('.seat-select-cancel').hide();
    }
  }
};

// at most one of the these Ready functions will actually do anything.
$(A1.seatmap.setupReservations);
$(A1.seatmap.setupRegularSales);
$(A1.seatmap.setupSeatmapEditor);
$(A1.seatmap.setupAddComps);
$(A1.seatmap.setupWalkupSalesPreview);
