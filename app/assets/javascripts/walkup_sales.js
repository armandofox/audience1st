// walkup sales - calculator

A1.orderState = {
  ticketCount: 0,
  totalPrice: 0.0,
  reset: function() {
    this.ticketCount = 0;
    this.totalPrice = 0.0;
  }
};

A1.show_only = function(div) {
  // force re-enabling regular form submission.  (b/c if a txn was submitted 
  // via Stripe JS and it failed, the form submit handler will still be 
  // set to block "real" submission of the form.)
  $('#_stripe_payment_form').submit(function(evt) { return true });
  $('#credit_card_payment').hide(); 
  $('#cash_payment').hide();        
  $('#check_payment').hide();       
  $('#'+div+'_payment').show();           
}

A1.recalcStoreTotal = function() {
  var total = A1.recalculate('#total', '.itemQty', 2, 'price');
  var ticketCount = A1.orderState.ticketCount;
  var totalPrice =  A1.orderState.totalPrice;
  var ready;
  $('#total').val(total.toFixed(2));
  // the submit button is either #submit.reserved or #submit.unreserved depending on whether
  // the selected performance has general or reserved seating.  The rules for whether we can
  // proceed to checkout vary depending on which one it is.

  // if UNRESERVED seating, disable 'proceed' if NO tickets wanted and NO other items
  $('#submit.unreserved').prop('disabled', (ticketCount == 0 &&  totalPrice == 0));

  // if RESERVED seating, we can proceed (skipping seat selection) if ZERO tickets are
  // selected but NONZERO total item price (ie nonticket products)...
  if (ticketCount == 0) {
    $('.show-seatmap').prop('disabled', true); // disable "select seats" button since nothing to select
    // allow proceed iff some nonzero price items are selected, since no tickets desired
    $('#submit.reserved').prop('disabled', !!(totalPrice == 0.0));
  } else if (A1.seatmap.selectedSeats.length < ticketCount) {
    // some tickets are desired, and not all seats selected, so must select seats before continue
    $('.show-seatmap').prop('disabled', false); // turn on "select seats" button
    $('#submit.reserved').prop('disabled', true); // disallow "continue to billing info"
  };
};

A1.recalcWalkupSales = function() {
  var total = A1.recalculate('#total', '.item', 2, 'price');
  var numTickets = A1.orderState.ticketCount;
  A1.recalculate('#totaltix', '.itemCount', 0);
  if (A1.seatmapWalkupSales.seatmapInfo == '') {
    // general adm:
    if (total == 0.0) {
      $('.confirm-walkup-sale').prop('disabled', true);
      if (numTickets > 0) { // no donation, but comp tickets: allow cash/0-rev purchase
        $('#submit_cash').prop('disabled', false);
      }
    } else {
      // nonzero total: enable all payment types
      $('.confirm-walkup-sale').prop('disabled', false);
    }
  } else {
    // reserved seating:
    // if nonzero # tickets selected, enable seatmap
    $('.select-seats').prop('disabled', true);
    if (numTickets > 0) {
      // disable payment buttons, enable seatmap selection
      $('.select-seats').prop('disabled', false);
      $('.confirm-walkup-sale').prop('disabled',true);
    } else if (total > 0) {
      // donation specified, but no tickets specified: enable payment button
      $('.confirm-walkup-sale').prop('disabled',false);
    }
  }
}

A1.recalculate = function(total_field,selector,decplaces,attrib) {
  A1.orderState.ticketCount = 0;
  $('.ticket').each(function() { A1.orderState.ticketCount += Number($(this).val()); });
  var tot = 0.0;
  var elts = $(selector);
  var price;
  var qty;
  elts.each(function() {
    var elt = $(this);
    if ((typeof attrib == "undefined") || 
        ((price = elt.data(attrib)) == undefined)) { 
      // if price attribute is either not given or not present,
      // the field value itself is the 'price'
      price = 1.0;
    } 
    qty = Number(elt.val());
    tot += (price * qty);
  });
  A1.orderState.totalPrice = tot;
  if (!! total_field) {
    $(total_field).val(tot.toFixed(decplaces));
  }
  return(tot);
}


A1.seatmapWalkupSales = {
  seatmapInfo: null
  ,showSeatmap: function() {
    A1.seatmap.max = A1.orderState.ticketCount;
    $('#seating-charts-wrapper').removeClass('d-none').slideDown();
    A1.seatmap.setupMap();
    // disallow changing ticket count menus while seats are being selected
    $('.item').prop('readonly', true);
    // disable "Choose Seats" button
    $('.select-seats').prop('disabled', true);
  }
  ,getSeatingOptions: function() {
    var confirmButton = $('.confirm-walkup-sale').prop('disabled',true);

    this.seatmapInfo = $('#seatmap_info').val();
    if (this.seatmapInfo == '') {
      return;
    }
    // setup for reserved seating
    $('#seatInfo').removeClass('invisible');
    $('.select-seats').click(A1.seatmapWalkupSales.showSeatmap);
    A1.seatmap.onSelect = function() {
      $('.seat-display').val(A1.seatmap.selectedSeatsAsString);
      confirmButton.prop('disabled', true);
    }
    A1.seatmap.allSeatsSelected = function() {  confirmButton.prop('disabled', false);  }  
    A1.seatmap.resetAfterCancel = function() { window.location.reload(); };
    // prepare to display seatmap.  'max' (seat count) will be filled in when map is shown
    A1.seatmap.configureFrom(JSON.parse(this.seatmapInfo));
    A1.seatmap.seats = $('#seatmap').seatCharts(A1.seatmap.settings);
  }
}


A1.setupWalkupSales = function() {
  $('#store_subscribe .itemQty').change(A1.recalcStoreTotal);
  // for walkup sales page
  $('#walkup_tickets .item').change(A1.recalcWalkupSales);
  // if page reloaded due to failed payment txn, recalculate totals
  if ($('#walkup_sales_show').length) { // walkup sales page
    A1.seatmapWalkupSales.getSeatingOptions();
    A1.recalcWalkupSales();
    // SPECIAL CASE: if this is a page reload due to failed CC charge, DON'T ALLOW changing
    // seats or ticket quantities (except by clearing the order) and ONLY enable payment button.
    // We detect this because A1.seatmap.seats[] is empty on page load, BUT the actual
    // seat display form field will be populated with the previously chosen seat values from params[]
    if (A1.seatmap.selectedSeats.length == 0  &&  $('.seat-display').val() != '') {
      $('.item').prop('readonly', true);
      $('.select-seats').prop('disabled', true);
      $('.confirm-walkup-sale').prop('disabled', false);
    }
  }
};

A1.setupWalkupSalesPreview = function() {
  if ($('#static-seatmap').length) {
    A1.seatmap.configureFrom(JSON.parse($('#seatmap_info').val()));
    A1.seatmap.seats = $('#seatmap').seatCharts(A1.seatmap.settings);
    $('#seating-charts-wrapper').removeClass('d-none');
    A1.seatmap.setupMap("passive");
    // cancel button can be hidden
    $('.seat-select-cancel').hide();
  }
}

$(A1.setupWalkupSales);
$(A1.setupWalkupSalesPreview);


