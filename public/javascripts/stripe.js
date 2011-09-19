// Functions for handling payments through Stripe.
// These make the following assumptions about available form fields:
//  #_stripe_api_key       API key for stripe calls
//  ._stripe_total         floating-point total field; any characters
//                            that are not a digit or . are squeezed out
//  #_stripe_payment_form  form to submit to server
//  #_stripe_submit        the form's submit button (for enabling/disabling)
//  #credit_card_token    hidden field that will carry token returned by Stripe
//  #payment_errors        element in which to display errors from API call

function getStripeTotal() {
  var total = $$('._stripe_total')[0].innerHTML;
  total = total.replace(/[^0-9.]+/g, '');
  return(100 * Number(total));
}

function stripeResponseHandler(status, response) {
  if (response.error) {
    // re-enable submit button
    $('_stripe_submit').disabled = false;
    $('payment_errors').innerHTML = 'Please correct the following problems:<br/>' +   response.error.message;
  } else {
    $('credit_card_token').setValue(response['id']);
    $('_stripe_payment_form').submit();
  }
}

// Submit the cc info in the form whose id is _stripe_payment_form
// Total is a floating-point number in field whose CLASS is _stripe_total
//   (convert to cents before submitting)
// Submit button's ID is _stripe_submit

function stripeSubmit(event) {
  var key = $('_stripe_api_key').getValue();
  $('payment_errors').innerHTML = '';  //  clear out errors field
  $('_stripe_submit').disabled = true; // disable submit button
  var total = getStripeTotal();
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
  Stripe.createToken(card, total, stripeResponseHandler);
  return(false);
}




                
