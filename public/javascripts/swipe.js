// after user clicks "Ready to swipe" button, move focus to
// hidden swipe-data field and change the message.  Set handler
// to do AJAX call to process swipe data on \n. If no swipe
// after 10 secs, go back to original state.
function waitForSwipe() {
    var timeout = 8;            // in seconds
    document.onKeyPress = collectKeys;
    $('ccReady').style.display = 'none';
    $('ccWaiting').style.display = 'block';
    $('swipe_data').value = '';
    $('swipe_data').focus();
    setTimeout('resetSwipe()', 1000*timeout);
    console.log("Swipe times out in " + timeout + " seconds");
    jQuery('#_stripe_payment_form').submit(parseSwipeData);
}
function resetSwipe() {
    console.log("Swipe timed out and reset");
    $('ccWaiting').style.display = 'none';
    $('ccReady').style.display = 'block';
    $('credit_card_verification_value').focus();
    jQuery('#_stripe_payment_form').submit(stripeSubmit);
}
// Ignore Enter/CR (which would normally sbmit form)
function collectKeys(evt) {
    var evt = (evt) ? evt : ((event) ? event : null);
    var node = (evt.target) ? evt.target : ((evt.srcElement) ? evt.srcElement : null); 
    if (evt.keyCode == 13)  { 
        parseSwipeData();
        stripeSubmit(evt);
        resetSwipe();
    }
}

// convert swipe data to form fields
function parseSwipeData() {
    trk1 = new RegExp('^%B(\d{1,19})\^([^/]+)/([^/^]+)\^(\d\d)(\d\d)');
    trk2 = new RegExp(';(\d{1,19})=(\d\d)(\d\d).{3,12}\?');
    swipe = $('swipe_data').getValue();
    console.log("Parsing swipe data: " + swipe);
    var elts = trk1.match(swipe);
    if (elts != null) {
        console.log("Parsing track 1");
        console.log(elts.toString());
        $('credit_card_number').value = elts[1];
        $('credit_card_last_name').value = elts[2];
        $('credit_card_first_name').value = elts[3];
        $('credit_card_year').value = (elts[4].toInt+2000).toString;
        $('credit_card_month').value = elts[5];
        stripeSubmit();
    } else if ((elts = trk2.match(swipe)) != null) {
        console.log("Parsing track 2");
        console.log(elts.toString());
        $('credit_card_number').value = elts[1];
        $('credit_card_year').value = (elts[2].toInt+2000).toString;
        $('credit_card_month').value = elts[3];
        $('credit_card_last_name').value = "";
        $('credit_card_first_name').value = "";
        stripeSubmit();
    } else {
        console.log("Couldn't match track 1 or track 2");
        $('credit_card_number').value = 'ERROR';
        $('credit_card_year').value =  'ERROR';
        $('credit_card_month').value =  'ERROR';
        $('credit_card_last_name').value = 'ERROR';
        $('credit_card_first_name').value =  'ERROR';
    }
    resetSwipe();
    return false;
}
