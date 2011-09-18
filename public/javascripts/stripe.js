function getStripeTotal() {
  return(100 * Number($$('._stripe_total')[0].innerHTML.substring(1)));
}

function getStripeDescription() {

}

function stripeResponseHandler(status, response) {
  if (response.error) {
    // re-enable submit button
    $('_stripe_submit').disabled = false;
    $('payment_errors').innerHTML = 'Please correct the following problems:<br/>' + 
      response.error.message;
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
  // clear out errors field
  $('payment_errors').innerHTML = '';
  // disable submit button
  $('_stripe_submit').disabled = true;
  var name = $$('#billing #customer_first_name')[0].getValue() + ' ' + 
    $$('#billing #customer_last_name')[0].getValue();
  var total = getStripeTotal();
  Stripe.createToken({
      number: $('credit_card_number').getValue(),
        cvc: $('credit_card_verification_value').getValue(),
        exp_month: $('credit_card_month').getValue(),
        exp_year: $('credit_card_year').getValue(),
        name:  name,
        address_line1: $$('#billing #customer_street')[0].getValue(),
        address_zip: $$('#billing #customer_zip')[0].getValue(),
        address_state: $$('#billing #customer_state')[0].getValue()
        },
    total,
    stripeResponseHandler);
  return false;
}




                
