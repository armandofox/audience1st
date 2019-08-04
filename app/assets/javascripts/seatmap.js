A1.seatmap = {
  seats: null,
  selectedSeats: [],
  max: 0,
  settings: {
    map: {}
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
    A1.seatmap.selected_seats = [];
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
  ,setup: function() {
    A1.seatmap.seats = $('#seatmap').seatCharts(A1.seatmap.settings);
    A1.seatmap.max = parseInt($('#num_seats').val());
    A1.seatmap.unselectAll();
    A1.seatmap.centerMap();
    A1.seatmap.refreshLegend();
    $('#seatmap')[0].addEventListener('click', A1.seatmap.refreshLegend);
    document.addEventListener('resize', A1.seatmap.centerMap);
    $('#num_seats').change(A1.seatmap.setup);
    $('.seatCharts-seat').each(function(index) {
      $(this).attr('title', $(this).attr('id'));
    });
  }
};

$(A1.seatmap.setup);
