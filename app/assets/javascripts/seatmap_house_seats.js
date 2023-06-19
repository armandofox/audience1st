
A1.showSeatmapForHouseSeats = function() {
  var seatmapUrl;
  if ($('body#showdates_new').length > 0) {
    // if CREATING new perf(s), show raw seatmap for choosing house seats
    seatmapUrl = '/ajax/raw_seatmap/' + $('#showdate_seatmap_id').val();
  } else {
    seatmapUrl = '/ajax/house_seats_seatmap/' + $('#showdate_id').val();
  }
  $.getJSON(seatmapUrl, A1.setupSeatmapForHouseSeats);
};

A1.setupSeatmapForHouseSeats = function(jsonData) {
  A1.seatmap.configureFrom(jsonData);
  A1.seatmap.max = 99999;       // infinity
  A1.seatmap.seats = $('#seatmap').seatCharts(A1.seatmap.settings);
  $('#seating-charts-wrapper').removeClass('d-none').slideDown();
  // hide the 'Cancel seat selection' button since it doesn't apply in this use case
  $('.seat-select-cancel').addClass('d-none');
  A1.seatmap.onSelect = function(seatNum) {
    $('.showdate-house-seats').val(A1.seatmap.selectedSeatsAsString);
  };
  A1.seatmap.setupMap();
}

