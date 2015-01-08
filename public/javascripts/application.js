// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

var A1 = {};                    // toplevel namespace for all our stuff
jQuery.noConflict(); // call Prototype's $ rather than Jquery's, temporary for compatibility
function reset_vouchertype_fields(category) {
    function hide_price() {
        $('p_vouchertype_price').hide();   $('vouchertype_price').value = '0'; }
    function hide_walkup_sale()  {
        $('p_vouchertype_walkup_sale_allowed').hide(); $('vouchertype_walkup_sale_allowed').checked = false;  }
    function hide_changeable() {
        $('vouchertype_changeable').checked = false;  $('p_vouchertype_changeable').hide(); }
    function hide_account_code() {   $('p_vouchertype_account_code').hide();  }
    function hide_availability() {   $('p_vouchertype_offer_public').hide();  }
    function hide_subscriber()   {   
        $('vouchertype_subscription').checked = false ; $('p_vouchertype_subscription').hide();  }
    $$('.vtform').map(Element.show);
    switch(category)  {
    case 'bundle':
        hide_walkup_sale(); hide_changeable();
        break;
    case 'subscriber':
        hide_price(); hide_walkup_sale(); hide_account_code(); hide_availability();
        break;
    case 'comp':
        hide_price(); hide_account_code(); hide_subscriber();
        break;
    case 'nonticket':
        hide_changeable();
        break;
    case 'revenue':
        break;
    }

}

// Check place-order form before it's submitted.

function checkPlaceOrderForm() {
    alrt = '';
    if (! $('credit_card_number').value.match('[0-9]{15,16}')) {
        alrt += "Credit card number appears to be too short.\n";
    }
    if (! $('credit_card_verification_value').value.match('[0-9]{3,4}')) {
        alrt += "Credit card security code appears to be too short.\n";
    }
    if ($('sales_final') && !($('sales_final').checked)) {
        alrt += "Please indicate your acceptance of our Terms of Sale by checking the TERMS OF SALE box.\n";
    }
    if (alrt != '') {
        alrt = "Please correct the following errors:\n\n" + alrt;
    } else {
        $('_stripe_submit').disabled = false;
    }
    return alrt;
}

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


Ajax.Autocompleter.extract_value =
  function (value, className) {
    var result;

    var elements =
      value.getElementsByClassName(className, value);
    if (elements && elements.length == 1) {
      result = elements[0].innerHTML.unescapeHTML();
    }

    return result;
};

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

function checkBoxes(formid,newval) {
    frm = '#' + formid + ' input.check';
    $$(frm).each(function(box) {box.checked=(newval ? true : false)} );
    return false;
}


function showEltOnCondition(menu,elt,cond) {
    if (menu.options[menu.selectedIndex].value == cond) {
        Element.show(elt);
    } else {
        Element.hide(elt);
    }
}

// walkup sales - calculator

function recalculate(target,selector,field_to_enable_if_nonzero,decplaces,no_price) {
    $(target).value = '';
    var tot = 0.0;
    var elts = $$(selector);
    for (var i = 0; i < elts.length; i++) {
        elt = elts[i];
        if (!no_price) {
            pricefield = $(elt.id + '_price');
            var price = pricefield ? parseFloat(pricefield.value) : 1;
        } else {
            var price = 1;
        }
        var qty   = (elt.tagName.match( /^select$/i ) ?
                 parseInt(elt.options[elt.selectedIndex].value)  :
                 parseFloat(elt.value)) ;
        if (isNaN(qty)) { qty = 0; }
        tot += (price * qty);
    }
    if (field_to_enable_if_nonzero) {
        if (tot > 0.0) {
            $(field_to_enable_if_nonzero).disabled = false;
        } else {
            $(field_to_enable_if_nonzero).disabled = true;
        }
    }
    if (!decplaces && decplaces != 0) { decplaces = 2; }
    $(target).value = tot.toFixed(decplaces);
}

// Enable chaining of onLoad handlers.

function addLoadEvent(func) {
  var oldonload = window.onload;
  if (typeof window.onload != 'function') {
    window.onload = func;
  } else {
    window.onload = function() {
      if (oldonload) {
        oldonload();
      }
      func();
    }
  }
}

