//# ルート現場マスタ #########################################################################################################################

//行追加（収集区登録）
function froute_add(cust_code, cust_name, cust_addr, latitude, longitude, admin_name, tel_no, email, bgcolor, add_flg){
  var cnt_no = eval(document.getElementById("m_route_point_cnt_no").value) + 1;
  $("#route_tag_sub").before(fhtml(cnt_no, cust_code, cust_name, cust_addr, latitude, longitude, admin_name, tel_no, email, bgcolor));
  document.getElementById("m_route_point_cnt_no").value = cnt_no;

  if(add_flg==1){
    routecode = document.getElementById("routecode").value;
    $.ajax({
      url: "m_route_points", 
      type: "POST", 
      data: 'routecode=' + routecode + '&add_flg=1&tree_no=' + cnt_no + '&cust_code=' + cust_code,
      complete: function(){
        //マーカー再表示
        f_marker_dsp();
      }
    })
  }else{
    //マーカー再表示
    f_marker_dsp();
  }
}

function fhtml(cnt_no, cust_code, cust_name, cust_addr, latitude, longitude, admin_name, tel_no, email, bgcolor){
  
  var ahtml = "";
  
  ahtml += "<div id=tree_no_" + cnt_no + ">";
  ahtml += "<table style='table-layout: fixed;'>";
  ahtml += "<tr style=\"background-color:" + bgcolor + ";\" id=tr_" + cust_code + " onClick=\"mClickTR(this, '" + latitude + "', '" + longitude + "', '" + bgcolor + "');\" onmouseover=\"mouseOverTR(this, '" + bgcolor + "');\" onmouseout=\"mouseOutTR(this, '" + bgcolor + "');\">";
  ahtml += "<td width=5% align=right><span id=seq_" + cust_code + ">&nbsp;</span></td>";
  ahtml += "<td width=10%>" + cust_code + "</td>";
  ahtml += "<td width=25%>" + decodeURIComponent(cust_name) + "</td>";
  ahtml += "<td width=30%>" + decodeURIComponent(cust_addr) + "</td>";
  ahtml += "<td width=15%>" + decodeURIComponent(admin_name) + "</td>";
  ahtml += "<td width=5%><input type=button value='削除' onClick=froute_dlt(" + cnt_no + ",'" + cust_code + "','" + cust_name + "','" + latitude + "','" + longitude + "'); class='btn btn-mini btn-danger'></td>";
  ahtml += "<input type=hidden id=cust_code_" + cnt_no + " name=cust_code[] value=" + cust_code + ">";
  ahtml += "<input type=hidden id=cust_name_" + cnt_no + " name=cust_name[] value=" + decodeURIComponent(cust_name) + ">";
  ahtml += "<input type=hidden id=bgcolor_" + cust_code + " name=bgcolor[" + cust_code + "] value=" + bgcolor + ">";
  ahtml += "</tr>";
  ahtml += "</table>";
  ahtml += "</div>";
  
  return ahtml;
}

//行削除
function froute_dlt(tree_no, cust_code, cust_name, latitude, longitude){

  
  if (confirm("削除処理をしますが、よろしいですか？\r\n※収集区内から除外されるだけでステーション自体は削除されません。")){
    $("div#tree_no_" + tree_no).remove();
    
    routecode = document.getElementById("routecode").value;
  
    $.ajax({
      url: "m_route_points", 
      type: "POST",
      data: 'routecode=' + routecode + '&delete_flg=1&tree_no=' + tree_no + '&cust_code=' + cust_code,
      complete: function(){
        //マーカー再表示
        f_marker_dsp();
      }
    })
  }else{
    return false;
  }
}

//マーカー再表示
function f_marker_dsp(){
  for(var i = 0; i < marker.length; i++){
    marker[i].setMap(null);
  }
  for(var i = 0; i < treeMarker.length; i++){
    treeMarker[i].setMap(null);
  }
  marker = new Array();
  treeMarker = new Array();
  //表示サイズが16以上の場合マーカー表示
  if(map.zoom>=16){
    document.getElementById("span_station_display").style.display="none";
    //緯度経度取得
    $('#layer').show();
    document.getElementById("routecode_marker_").value = document.getElementById("routecode").value;
    document.getElementById("northeast_lat_").value =map.getBounds().getNorthEast().lat();
    document.getElementById("southwest_lat_").value =map.getBounds().getSouthWest().lat();
    document.getElementById("northeast_lng_").value =map.getBounds().getNorthEast().lng();
    document.getElementById("southwest_lng_").value =map.getBounds().getSouthWest().lng();
    //再読み込み
    //$("#marker_form").submit();
    document.querySelector("#marker_form [type=submit]").click();
  }else{
    document.getElementById("span_station_display").style.display="";
  }
  $("#span_map_zoom_size").html(map.zoom);
}

