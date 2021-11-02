A1.ticketSalesImport = {
  showMap: function(evt) {
    var choose = $(this);
    var container = choose.closest('.import-row');
    var showdateID = container.find('.showdate-id').val();
    var selectedSeats = container.find('.seat-display');
    var voucherIds = container.find('.voucher-ids');
    var chooseSeats = $('.select-seats');
    var confirm = container.find('.confirm-seats');
    var submit = $('#submit');

    function seatsStillToAssign() {
      var stillToAssign = false;
      $('.seat-display').each(function() {
        if ($(this).val() == '') {
          stillToAssign = true;
        }
      });
      return(stillToAssign);
    }

    function resetPage() {
      $('#seating-charts-wrapper').slideUp().addClass('d-none');
      $('.tbody-import').append($('#seatmap-table-row'));
      chooseSeats.prop('disabled', false);
      confirm.addClass('d-none');
      choose.removeClass('d-none');
      // only enable Submit button when all seats have been assigned
      submit.prop('disabled', seatsStillToAssign());
    };

    function assignSeatsFailed(jqXHR, textStatus, errorString) {
      selectedSeats.val('');    // ensure we don't actually try to select seats
      alert(textStatus + ': ' + jqXHR.responseText);
    }
    function assignSeats() {
      $.ajax({
        method: 'POST',
        url: '/ajax/import_assign_seats', 
        timeout: 30000,
        data: {
          seats: A1.seatmap.selectedSeatsAsString,
          vouchers: voucherIds.val()
        },
        error: assignSeatsFailed
      });
      resetPage();
    }


    evt.preventDefault();
    // move the hidden table row to just below our own, and reveal it
    $('#seatmap-table-row').insertAfter(container);
    $('#seating-charts-wrapper').removeClass('d-none').slideDown();
     
    // once seat selection begins, must choose all seats for this order, OR cancel,
    // before can choose seats for another order
    chooseSeats.prop('disabled', true);
    choose.addClass('d-none'); 

    // ensure attach exactly 1 onlick event, rather than adding a new one each time this is called
    confirm.removeClass('d-none').off().on('click',assignSeats); 

    A1.seatmap.max = Number(container.find('.num-seats').val());
    A1.seatmap.resetAfterCancel = function() {
      selectedSeats.val('');
      A1.seatmap.selectedSeatsAsString = '';
      assignSeats();            // cause the vouchers to "un-assign" seat numbers
    };
    A1.seatmap.onSelect = function() {
      // console.log("====selecting: " + A1.seatmap.selectedSeatsAsString);
      selectedSeats.val(A1.seatmap.selectedSeatsAsString);
      chooseSeats.prop('disabled', true);
      confirm.prop('disabled', true);
    };
    A1.seatmap.allSeatsSelected = function() {
      // console.log("=== enabling Confirm");
      if (! (confirm.prop('disabled'))) {
        throw('Should not be enabled!');
      }
      confirm.prop('disabled', false);
    };
    var uri = encodeURI('/ajax/seatmap/' + showdateID + '?selected=' + selectedSeats.val());
    $.getJSON(uri,
              function(json_data) {
                A1.seatmap.configureFrom(json_data);
                A1.seatmap.seats = $('#seatmap').seatCharts(A1.seatmap.settings);
                A1.seatmap.setupMap();
              });
  }
  ,setup: function() {
    if ($('body#ticket_sales_imports_edit').length > 0 // imports page
        && ($('.select-seats').length > 0)) { // reserved seating for this import
      $('.select-seats').on('click', A1.ticketSalesImport.showMap);
      $('#submit').prop('disabled', true); // until all seats selected
    }
  }
};

$(A1.ticketSalesImport.setup);
