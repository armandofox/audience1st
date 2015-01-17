A1.quick_donate = {

  conditionallyCopy: function(field) {
    var ccField = jQuery("#credit_card_" + field);
    if (ccField.val() == "") {  ccField.val(jQuery("#customer_" + field).val()); }
  },
  setup: function() {
    jQuery('#customer_first_name').change(function() { A1.quick_donate.conditionallyCopy('first_name'); });
    jQuery('#customer_last_name').change(function() { A1.quick_donate.conditionallyCopy('last_name'); });
  }
};

if (jQuery('#quick_donation')) {
  jQuery(A1.quick_donate.setup);
}
