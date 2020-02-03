A1.ticketSalesImport = {
  showMap: function(evt) {
    var choose = $(this);
    var container = choose.closest('.import-row');
    var showdateID = container.find('.showdate-id').val();
    var selectedSeats = container.find('.seat-display');
    var chooseSeats = $('.select-seats');
    var confirm = container.find('.confirm-seats');

    evt.preventDefault();
    // move the hidden table row to just below our own, and reveal it
    $('#seatmap-table-row').insertAfter(container);
    $('#seating-charts-wrapper').removeClass('d-none').slideDown();
     
    // clear the previous seat selection
    selectedSeats.val('');

    // once seat selection begins, must choose all seats for this order, OR cancel,
    // before can choose seats for another order
    chooseSeats.prop('disabled', true);
    choose.addClass('d-none'); 
    confirm.removeClass('d-none');
    confirm.click(A1.ticketSalesImport.confirmSeats);

    A1.seatmap.max = Number(container.find('.num-seats').val());
    A1.seatmap.resetAfterCancel = function() {
      $('.tbody-import').append($('#seatmap-table-row'));
      selectedSeats.val('');
      chooseSeats.prop('disabled', false);
      confirm.addClass('d-none');
      $(this).removeClass('d-none');
    };
    A1.seatmap.onSelect = function() {
      selectedSeats.val(A1.seatmap.selectedSeatsAsString);
      chooseSeats.prop('disabled', true);
    };
    A1.seatmap.allSeatsSelected = function() {
      confirm.prop('disabled', false);
    };
    $.getJSON('/ajax/seatmap/' + showdateID, function(json_data) {
      A1.seatmap.configureFrom(json_data);
      A1.seatmap.seats = $('#seatmap').seatCharts(A1.seatmap.settings);
      A1.seatmap.setupMap();
    });
  }
  ,confirmSeats: function() {
    alert("Woohoo!");
  }
  ,setup: function() {
    if ($('body#ticket_sales_imports_edit').length > 0) {
      $('.select-seats').on('click', A1.ticketSalesImport.showMap);
    };
  }
};

$(A1.ticketSalesImport.setup);
