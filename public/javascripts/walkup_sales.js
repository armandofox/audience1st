// walkup sales - calculator

A1.recalc_store_total = function() {
  var total = A1.recalculate('#total', '.itemQty', 2);
  $('#submit').prop('disabled', (total <= 0.0));
};

A1.recalculate = function(total_field,selector,decplaces) {
  $(total_field).value = '';
  var tot = 0.0;
  var elts = $(selector);
  var price;
  var qty;
  elts.each(function(i) {
    var elt = $(this);
    if ((price = elt.data('price')) == undefined) { 
      // if data-price is not set, the field value itself is the 'price'
      price = 1.0;
    } 
    qty = parseFloat(elt.val());
    if (isNaN(qty)) { qty = 0; }
    tot += (price * qty);
  });
  if (!decplaces && decplaces != 0) { decplaces = 2; }
  $(total_field).val(tot.toFixed(decplaces));
  return(tot);
}

$(function() {
  $('#store_index .itemQty').change(A1.recalc_store_total);
  $('#store_subscribe .itemQty').change(A1.recalc_store_total);
});