//# ルート収集日マスタ #########################################################################################################################

//行追加
function froute_rundate_add(run_weeks, run_yobis, item_kbns, unit_kbns, itaku_codes, current_itaku_code){
  
  var run_week = document.getElementById("run_week_new_").value;
  var run_yobi = document.getElementById("run_yobi_new_").value;
  var item_kbn = document.getElementById("item_kbn_new_").value;
  var unit_kbn = document.getElementById("unit_kbn_new_").value;
  var itaku_code = document.getElementById("itaku_code_new_").value;
  var cnt_no = eval(document.getElementById("m_route_rundate_cnt_no").value) + 1;

  $("#route_tag_sub").before(fhtml_route_rundate(cnt_no, run_week, run_yobi, item_kbn, unit_kbn, itaku_code, run_weeks, run_yobis, item_kbns, unit_kbns, itaku_codes, current_itaku_code));
  document.getElementById("run_week_new_").value = "";
  document.getElementById("run_yobi_new_").value = "";
  document.getElementById("item_kbn_new_").value = "";
  document.getElementById("unit_kbn_new_").value = "";
  document.getElementById("itaku_code_new_").value = "";
  document.getElementById("m_route_rundate_cnt_no").value = cnt_no;
}

function fhtml_route_rundate(cnt_no, run_week, run_yobi, item_kbn, unit_kbn, itaku_code, run_weeks, run_yobis, item_kbns, unit_kbns, itaku_codes, current_itaku_code){

  var ary_runweek = froute_charchange(decodeURIComponent(run_weeks));
  var ary_runyobi = froute_charchange(decodeURIComponent(run_yobis));
  var ary_itemkbn = froute_charchange(decodeURIComponent(item_kbns));
  var ary_unitkbn = froute_charchange(decodeURIComponent(unit_kbns));
  var ary_itakucode = froute_charchange(decodeURIComponent(itaku_codes));
  
  var ahtml = "";
  var selecttype = "";

  ahtml += "<div id=tree_no_" + cnt_no + ">";
  ahtml += "<table>";
  ahtml += "<tr>";
  //週
  ahtml += "<td width=10%>";
  ahtml += "<select id=run_week_ name=run_week[]>";
  for(var i = 0; i < ary_runweek.split(",").length; i++){
    if (i % 2 != 0){
      if(eval(ary_runweek.split(",")[i])==eval(run_week)){
        selecttype = " selected='selected'";
      }else{
        selecttype = "";
      }
      ahtml += "<option value=" + ary_runweek.split(",")[i] + selecttype + ">" + ary_runweek.split(",")[i-1] + "</option>";
    }
  }
  ahtml += "</select>";
  ahtml += "</td>";
  
  //曜日
  ahtml += "<td width=15%>";
  ahtml += "<select id=run_yobi_ name=run_yobi[]>";
  for(var i = 0; i < ary_runyobi.split(",").length; i++){
    if (i % 2 != 0){
      if(eval(ary_runyobi.split(",")[i])==eval(run_yobi)){
        selecttype = " selected='selected'";
      }else{
        selecttype = "";
      }
      ahtml += "<option value=" + ary_runyobi.split(",")[i] + selecttype + ">" + ary_runyobi.split(",")[i-1] + "</option>";
    }
  }
  ahtml += "</select>";
  ahtml += "</td>";
  
  //ゴミ種類
  ahtml += "<td width=25%>";
  ahtml += "<select id=item_kbn_ name=item_kbn[]>";
  for(var i = 0; i < ary_itemkbn.split(",").length; i++){
    if (i % 2 != 0){
      if(eval(ary_itemkbn.split(",")[i])==eval(item_kbn)){
        selecttype = " selected='selected'";
      }else{
        selecttype = "";
      }
      ahtml += "<option value=" + ary_itemkbn.split(",")[i] + selecttype + ">" + ary_itemkbn.split(",")[i-1] + "</option>";
    }
  }
  ahtml += "</select>";
  ahtml += "</td>";
  
  //単位
  if(ary_unitkbn){
    ahtml += "<td width=10%>";
    ahtml += "<select id=unit_kbn_ name=unit_kbn[]>";
    ahtml += "<option value=''></option>";
    for(var i = 0; i < ary_unitkbn.split(",").length; i++){
      if (i % 2 != 0){
        if(eval(ary_unitkbn.split(",")[i])==eval(unit_kbn)){
          selecttype = " selected='selected'";
        }else{
          selecttype = "";
        }
        ahtml += "<option value=" + ary_unitkbn.split(",")[i] + selecttype + ">" + ary_unitkbn.split(",")[i-1] + "</option>";
      }
    }
    ahtml += "</select>";
    ahtml += "</td>";
  }
  
  //委託会社
  if(!current_itaku_code){
    ahtml += "<td width=30%>";
    ahtml += "<select id=itaku_code_ name=itaku_code[]>";
    ahtml += "<option value=''></option>";
    for(var i = 0; i < ary_itakucode.split(",").length; i++){
      if (i % 2 != 0){
        if(eval(ary_itakucode.split(",")[i])==eval(itaku_code)){
          selecttype = " selected='selected'";
        }else{
          selecttype = "";
        }
        ahtml += "<option value=" + ary_itakucode.split(",")[i] + selecttype + ">" + ary_itakucode.split(",")[i-1] + "</option>";
      }
    }
    ahtml += "</select>";
    ahtml += "</td>";
  }else{
    ahtml += "<input type=hidden id=itaku_code_ name=itaku_code[] value=" + current_itaku_code + ">";
  }
  ahtml += "<td width=10%><input type=button value='削除' onClick=froute_rundate_dlt(" + cnt_no + "); class='btn btn-mini btn-danger'></td>";
  ahtml += "</tr>";
  ahtml += "</table>";
  ahtml += "</div>";
  
  return ahtml;
}

