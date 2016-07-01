A1.quick_donate = {

  conditionallyCopy: function(field) {
    var ccField = $("#credit_card_" + field);
    if (ccField.val() == "") {  ccField.val($("#customer_" + field).val()); }
  },
  setup: function() {
    $('#customer_first_name').change(function() { A1.quick_donate.conditionallyCopy('first_name'); });
    $('#customer_last_name').change(function() { A1.quick_donate.conditionallyCopy('last_name'); });
  }
};

if ($('#quick_donation')) {
  $(A1.quick_donate.setup);
}
