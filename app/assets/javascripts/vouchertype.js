A1.vouchertype = {
  filter_this_vouchertype: function() {
    var klass = 'tr.' + $(this).attr('name'); // eg 'tr.revenue'
    if ($(this).is(':checked')) {
      $(klass).show();
    }  else {
      $(klass).hide();
    }
  },
  reset_fields: function() {
    var category = $('.vouchertype-category').val();
    $('#vouchertype-form .form-row').show();
    $('#vouchertype-form .form-row.' + category).hide();
    $('#vouchertype-form .btn.' + category).hide();
    $('#vouchertype-form input.' + category).val('0'); // numeric price field(s)
    $('#vouchertype-form input.' + category).checked = false;
  },
  setup: function() {
    $('.vouchertype-filter').change(A1.vouchertype.filter_this_vouchertype);   
    if ($('#vouchertype-form').length) {
      A1.vouchertype.reset_fields();
      $('#vouchertype_category').change(A1.vouchertype.reset_fields);
    }
  }
};

$(A1.vouchertype.setup);
