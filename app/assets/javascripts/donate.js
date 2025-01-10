A1.donate = {

  conditionallyCopy: function(field) {
    var ccField = $("#credit_card_" + field);
    if (ccField.val() == "") {  ccField.val($("#customer_" + field).val()); }
  },
  redirectToRecurringDonation: function() {
    var amount = parseInt( $('#donation').val() ) || 0;
    var url = $('#recurring_donation_path').val() + '?amount=' + amount.toString();
    window.location = url;
  },
  quick_donate_setup: function() {
    $('#customer_first_name').change(function() { A1.quick_donate.conditionallyCopy('first_name'); });
    $('#customer_last_name').change(function() { A1.quick_donate.conditionallyCopy('last_name'); });
  },
  setup: function() {
    if ($('#quick_donation')) {
      A1.donate.quick_donate_setup();
    }
    // when Monthly Recurring donation selected, hide certain fields
    $('.recurring').hide();  $('.onetime').show();
    $('#donation_recurring').click(() => { $('.onetime').hide(); $('.recurring').show() });
    $('#donation_onetime').click(() => { $('.onetime').show(); $('.recurring').hide() });
    $('#redirect_to_recurring').click(() => A1.donate.redirectToRecurringDonation());
  }
};

$(A1.donate.setup);

