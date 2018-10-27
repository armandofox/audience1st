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

A1.clearCreditCardFields = function() {
  $('.unsubmitted').val('');
}
A1.swipeFail = function() { 
  alert('Error reading card.'); 
}
A1.copySwipe = function(data) {
  $('#credit_card_name').val(data.firstName + ' ' + data.lastName);
  $('#credit_card_number').val(data.account);
  $('#credit_card_month').val(data.expMonth);
  $('#credit_card_year').val("20" + data.expYear);
}

A1.stripeResponseHandler = function(status, response) {
  if (response.error) {
    // re-enable submit button
    $('#_stripe_submit').prop('disabled', false);
    $('#payment_errors').html('Please correct the following problems:<br/>' +   response.error.message);
  } else {
    $('#credit_card_token').val(response['id']);
    $('#_stripe_commit').val('credit');
    // we have to "unwrap" the jQuery form element or else submit() won't work (http://stackoverflow.com/a/22950376/558723)
    // $('#_stripe_payment_form')[0].submit();
    document.getElementById('_stripe_payment_form').submit();
  }
};

// Submit the cc info in the form whose id is _stripe_payment_form
// Submit button's ID is _stripe_submit

A1.stripeSubmit = function(event) {
  // disable regular form submit action (needed for Firefox <4)
  $('#_stripe_payment_form').submit(function(evt) { return false });
  //console.log("Submitting to Stripe");
  var key = $('#_stripe_api_key').val();
  $('#payment_errors').text('');  //  clear out errors field
  $('#_stripe_submit').prop('disabled', true); // disable submit button
  var card = {
    number: $('#credit_card_number').val(),
    cvc: $('#credit_card_verification_value').val(),
    exp_month: $('#credit_card_month').val(),
    exp_year: $('#credit_card_year').val(),
    name: ($('#credit_card_name').val())
  };
  if ($('#billing').length > 0) {             // billing name/addr available on form?
    card.address_line1 = $('#billing #customer_street').val();
    card.address_zip = $('#billing #customer_zip').val();
    card.address_state = $('#billing #customer_state').val();
  }
  Stripe.setPublishableKey(key);
  Stripe.createToken(card, A1.stripeResponseHandler);
  return(false);
}

A1.setupForCheckout = function() {
  // make credit card fields unsubmittable to server....
  $('.unsubmitted').removeAttr('name');                // always do this

  // setup swipe listener to wait for full swipe before passing keystrokes on
  $.cardswipe({
    success: A1.copySwipe,
    failure: A1.swipeFail,
    parsers: ["visa", "amex", "mastercard", "discover"],
  });
};

$(A1.setupForCheckout);
