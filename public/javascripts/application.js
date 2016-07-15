// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

var A1 = {};                    // toplevel namespace for all our stuff

// Check place-order form before it's submitted.


// Last chance to check dates before placing order

function confirmCheckDates(str,submitBtn,cancelBtnName,cancelUrl) {
    if (confirm(str))  {
        Element.hide(cancelBtnName);
        submitBtn.disabled = true;
        submitBtn.value = 'Processing, Please Wait...';
        submitBtn.form.submit();
        return true;
    } else {
        return false;
    }

}


// Ajax.Autocompleter.extract_value =
//   function (value, className) {
//     var result;

//     var elements =
//       value.getElementsByClassName(className, value);
//     if (elements && elements.length == 1) {
//       result = elements[0].innerHTML.unescapeHTML();
//     }

//     return result;
// };

function setOptionsFrom(parent,child) {
    p = document.getElementById(parent+"_select");
    v = p.options[p.selectedIndex].value;
    arr2 = eval(child+"_value['"+v+"']");
    arr1 = eval(child+"_text['"+v+"']");
    setOptions(child+"_select",arr1,arr2);
}

function setOptions(id,arr1,arr2) {
    e = document.getElementById(id);
    e.options.length = arr1.length;
    for (i=0; i<arr1.length; i++) {
        e.options[i] = new Option(arr1[i],arr2[i],false,false);
    }
}

function showEltOnCondition(menu,elt,cond) {
    if (menu.options[menu.selectedIndex].value == cond) {
        Element.show(elt);
    } else {
        Element.hide(elt);
    }
}

// walkup sales - calculator

A1.recalc_store_total = function() {
  var total = A1.recalculate('#total', '.itemQty', 2);
  $('#submit').prop('disabled', (total <= 0.0));
};

$(function() {
  $('#store_index .itemQty').change(A1.recalc_store_total);
  $('#store_subscribe .itemQty')
});

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

