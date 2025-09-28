import { post } from '@rails/request.js'

function f_marker_dsp_map() {
  alert(' xxxxxxxxxxxxxxxxxxxx f_marker_dsp_map')
  /*
  //マーカークリア
  for (var i = 0; i < marker.length; i++){
    marker[i].setMap(null);
  }

  marker = new Array();
  //表示サイズが16以上の場合マーカー表示
  if (map.zoom>=16){
    document.getElementById("span_station_display").style.display="none";
    //緯度経度取得
    $('#layer').show();
    document.getElementById("routecode_marker_").value = document.getElementById("routecode").value;
    document.getElementById("northeast_lat_").value =map.getBounds().getNorthEast().lat();
    document.getElementById("southwest_lat_").value =map.getBounds().getSouthWest().lat();
    document.getElementById("northeast_lng_").value =map.getBounds().getNorthEast().lng();
    document.getElementById("southwest_lng_").value =map.getBounds().getSouthWest().lng();
    //管理者種別
    for (var j = -1; j <= eval(document.getElementById("admin_type_count").value); j++){
      if(document.getElementById("search_admin_type_"+j)){
        if(document.getElementById("search_admin_type_"+j).checked){
          document.getElementById("admin_type_" + j).value = 1;
        } else {
          document.getElementById("admin_type_" + j).value = 0;
        }
      }
    }

    //再読み込み
    $("#marker_form").submit();
  } else {
    document.getElementById("span_station_display").style.display="";
  }
  $("#span_map_zoom_size").html(map.zoom);
  */
}