//行削除
function froute_rundate_dlt(tree_no){
  $("div#tree_no_" + tree_no).remove();
}

//# ルート現場マスタ（ステーション登録より） ##################################################################################################################
function fcustom_route_add(m_routes){
  var route_code = document.getElementById("route_code_new_").value;
  var cnt_no = eval(document.getElementById("m_route_cnt_no").value) + 1;
  
  //エラーチェック
  if(!route_code){
    alert("収集区を選択してください。");
    return false;
  }
  
  //タグ追加
  $("#route_tag_sub").before(fhtml_custom_route(cnt_no, route_code, m_routes));
  document.getElementById("route_code_new_").value = "";
  document.getElementById("m_route_cnt_no").value = cnt_no;
}

function fhtml_custom_route(cnt_no, route_code, m_routes){
  var ary_route_code = froute_charchange(decodeURIComponent(m_routes));
  var ahtml = "";
  var selecttype = "";

  ahtml += "<div id=tree_no_" + cnt_no + ">";
  ahtml += "<table>";
  ahtml += "<tr>";
  ahtml += "<td width=70%>";
  ahtml += "<select id=route_code_ name=route_code[]>";
  for(var i = 0; i < ary_route_code.split(",").length; i++){
    if (i % 2 != 0){
      if(ary_route_code.split(",")[i]==route_code){
        selecttype = " selected='selected'";
      }else{
        selecttype = "";
      }
      ahtml += "<option value=" + ary_route_code.split(",")[i] + selecttype + ">" + ary_route_code.split(",")[i-1] + "</option>";
    }
  }
  ahtml += "</select>";
  
  ahtml += "</td>";
  ahtml += "<td width=30% align=center><input type=button value='削除' onClick=fcustom_route_dlt(" + cnt_no + "); class='btn btn-mini btn-danger'></td>";
  ahtml += "<input type=hidden id=route_code_old_ name=route_code_old[] value=''>";
  ahtml += "<input type=hidden id=tree_no_old_ name=tree_no_old[] value=0>";
  ahtml += "</tr>";
  ahtml += "</table>";
  ahtml += "</div>";

  return ahtml;
}

//更新処理
function fcustom_route_upd(){
  if (confirm("更新処理をしますが、よろしいですか？")){
    document.input_form.submit();
  }else{
    return false;
  }
}

//削除処理
function fcustom_route_dlt(tree_no){
  $("div#tree_no_" + tree_no).remove();
}
//# 共通 #########################################################################################################################

//更新処理
function froute_upd(){
  var detail_check = 0;
  
  if (document.getElementById("m_route_route_code").value.length<=0) {
    alert("収集区コードは入力必須です。");
    return false;
  }
  if (document.getElementById("m_route_route_name").value.length<=0) {
    alert("収集区名称は入力必須です。");
    return false;
  }
  if (document.getElementById("m_route_route_code").value.match(/[^0-9a-zA-Z_]+/)){
    alert("収集区コードは半角英数字で入力してください。");
    return false;
  }
  //明細行のチェック
  for(var i = 0; i < eval(document.getElementById("m_route_rundate_cnt_no").value)+1; i++){
    if(document.getElementById("tree_no_"+i)){
      detail_check = detail_check + 1;
    }
  }
  if(detail_check==0){
    alert("明細行を設定してください。");
    return false;
  }
  
  if (confirm("更新処理をしますが、よろしいですか？")){
    document.input_form.submit();
  }else{
    return false;
  }
}

//文字変換
function froute_charchange(char){
  char = char.replace(/"/g, "");
  char = char.split("[").join("");
  char = char.split("]").join("");
  char = char.split(" ").join("");
  return char;
}
