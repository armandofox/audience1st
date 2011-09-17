function getStripeTotal() {
  return(100 * Number($$('._stripe_total')[0].innerHTML.substring(1)));
}

function stripeResponseHandler(status, response) {
  if (response.error) {
    // re-enable submit button
    $('_stripe_submit').disabled = false;
    $('payment_errors').innerHTML = '';
    // TBD - show errors on form
  } else {
    $('_stripe_payment_form')['credit_card_token'].setValue(response['id']);
    $('_stripe_payment_form').submit();
  }
}

// Submit the cc info in the form whose id is _stripe_payment_form
// Total is a floating-point number in field whose CLASS is _stripe_total
//   (convert to cents before submitting)
// Submit button's ID is _stripe_submit

function stripeSubmit(event) {
  // disable submit button
  $('_stripe_submit').disabled = true;
  Stripe.createToken({
      number: $('credit_card_number').getValue(),
        cvc: $('credit_card_verification_value').getValue(),
        exp_month: $('credit_card_month').getValue(),
        exp_year: $('credit_card_year').getValue()
        },
    getStripeTotal(),
    stripeResponseHandler);
  return false;
}




                
