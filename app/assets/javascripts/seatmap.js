A1.seatmap = {
  selectedSeats: []
  ,enclosingSelector: ''
  ,unavailable: []
  ,max: 0
  ,seats: null
  ,onSelect: null
  ,allSeatsSelected: null
  ,resetAfterCancel: null
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

};

