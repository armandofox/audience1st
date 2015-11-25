A1.vouchertype = {

  hide_price: function() {
    $('#p_vouchertype_price').hide();   
    $('#vouchertype_price').value = '0'; 
  },
  hide_walkup_sale: function()  {
    $('#p_vouchertype_walkup_sale_allowed').hide(); $('#vouchertype_walkup_sale_allowed').checked = false;  },
  hide_changeable: function() {
    $('#vouchertype_changeable').checked = false;  $('#p_vouchertype_changeable').hide(); },
  hide_account_code: function() {   $('#p_vouchertype_account_code').hide();  },
  hide_availability: function() {   $('#p_vouchertype_offer_public').hide();  },
  hide_subscriber: function()   {   
    $('#vouchertype_subscription').checked = false ; $('#p_vouchertype_subscription').hide();  },

  reset_fields: function() {
    var category = $(this).val();
    var k = A1.vouchertype;
    console.log(category);
    $('.vtform').show();
    switch(category)  {
    case 'bundle':
      k.hide_walkup_sale(); k.hide_changeable();
      break;
    case 'subscriber':
      k.hide_price(); k.hide_walkup_sale(); 
      k.hide_account_code(); k.hide_availability();
      break;
    case 'comp':
      k.hide_price(); k.hide_account_code(); 
      k.hide_subscriber();
      break;
    case 'nonticket':
      k.hide_changeable();
      break;
    case 'revenue':
      break;
    }
  },
  observe_vouchertype_field: function() {
    $('#vouchertype_category').change(A1.vouchertype.reset_fields);
  }
};

$(A1.vouchertype.observe_vouchertype_field);



