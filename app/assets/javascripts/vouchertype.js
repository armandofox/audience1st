A1.vouchertype = {
  reset_fields: function() {
    var category = $('#vouchertype_category').val();
    $('#vouchertype-form form-row').show();
    $('#vouchertype-form input.' + category).val('0'); // numeric price field(s)
    $('#vouchertyoe-form input.' + category).checked = false;
    $('#vouchertype-form .form-row.' + category).hide();
  },
  filter_this_vouchertype: function() {
    var klass = 'tr.' + $(this).attr('name'); // eg 'tr.revenue'
    console.log(klass);
    if ($(this).is(':checked')) {
      $(klass).show();
    }  else {
      $(klass).hide();
    }
  },
  setup: function() {
    $('.vouchertype-filter').change(A1.vouchertype.filter_this_vouchertype);   
    if ($('body#vouchertypes_new').length) {
      A1.vouchertype.reset_fields();
      $('#vouchertype_category').change(A1.vouchertype.reset_fields);
    }
  }
};

$(A1.vouchertype.setup);
