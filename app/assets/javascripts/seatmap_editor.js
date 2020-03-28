A1.showSeatmapForPreviewOnly = function(evt) {
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
};

A1.setupSeatmapEditor = function() {
  // bindings only for Seatmap Editor
  if ($('body#seatmaps_index').length > 0) {
    $('.preview').click(A1.showSeatmapForPreviewOnly);
  }
}

$(A1.setupSeatmapEditor);
