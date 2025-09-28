//追加ボタン押下時
function fcarrun_add_button(){
  if (!document.getElementById("search_route").value){
    alert("追加時は収集区を選択してください。");
    return false;
  }
  document.getElementById("routecode").value =document.getElementById("search_route").value;
  document.add_form.submit();
}

//マーカー再表示
function f_marker_dsp_carrun(){
  
  //マーカークリア
  for(var i = 0; i < marker.length; i++){
    marker[i].setMap(null);
  }
  for(var i = 0; i < marker_unload.length; i++){
    marker_unload[i].setMap(null);
  }
  
  //表示サイズが16以上の場合マーカー表示
  if(map.zoom>=16){
    document.getElementById("span_station_display").style.display="none";
    //緯度経度取得
    $('#layer').show();
    document.getElementById("northeast_lat_").value =map.getBounds().getNorthEast().lat();
    document.getElementById("southwest_lat_").value =map.getBounds().getSouthWest().lat();
    document.getElementById("northeast_lng_").value =map.getBounds().getNorthEast().lng();
    document.getElementById("southwest_lng_").value =map.getBounds().getSouthWest().lng();
    //再読み込み
    $("#marker_form").submit();
  }else{
    document.getElementById("span_station_display").style.display="";
  }
  $("#span_map_zoom_size").html(map.zoom);
}
