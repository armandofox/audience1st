A1.seatmap = {
  selectedSeats: []
  ,unavailable: []
  ,max: 0
  ,seats: null
  ,seatDisplayField: null
  ,url: null
  ,settings: {
    seats: {}
    ,map: []
    ,naming: { top: false, left: false }
    ,click: function(evt) {
      switch(this.status()) {
      case 'available':           // select seat
        A1.seatmap.select(this);
        return('selected');
      case 'selected':            // unselect seat
        A1.seatmap.unselect(this);
        return('available');
      case 'unavailable':         // ignore; seat is taken
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
      removeClass('invisible').
      slideDown();
    // num seats to select
    A1.seatmap.max = parseInt(container.find('.num_tickets').val());
    // where to display seats chosen so far
    A1.seatmap.seatDisplayField = container.find('.seat-display'); 
    // URL to retrieve seatmap and unavailable seat info
    A1.seatmap.url = '/ajax/seatmap/' + container.find('.showdate').val();
  }
  ,showSeatmapForShowdate: function(evt) {
    evt.preventDefault();
    A1.seatmap.findDomElements($(this).closest('.row'));
    // get the seatmap and list of unavailable seats for this showdate
    $.getJSON(A1.seatmap.url, function(json_data) { 
      A1.seatmap.settings.map = json_data.map;
      // list of already-taken seats
      A1.seatmap.unavailable = json_data.unavailable;
      A1.seatmap.seats = $('#seatmap').seatCharts(A1.seatmap.settings);
      A1.seatmap.setup();
    });
  }
  ,setup: function() {
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
    if (A1.seatmap.selectedSeats.length > A1.seatmap.max-1) {
      var vacate = A1.seatmap.selectedSeats.shift();
      A1.seatmap.seats.status(vacate, 'available');
    }
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
    // refresh Done/Cancel button state
    A1.seatmap.seatDisplayField.val(A1.seatmap.selectedSeats.sort().join(', '));
    // if exact # seats selected, allow proceed
    if (A1.seatmap.selectedSeats.length == A1.seatmap.max) {
      $('#confirm-seats').removeClass('disabled');
    } else {
      $('#confirm-seats').addClass('disabled');
    }      
  }
  ,centerMap: function() {
    var mapWidth = $('#seatmap').width(); // computed width
    var left = ($('#seating-charts-wrapper').width() - mapWidth) / 2;
    $('#seating-charts-overlay').width(mapWidth);
    $('#seatmap').css({"left": left});
    $('#seating-charts-wrapper').height($('#seatmap').height());
  }
};
