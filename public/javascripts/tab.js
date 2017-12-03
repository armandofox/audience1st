window.onload = function(){
    var myTab = document.getElementById("tab");
    if (myTab != null) {
        var myUl = myTab.getElementsByTagName("ul")[0];
        var myLi = myUl.getElementsByTagName("li");
        var myDiv = myTab.getElementsByTagName("div");
    
        for(var i = 0; i<myLi.length;i++){
            myLi[i].index = i;
            myLi[i].onclick = function(){
                for(var j = 0; j < myLi.length; j++){
                    myLi[j].className="off";
                    myDiv[j].className = "hide";
                }
                this.className = "on";
                myDiv[this.index].className = "show";
            }
        }
    }
}