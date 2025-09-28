window.addEventListener("load", function() {
  $( ".datepicker" ).datepicker({buttonImage: 'images/calendar_icon.png', buttonText: 'カレンダー', buttonImageOnly: true, showOn: "both", dateFormat: 'yy/mm/dd'});
});
/*
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
