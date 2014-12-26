// Functions for handling payments through Stripe.
// These make the following assumptions about available form fields:
//  #_stripe_api_key       API key for stripe calls
//  ._stripe_total         floating-point total field; any characters
//                            that are not a digit or . are squeezed out
//  #_stripe_payment_form  form to submit to server
//  #_stripe_submit        the form's submit button (for enabling/disabling)
//  #credit_card_token    hidden field that will carry token returned by Stripe
//  #payment_errors        element in which to display errors from API call

function checkForStripe(eltIdToDisable) {
  if (typeof(Stripe) == 'undefined') {
    alert("Your browser appears to be blocking JavaScript connections to Stripe.com, which are necessary for processing credit card transactions.  Please add https://js.stripe.com to your Trusted Sites list to perform credit card purchases.");
    // disable purchase button
    document.getElementById(eltIdToDisable).disabled = true;
    return false;
  } else {
    return true;
  }
}

function disableRegularFormSubmit() {
  $('_stripe_payment_form').onsubmit = function(evt) { return false };
}

function stripeResponseHandler(status, response) {
  if (response.error) {
    // re-enable submit button
    $('_stripe_submit').disabled = false;
    $('payment_errors').innerHTML = 'Please correct the following problems:<br/>' +   response.error.message;
    //console.log("Stripe error: " + response.error.message);
  } else {
    document.getElementById('credit_card_token').value = response['id'];
    document.getElementById('_stripe_commit').value = 'credit';
    document.getElementById('_stripe_payment_form').submit();
  }
}

// Submit the cc info in the form whose id is _stripe_payment_form
// Submit button's ID is _stripe_submit

function stripeSubmit(event) {
  // disable regular form submit action (needed for Firefox <4)
  disableRegularFormSubmit();
  //console.log("Submitting to Stripe");
  if ($('swipe_data')  && $('swipe_data').getValue() != '') {
    // populate credit card info fields from magstripe swipe hidden field
    parseSwipeData();
  }
  var key = $('_stripe_api_key').getValue();
  $('payment_errors').innerHTML = '';  //  clear out errors field
  $('_stripe_submit').disabled = true; // disable submit button
  var card = {
        number: $('credit_card_number').getValue(),
        cvc: $('credit_card_verification_value').getValue(),
        exp_month: $('credit_card_month').getValue(),
        exp_year: $('credit_card_year').getValue(),
        name: ($('credit_card_first_name').getValue() + ' ' + $('credit_card_last_name').getValue())
  };
  if ($('billing')) {             // billing name/addr available on form?
      card.address_line1 = $$('#billing #customer_street')[0].getValue();
      card.address_zip = $$('#billing #customer_zip')[0].getValue();
      card.address_state = $$('#billing #customer_state')[0].getValue();
  }
  Stripe.setPublishableKey(key);
  Stripe.createToken(card, stripeResponseHandler);
  return(false);
}
