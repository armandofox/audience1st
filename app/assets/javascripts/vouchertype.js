A1.vouchertype = {
  reset_fields: function() {
    var category = $('.vouchertype-category').val();
    $('#vouchertype-form .form-row').show();
    $('#vouchertype-form .form-row.' + category).hide();
    $('#vouchertype-form .btn.' + category).hide();
    $('#vouchertype-form input.' + category).val('0'); // numeric price field(s)
    $('#vouchertype-form input.' + category).checked = false;
  },
  setup: function() {
    if ($('#vouchertype-form').length) {
      A1.vouchertype.reset_fields();
      $('#vouchertype_category').change(A1.vouchertype.reset_fields);
    }
  }
};

$(A1.vouchertype.setup);
