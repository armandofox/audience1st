var Seatmap = {
  seats: null,
  selectedSeats: [],
  max: 0,
  settings: {
    map: Altarena.map
    ,naming: { top: false, left: false }
    ,click: function(evt) {
      switch(this.status()) {
      case 'available':           // select seat
        Seatmap.select(this);
        return('selected');
      case 'selected':            // unselect seat
        Seatmap.unselect(this);
        return('available');
      case 'unavailable':         // ignore; seat is taken
        break;
      }
    }
  }
  ,select: function(seat) {
    var seatNum = seat.settings.id;
    if (Seatmap.selectedSeats.length > Seatmap.max-1) {
      var vacate = Seatmap.selectedSeats.shift();
      Seatmap.seats.status(vacate, 'available');
    }
    Seatmap.selectedSeats.push(seatNum);
  }
  ,unselectAll: function() {
    Seatmap.seats.status(Seatmap.selectedSeats,'available');
    Seatmap.selected_seats = [];
  }
  ,unselect: function(seat) {
    var seatNum = seat.settings.id;
    var idx = Seatmap.selectedSeats.indexOf(seatNum);
    Seatmap.selectedSeats.splice(idx,1);
  }
  ,refreshLegend: function() {
    // refresh Done/Cancel button state
    $('#your-seats').text(Seatmap.selectedSeats.join(', '));
    // if exact # seats selected, allow proceed
    if (Seatmap.selectedSeats.length == Seatmap.max) {
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
    Seatmap.seats = $('#seatmap').seatCharts(Seatmap.settings);
    Seatmap.max = parseInt($('#num_seats').val());
    Seatmap.unselectAll();
    Seatmap.centerMap();
    Seatmap.refreshLegend();
    $('#seatmap')[0].addEventListener('click', Seatmap.refreshLegend);
    document.addEventListener('resize', Seatmap.centerMap);
    $('#num_seats').change(Seatmap.setup);
    $('.seatCharts-seat').each(function(index) {
      $(this).attr('title', $(this).attr('id'));
    });
  }
};

$(Seatmap.setup);
