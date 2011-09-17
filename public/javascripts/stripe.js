function getStripeTotal() {
  return(($$('.stripe_total')[0].getValue()) * 100);
}

function stripeResponseHandler(status, response) {
  if (response.error) {
    // re-enable submit button
    $('_stripe_submit').removeAttribute('disabled');
    // TBD - show errors on form
  } else {
    $('_stripe_payment_form')['token'].setValue(response['id']);
    $('_stripe_payment_form')

// Submit the cc info in the form whose id is _stripe_payment_form
// Total is a floating-point number in field whose CLASS is _stripe_total
//   (convert to cents before submitting)
// Submit button's ID is _stripe_submit

$(document).ready(function() {
    $('_stripe_payment_form').submit(function(event) {
        // disable submit button
        $('_stripe_submit').setAttribute('disabled', 'disabled');
        Stripe.createToken(
            {
            number: $('credit_card_number').getValue(),
              cvc: $('credit_card_verification_value').getValue(),
              exp_month: $('credit_card_month').getValue(),
              exp_year: $('credit_card_year').getValue()
             },
            getStripeTotal(),
            stripeResponseHandler);
        return false;
      });
  });





                
