A1.vouchertype = {

  // event handler for checkboxes that filter list of vouchertypes
  filter_this_vouchertype: function() {
    var klass = 'tr.' + $(this).attr('name'); // eg 'tr.revenue'
    console.log(klass);
    if ($(this).is(':checked')) { $(klass).show();  }  else { $(klass).hide(); }
  },
  hide_price: function() {
    $('#p_vouchertype_price').hide();   
    $('#vouchertype_price').value = '0'; 
    $('#vouchertype_price').hide();
  },
  hide_walkup_sale: function()  {
    $('#p_vouchertype_walkup_sale_allowed').hide();
    $('#vouchertype_walkup_sale_allowed').checked = false;
  },
  hide_changeable: function() {
    $('#vouchertype_changeable').checked = false;
    $('#p_vouchertype_changeable').hide();
  },
  hide_account_code: function() {   
    $('#p_vouchertype_account_code').hide();  
  },
  hide_availability: function() {   
    $('#p_vouchertype_offer_public').hide();  
  },
  hide_mail_fulfillment_needed: function() { 
    $('#vouchertype_fulfillment_needed').checked = false; 
    $('#p_vouchertype_fulfillment_needed').hide();
  },
  hide_subscriber: function()   { 
    $('#p_vouchertype_subscription').hide();
    $('#vouchertype_subscription').checked = false;  
  },
  hide_comments: function() {
    $('#p_vouchertype_comments').hide();
    $('#vouchertype_comments').val('');
  },
  set_fields_for_category: function(category) {
    var k = A1.vouchertype;
    $('.vtform').show();
    switch(category)  {
    case 'bundle':
      k.hide_walkup_sale(); k.hide_changeable();
      k.hide_changeable();
      break;
    case 'subscriber':
      k.hide_price(); k.hide_walkup_sale(); 
      k.hide_account_code(); k.hide_availability();
      k.hide_mail_fulfillment_needed(); k.hide_subscriber();
      k.hide_comments();
      break;
    case 'comp':
      k.hide_price(); k.hide_account_code(); 
      k.hide_mail_fulfillment_needed(); k.hide_subscriber();
      break;
    case 'nonticket':
      k.hide_changeable();
      break;
    case 'revenue':
      break;
    }
  },
  reset_fields: function() {
    var category = $(this).val();
    A1.vouchertype.set_fields_for_category(category);
  },
  setup: function() {
    $('#vouchertype_category').change(A1.vouchertype.reset_fields);
    // checkboxes on index page
    $('.vouchertype-filter').change(A1.vouchertype.filter_this_vouchertype);
    // for Edit form, detect type being edited and set fields
    A1.vouchertype.set_fields_for_category($('#vouchertype_category_uncooked').val());
  }
};

$(A1.vouchertype.setup);
