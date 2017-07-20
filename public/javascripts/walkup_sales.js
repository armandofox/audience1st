// walkup sales - calculator

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

A1.recalc_store_total = function() {
  var total = A1.recalculate('#total', '.itemQty', 2, 'price');
  $('#submit').prop('disabled', (total <= 0.0));
};

A1.recalc_all_walkup_sales = function() {
  var total = A1.recalculate('#total', '.item', 2, 'price');
  $('#_stripe_submit').prop('disabled', (total <= 0.0));
  A1.recalculate('#totaltix', '.itemCount', 0);
}

A1.recalculate = function(total_field,selector,decplaces,attrib) {
  $(total_field).value = '';
  var tot = 0.0;
  var elts = $(selector);
  var price;
  var qty;
  elts.each(function(i) {
    var elt = $(this);
    if ((typeof attrib == "undefined") || 
        ((price = elt.data(attrib)) == undefined)) { 
      // if price attribute is either not given or not present,
      // the field value itself is the 'price'
      price = 1.0;
    } 
    qty = parseFloat(elt.val());
    if (isNaN(qty)) { 
      qty = 0; 
    }
    tot += (price * qty);
  });
  $(total_field).val(tot.toFixed(decplaces));
  return(tot);
}

$(function() {
  $('#store_index .itemQty').change(A1.recalc_store_total);
  $('#store_subscribe .itemQty').change(A1.recalc_store_total);
  // for walkup sales page
  $('#walkup_tickets .item').change(A1.recalc_all_walkup_sales);
  // if page reloaded due to failed payment txn, recalculate totals
  if ($('#walkup_tickets').length) { // walkup sales page
    A1.recalc_all_walkup_sales();
  }
});

