A1.showSeatmapForHouseSeats = function() {
  // triggered when seatmap displayed for house seat selection in create/edit perf view
  // get the seatmap based on the ID selected in the dropdown
  var seatmapUrl = '/ajax/raw_seatmap/' + $('#showdate_seatmap_id').val();
  $.getJSON(seatmapUrl, A1.setupSeatmapForHouseSeats);
};

A1.setupSeatmapForHouseSeats = function(jsonData) {
  A1.seatmap.configureFrom(jsonData);
  A1.seatmap.max = 99999;       // infinity
  $('#seating-charts-wrapper').removeClass('d-none').slideDown();
  A1.seatmap.seats = $('#seatmap').seatCharts(A1.seatmap.settings);
  A1.seatmap.setupMap();
}
