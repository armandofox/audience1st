A1.seatmap = {
  selectedSeats: []
  ,unavailable: []
  ,max: 0
  ,seats: null
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
    }
  }
  // Link/button that makes seatmap appear has a "data-showdate-id" attribute that will
  // be used to fetch seatmap JSON and list of unavailable seats as JSON array
  ,showSeatmapForShowdate: function(evt) {
    evt.preventDefault();
    // extract number of tickets to reserve and showdate_id from neighboring elements
    var container = $(this).closest('.row');
    var numTickets = container.find('.num_tickets').val();
    var showdateID = container.find('.showdate').val();
    var url = '/ajax/seatmap/' + showdateID;
    // get the seatmap and unavailable seats for this showdate
    $.getJSON(url, function(json_data) { 
      A1.seatmap.max = parseInt(numTickets);
      A1.seatmap.settings.map = json_data.map;
      A1.seatmap.unavailable = json_data.unavailable;
      A1.seatmap.seats = $('#seatmap').seatCharts(A1.seatmap.settings);
      $('#seatmap').removeClass('invisible');
      A1.seatmap.setup();
    });
  }
  ,setup: function() {
    A1.seatmap.unselectAll();
    A1.seatmap.centerMap();
    A1.seatmap.refreshLegend();
    A1.seatmap.unavailable.forEach(function(seat_num) {
      A1.seatmap.seats.status(seat_num, 'unavailable');
    });
    $('#seatmap')[0].addEventListener('click', A1.seatmap.refreshLegend);
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
  ,refreshLegend: function() {
    // refresh Done/Cancel button state
    $('#your-seats').text(A1.seatmap.selectedSeats.join(', '));
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
