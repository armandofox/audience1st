A1.vouchertype = {
  reset_fields: function() {
    var category = $('#vouchertype_category').val();
    $('.form-row').show();
    $('input.' + category).val('');
    $('input.' + category).checked = false;
    $('.form-row.' + category).hide();
  },
  setup: function() {
    A1.vouchertype.reset_fields();
    $('#vouchertype_category').change(A1.vouchertype.reset_fields);
  }
};

$(A1.vouchertype.setup);
