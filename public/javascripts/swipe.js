// after user clicks "Ready to swipe" button, move focus to
// hidden swipe-data field and change the message.  Set handler
// to do AJAX call to process swipe data on \n. If no swipe
// after 10 secs, go back to original state.
function waitForSwipe() {
    document.getElementById('ccReady').style.display = 'none';
    document.getElementById('ccWaiting').style.display = 'block';
    document.getElementById('swipe_data').value = '';
    document.getElementById('swipe_data').focus();
    setTimeout('resetSwipe()', 10000);
}
function resetSwipe() {
    document.getElementById('ccWaiting').style.display = 'none';
    document.getElementById('ccReady').style.display = 'block';
    document.getElementById('credit_card_verification_value').focus();
}

// encrypt swipe data with one-time pad
function encryptField(field) {
    clear = document.getElementById(field).value;
    otp = document.getElementById('otp').value;
    cipher = '';
    for (i=0; i<clear.length; i++) {
        cipher += String.fromCharCode(clear.charCodeAt(i) ^ otp.charCodeAt(i));
    }
    document.getElementById(field).value = cipher;
    true;
}

// convert swipe data to form fields
function parseSwipeData() {
    trk1 = new RegExp('^%B(\d{1,19})\\^([^/]+)/?([^/]+)?\\^(\d\d)(\d\d)[^?]+\\?');
    trk2 = new RegExp(';(\d{1,19})=(\d\d)(\d\d).{3,12}\?');
    swipe = document.getElementById('swipe_data').value;
    var elts = trk1.exec(swipe);
    if (elts != null) {
        document.getElementById('credit_card_number').value = elts[1];
        document.getElementById('credit_card_last_name').value = elts[2];
        document.getElementById('credit_card_first_name').value = elts[3];
        document.getElementById('credit_card_year').value = (elts[4].toInt+2000).toString;
        document.getElementById('credit_card_month').value = elts[5];
    } else if ((elts = trk2.exec(swipe)) != null) {
        document.getElementById('credit_card_number').value = elts[1];
        document.getElementById('credit_card_year').value = (elts[2].toInt+2000).toString;
        document.getElementById('credit_card_month').value = elts[3];
        document.getElementById('credit_card_last_name').value = "";
        document.getElementById('credit_card_first_name').value = "";
    } else {
        document.getElementById('credit_card_number').value = 'ERROR';
        document.getElementById('credit_card_year').value =  'ERROR';
        document.getElementById('credit_card_month').value =  'ERROR';
        document.getElementById('credit_card_last_name').value = 'ERROR';
        document.getElementById('credit_card_first_name').value =  'ERROR';
    }
    return false;
}
