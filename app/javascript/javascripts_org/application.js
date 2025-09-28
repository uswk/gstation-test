// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// WARNING: THE FIRST BLANK LINE MARKS THE END OF WHAT'S TO BE PROCESSED, ANY BLANK LINE SHOULD
// GO AFTER THE REQUIRES BELOW.
//
//= require jquery
//= require jquery_ujs
//= require twitter/bootstrap
//= require jquery-ui.min
//= require jquery-ui
//= require jquery.ui.datepicker-ja
//= require jquery.remotipart
//= require js/lightbox
//= require fixed_midashi_src
//= require_tree .

//import jquery from "jquery";
//window.$ = jquery

/*
$(function() {
  $( ".datepicker" ).datepicker({buttonImage: 'images/calendar_icon.png', buttonText: 'カレンダー', buttonImageOnly: true, showOn: "both", dateFormat: 'yy/mm/dd'});
});
$(function() {
  $( ".datepicker_sub" ).datepicker({dateFormat: 'yy/mm/dd'});
});
$(function() {
  $( ".timepicker" ).datepicker({buttonImage: 'images/calendar_icon.png', buttonText: 'カレンダー', buttonImageOnly: true, showOn: "both", dateFormat: 'yy/mm/dd 00:00:00'});
});
$(function(){
  $('#sortable-div').sortable();
});
*/

function f_marker_dsp_map() {
        alert('hoge');
}

function commonCkDate(datestr) { 
  // 正規表現による日付書式チェック 
  if(!datestr.match(/^\d{4}\/\d{2}\/\d{2}$/)){ 
    return false; 
  } 
  var vYear = datestr.substr(0, 4) - 0; 
  var vMonth = datestr.substr(5, 2) - 1; // Javascriptは、0-11で表現 
  var vDay = datestr.substr(8, 2) - 0; 
  // 月,日の妥当性チェック 
  if(vMonth >= 0 && vMonth <= 11 && vDay >= 1 && vDay <= 31){ 
    var vDt = new Date(vYear, vMonth, vDay); 
    if(isNaN(vDt)){ 
      return false; 
    }else if(vDt.getFullYear() == vYear && vDt.getMonth() == vMonth && vDt.getDate() == vDay){ 
      return true; 
    }else{ 
      return false; 
    } 
  }else{ 
    return false; 
  } 
}

function commonCkTime(str) { 
  // 正規表現による時刻書式チェック 
  if(!str.match(/^\d{2}\:\d{2}\:\d{2}$/)){ 
    return false; 
  } 
  var vHour = str.substr(0, 2) - 0;
  var vMinutes = str.substr(3, 2) - 0;
  var vSeconds = str.substr(6, 2) - 0;
  if(vHour >= 0 && vHour <= 24 && vMinutes >= 0 && vMinutes <= 59 && vSeconds >= 0 && vSeconds <= 59){ 
    return true; 
  }else{ 
    return false;
  } 
}

function commonCkDateTime(str) {
  // 正規表現による日付・時刻書式チェック 
  if (commonCkDate(str.substr(0, 10))==false) {
    return false;
  }
  if (commonCkTime(str.substr(11, 8))==false) {
    return false;
  }
  return true;
}


var poly_color_code = new Array();
poly_color_code[0] = "#FF0000";
poly_color_code[1] = "#008000";
poly_color_code[2] = "#FF6600";
poly_color_code[3] = "#800800";
poly_color_code[4] = "#0000FF";
poly_color_code[5] = "#808080";
poly_color_code[6] = "#808000";
poly_color_code[7] = "#800000";
poly_color_code[8] = "#000000";
poly_color_code[9] = "#FF00FF";
