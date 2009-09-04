// after user clicks "Ready to swipe" button, move focus to
// hidden swipe-data field and change the message.  Set handler
// to do AJAX call to process swipe data on \n. If no swipe
// after 10 secs, go back to original state.
function waitForSwipe() {
    $('ccReady').style.display = 'none';
    $('ccWaiting').style.display = 'block';
    $('swipe_data').value = '';
    $('swipe_data').focus();
    setTimeout('resetSwipe()', 10000);
}
function resetSwipe() {
    $('ccWaiting').style.display = 'none';
    $('ccReady').style.display = 'block';
    $('credit_card_verification_value').focus();
}

// encrypt swipe data with one-time pad
function encryptField(field) {
    clear = $(field).value;
    otp = $('otp').value;
    cipher = '';
    for (i=0; i<clear.length; i++) {
        cipher += String.fromCharCode(clear.charCodeAt(i) ^ otp.charCodeAt(i));
    }
    $(field).value = cipher;
    true;
}

// convert swipe data to form fields
function parseSwipeData() {
    trk1 = new RegExp('^%B(\d{1,19})\\^([^/]+)/?([^/]+)?\\^(\d\d)(\d\d)[^?]+\\?');
    trk2 = new RegExp(';(\d{1,19})=(\d\d)(\d\d).{3,12}\?');
    swipe = $('swipe_data').value;
    var elts = trk1.exec(swipe);
    if (elts != null) {
        $('credit_card_number').value = elts[1];
        $('credit_card_last_name').value = elts[2];
        $('credit_card_first_name').value = elts[3];
        $('credit_card_year').value = (elts[4].toInt+2000).toString;
        $('credit_card_month').value = elts[5];
    } else if ((elts = trk2.exec(swipe)) != null) {
        $('credit_card_number').value = elts[1];
        $('credit_card_year').value = (elts[2].toInt+2000).toString;
        $('credit_card_month').value = elts[3];
        $('credit_card_last_name').value = "";
        $('credit_card_first_name').value = "";
    } else {
        $('credit_card_number').value = 'ERROR';
        $('credit_card_year').value =  'ERROR';
        $('credit_card_month').value =  'ERROR';
        $('credit_card_last_name').value = 'ERROR';
        $('credit_card_first_name').value =  'ERROR';
    }
    return false;
}
