// Functions for handling payments through Stripe.
// These make the following assumptions about available form fields:
//  #_stripe_api_key       API key for stripe calls
//  ._stripe_total         floating-point total field; any characters
//                            that are not a digit or . are squeezed out
//  #_stripe_payment_form  form to submit to server
//  #_stripe_submit        the form's submit button (for enabling/disabling)
//  #credit_card_token    hidden field that will carry token returned by Stripe
//  #payment_errors        element in which to display errors from API call

A1.checkForStripe = function() {
  if (typeof(Stripe) == 'undefined') {
    alert("Your browser appears to be blocking JavaScript connections to Stripe.com, which are necessary for processing credit card transactions.  Please add https://js.stripe.com to your Trusted Sites list to perform credit card purchases.");
    // disable purchase button
    $('#_stripe_submit').prop('disabled', true);
    return false;
  } else {
    return true;
  }
}

A1.show_only = function(div) {
  // force re-enabling regular form submission.  (b/c if a txn was submitted 
  // via Stripe JS and it failed, the form submit handler will still be 
  // set to block "real" submission of the form.)
  $('#_stripe_payment_form').submit(function(evt) { return true });
  $('#credit_card').hide(); 
  $('#cash').hide();        
  $('#check').hide();       
  $('#'+div).show();           
}


A1.stripeResponseHandler = function(status, response) {
  if (response.error) {
    // re-enable submit button
    $('#_stripe_submit').prop('disabled', false);
    $('#payment_errors').text('Please correct the following problems:<br/>' +   response.error.message);
  } else {
    $('#credit_card_token').val(response['id']);
    $('#_stripe_commit').val('credit');
    $('#_stripe_payment_form').submit();
  }
};

// Submit the cc info in the form whose id is _stripe_payment_form
// Submit button's ID is _stripe_submit

A1.stripeSubmit = function(event) {
  // disable regular form submit action (needed for Firefox <4)
  $('#_stripe_payment_form').submit(function(evt) { return false });
  //console.log("Submitting to Stripe");
  if ($('#swipe_data')  && $('#swipe_data').val() != '') {
    // populate credit card info fields from magstripe swipe hidden field
    parseSwipeData();
  }
  var key = $('#_stripe_api_key').val();
  $('#payment_errors').text('');  //  clear out errors field
  $('#_stripe_submit').prop('disabled', true); // disable submit button
  var card = {
        number: $('#credit_card_number').val(),
        cvc: $('#credit_card_verification_value').val(),
        exp_month: $('#credit_card_month').val(),
        exp_year: $('#credit_card_year').val(),
        name: ($('#credit_card_first_name').val() + ' ' + $('#credit_card_last_name').val())
  };
  if ($('#billing')) {             // billing name/addr available on form?
      card.address_line1 = $('#billing #customer_street')[0].val();
      card.address_zip = $('#billing #customer_zip')[0].val();
      card.address_state = $('#billing #customer_state')[0].val();
  }
  Stripe.setPublishableKey(key);
  Stripe.createToken(card, A1.stripeResponseHandler);
  return(false);
}

A1.checkPlaceOrderForm = function() {
    alrt = '';
    if (! $('#credit_card_number').val().match('[0-9]{15,16}')) {
        alrt += "Credit card number appears to be too short.\n";
    }
    if (! $('#credit_card_verification_value').val().match('[0-9]{3,4}')) {
        alrt += "Credit card security code appears to be too short.\n";
    }
    if ($('#sales_final') && !($('#sales_final').checked)) {
        alrt += "Please indicate your acceptance of our Terms of Sale by checking the TERMS OF SALE box.\n";
    }
    if (alrt != '') {
        alrt = "Please correct the following errors:\n\n" + alrt;
    } else {
        $('#_stripe_submit').disabled = false;
    }
    return alrt;
}

A1.setupForCheckout = function() {
  // make credit card fields unsubmittable to server....
  $('.unsubmitted').removeAttr('name');                // always do this
  // ...and whenever they change, check if order form is valid
  $('#credit_card_number').change(A1.checkPlaceOrderForm);
  $('#credit_card_verification_value').change(A1.checkPlaceOrderForm);
  $('#sales_final').change(A1.checkPlaceOrderForm);
  // on the checkout page, copy the billing customer info to the credit card info

  if (document.querySelector('body#store_checkout')) { // only on checkout page
    $('#credit_card_first_name').val($('#billing #customer_first_name').val());
    $('#credit_card_last_name').val($('#billing #customer_last_name').val());
    if (A1.checkForStripe()) {
       var message = $('#checkout_message').text();
       if (message != "") { alert(message); }
     }
  }
};

$(A1.setupForCheckout);
