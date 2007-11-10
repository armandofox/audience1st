// walkup sales - calculator

function recalculate(target,elts) {
    document.getElementById(target).value = '';
    var tot = 0.0;
    for (i=0; i<elts.length; i++) {
        e = elts[i].toString();
        price = document.getElementById("price"+e);
        qty = document.getElementById("select"+e);
        qty = qty.options[qty.selectedIndex];
        tot += (parseFloat(price.value) * qty.value);
    }
    if (e = document.getElementById('donation')) {
        tot += parseFloat(e.value);
    }
    document.getElementById(target).value = tot;
}

