// /////////////////////////////////////////////////////////////////////////////////
// JavaScript Magstripe (track 1, track2) data parser object
//
// Mar-22-2005	Modified by Wayne Walrath,
//				Acme Technologies http://www.acmetech.com
//			based on demo source code from www.skipjack.com
//
// USAGE:
// var p = new SwipeParserObj();
// p.dump();  -- returns parsed field values and meta info.
//	-- or --
// get individual field names (see member variables at top of object)
//
// if( p.hasTrack1 ){
//		p.surname;
//		p.firstname;
//		p.account;
//		p.exp_month + "/" + p.exp_year;
//	}
///////////////////////////////////////////////////////////////////////////////////

function SwipeParserObj(strParse)
{
	///////////////////////////////////////////////////////////////
	///////////////////// member variables ////////////////////////
	this.input_trackdata_str = strParse;
	this.account_name = null;
	this.surname = null;
	this.firstname = null;
	this.acccount = null;
	this.exp_month = null;
	this.exp_year = null;
	this.track1 = null;
	this.track2 = null;
	this.hasTrack1 = false;
	this.hasTrack2 = false;
	/////////////////////////// end member fields /////////////////
	
	
	sTrackData = this.input_trackdata_str;     //--- Get the track data
	
  //-- Example: Track 1 & 2 Data
  //-- %B1234123412341234^CardUser/John^030510100000019301000000877000000?;1234123412341234=0305101193010877?
  //-- Key off of the presence of "^" and "="

  //-- Example: Track 1 Data Only
  //-- B1234123412341234^CardUser/John^030510100000019301000000877000000?
  //-- Key off of the presence of "^" but not "="

  //-- Example: Track 2 Data Only
  //-- 1234123412341234=0305101193010877?
  //-- Key off of the presence of "=" but not "^"

  if ( strParse != '' )
  {
    // alert(strParse);

    //--- Determine the presence of special characters
    nHasTrack1 = strParse.indexOf("^");
    nHasTrack2 = strParse.indexOf("=");

    //--- Set boolean values based off of character presence
    this.hasTrack1 = bHasTrack1 = false;
    this.hasTrack2 = bHasTrack2 = false;
    if (nHasTrack1 > 0) { this.hasTrack1 = bHasTrack1 = true; }
    if (nHasTrack2 > 0) { this.hasTrack2 = bHasTrack2 = true; }

    //--- Test messages
    // alert('nHasTrack1: ' + nHasTrack1 + ' nHasTrack2: ' + nHasTrack2);
    // alert('bHasTrack1: ' + bHasTrack1 + ' bHasTrack2: ' + bHasTrack2);    

    //--- Initialize
    bTrack1_2  = false;
    bTrack1    = false;
    bTrack2    = false;

    //--- Determine tracks present
    if (( bHasTrack1) && ( bHasTrack2)) { bTrack1_2 = true; }
    if (( bHasTrack1) && (!bHasTrack2)) { bTrack1   = true; }
    if ((!bHasTrack1) && ( bHasTrack2)) { bTrack2   = true; }

    //--- Test messages
    // alert('bTrack1_2: ' + bTrack1_2 + ' bTrack1: ' + bTrack1 + ' bTrack2: ' + bTrack2);

    //--- Initialize alert message on error
    bShowAlert = false;
    
    //-----------------------------------------------------------------------------    
    //--- Track 1 & 2 cards
    //--- Ex: B1234123412341234^CardUser/John^030510100000019301000000877000000?;1234123412341234=0305101193010877?
    //-----------------------------------------------------------------------------    
    if (bTrack1_2)
    { 
//      alert('Track 1 & 2 swipe');

      strCutUpSwipe = '' + strParse + ' ';
      arrayStrSwipe = new Array(4);
      arrayStrSwipe = strCutUpSwipe.split("^");
  
      var sAccountNumber, sName, sShipToName, sMonth, sYear;
  
      if ( arrayStrSwipe.length > 2 )
      {
        this.account = stripAlpha( arrayStrSwipe[0].substring(1,arrayStrSwipe[0].length) );
        this.account_name          = arrayStrSwipe[1];
        this.exp_month         = arrayStrSwipe[2].substring(2,4);
        this.exp_year          = '20' + arrayStrSwipe[2].substring(0,2); 
        
        //--- Different card swipe readers include or exclude the % in the front of the track data - when it's there, there are
        //---   problems with parsing on the part of credit cards processor - so strip it off
        if ( sTrackData.substring(0,1) == '%' ) {
        	sTrackData = sTrackData.substring(1,sTrackData.length);
        }

       	var track2sentinel = sTrackData.indexOf(";");
       	if( track2sentinel != -1 ){
       		this.track1 = sTrackData.substring(0, track2sentinel);
       		this.track2 = sTrackData.substring(track2sentinel);
       	}

		//--- parse name field into first/last names
		var nameDelim = this.account_name.indexOf("/");
		if( nameDelim != -1 ){
			this.surname = this.account_name.substring(0, nameDelim);
			this.firstname = this.account_name.substring(nameDelim+1);
		}
      }
      else  //--- for "if ( arrayStrSwipe.length > 2 )"
      { 
        bShowAlert = true;  //--- Error -- show alert message
      }
    }
    
    //-----------------------------------------------------------------------------
    //--- Track 1 only cards
    //--- Ex: B1234123412341234^CardUser/John^030510100000019301000000877000000?
    //-----------------------------------------------------------------------------    
    if (bTrack1)
    {
//      alert('Track 1 swipe');

      strCutUpSwipe = '' + strParse + ' ';
      arrayStrSwipe = new Array(4);
      arrayStrSwipe = strCutUpSwipe.split("^");
  
      var sAccountNumber, sName, sShipToName, sMonth, sYear;
  
      if ( arrayStrSwipe.length > 2 )
      {
        this.account = sAccountNumber = stripAlpha( arrayStrSwipe[0].substring( 1,arrayStrSwipe[0].length) );
        this.account_name = sName	= arrayStrSwipe[1];
        this.exp_month = sMonth	= arrayStrSwipe[2].substring(2,4);
        this.exp_year = sYear	= '20' + arrayStrSwipe[2].substring(0,2); 
  
        
        //--- Different card swipe readers include or exclude the % in
        //--- the front of the track data - when it's there, there are
        //---   problems with parsing on the part of credit cards processor - so strip it off
        if ( sTrackData.substring(0,1) == '%' ) { 
        	this.track1 = sTrackData = sTrackData.substring(1,sTrackData.length);
        }
  
        //--- Add track 2 data to the string for processing reasons
//        if (sTrackData.substring(sTrackData.length-1,1) != '?')  //--- Add a ? if not present
//        { sTrackData = sTrackData + '?'; }
		this.track2 = ';' + sAccountNumber + '=' + sYear.substring(2,4) + sMonth + '111111111111?';
        sTrackData = sTrackData + this.track2;
  
		//--- parse name field into first/last names
		var nameDelim = this.account_name.indexOf("/");
		if( nameDelim != -1 ){
			this.surname = this.account_name.substring(0, nameDelim);
			this.firstname = this.account_name.substring(nameDelim+1);
		}

      }
      else  //--- for "if ( arrayStrSwipe.length > 2 )"
      { 
        bShowAlert = true;  //--- Error -- show alert message
      }
    }
    
    //-----------------------------------------------------------------------------
    //--- Track 2 only cards
    //--- Ex: 1234123412341234=0305101193010877?
    //-----------------------------------------------------------------------------    
    if (bTrack2)
    {
//      alert('Track 2 swipe');
    
      nSeperator  = strParse.indexOf("=");
      sCardNumber = strParse.substring(1,nSeperator);
      sYear       = strParse.substr(nSeperator+1,2);
      sMonth      = strParse.substr(nSeperator+3,2);

      // alert(sCardNumber + ' -- ' + sMonth + '/' + sYear);

      this.account = sAccountNumber = stripAlpha(sCardNumber);
      this.exp_month = sMonth		= sMonth;
      this.exp_year = sYear			= '20' + sYear; 
        
      //--- Different card swipe readers include or exclude the % in the front of the track data - when it's there, 
      //---  there are problems with parsing on the part of credit cards processor - so strip it off
      if ( sTrackData.substring(0,1) == '%' ) {
		sTrackData = sTrackData.substring(1,sTrackData.length);
      }
  
    }
    
    //-----------------------------------------------------------------------------
    //--- No Track Match
    //-----------------------------------------------------------------------------    
    if (((!bTrack1_2) && (!bTrack1) && (!bTrack2)) || (bShowAlert))
    {
      //alert('Difficulty Reading Card Information.\n\nPlease Swipe Card Again.');
    }

//    alert('Track Data: ' + document.formFinal.trackdata.value);
    
    //document.formFinal.trackdata.value = replaceChars(document.formFinal.trackdata.value,';','');
    //document.formFinal.trackdata.value = replaceChars(document.formFinal.trackdata.value,'?','');

//    alert('Track Data: ' + document.formFinal.trackdata.value);

  } //--- end "if ( strParse != '' )"


	this.dump = function(){
		var s = "";
		var sep = "\r"; // line separator
		s += "Name: " + this.account_name + sep;
		s += "Surname: " + this.surname + sep;
		s += "first name: " + this.firstname + sep;
		s += "account: " + this.account + sep;
		s += "exp_month: " + this.exp_month + sep;
		s += "exp_year: " + this.exp_year + sep;
		s += "has track1: " + this.hasTrack1 + sep;
		s += "has track2: " + this.hasTrack2 + sep;
		s += "TRACK 1: " + this.track1 + sep;
		s += "TRACK 2: " + this.track2 + sep;
		s += "Raw Input Str: " + this.input_trackdata_str + sep;
		
		return s;
	}

	function stripAlpha(sInput){
		if( sInput == null )	return '';
		return sInput.replace(/[^0-9]/g, '');
	}

}
