// walkup sales - calculator

A1.recalc_store_total = function() {
  var total = A1.recalculate('#total', '.itemQty', 2, 'price');
  $('#submit').prop('disabled', (total <= 0.0));
};

A1.recalc_all_walkup_sales = function() {
  A1.recalculate('#totaltix', '.itemCount', 0);
  A1.recalculate('#total', '.item', 2, 'price');
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
});

