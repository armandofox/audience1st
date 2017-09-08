A1.imports_page_setup = function() {
  $('#import_type').change(function() { 
    $('.import_help').hide(); 
    $("#"+$('#import_type').val()).show(); 
  });
};

$(A1.imports_page_setup);

    
                           
