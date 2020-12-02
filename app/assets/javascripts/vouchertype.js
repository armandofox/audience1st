A1.vouchertype = {
  reset_fields: function() {
    var category = $('#vouchertype_category').val();
    $('#vouchertype-form form-row').show();
    $('#vouchertype-form input.' + category).val('0'); // numeric price field(s)
    $('#vouchertyoe-form input.' + category).checked = false;
    $('#vouchertype-form .form-row.' + category).hide();
  },
  setup: function() {
    if ($('body#vouchertypes_new').length) {
      A1.vouchertype.reset_fields();
      $('#vouchertype_category').change(A1.vouchertype.reset_fields);
    }
  }
};

$(A1.vouchertype.setup);
