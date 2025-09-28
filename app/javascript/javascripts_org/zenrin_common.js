     // ゼンリン住宅地図表示（位置情報と地図サイズをGETする）
     function fzenrin_common_map_display(url){
       var strHtml;
       var mapWidth = eval(document.getElementById("map_canvas").clientWidth);
       var mapHeight = eval(document.getElementById("map_canvas").clientHeight);
       var intWidth = eval(window.innerWidth)*0.98;
       var intHeight = eval(window.innerHeight)*0.9;
       var center_lat = map.getBounds().getCenter().lat();
       var center_lng = map.getBounds().getCenter().lng();

       document.getElementById("zenrin_latitude").value = center_lat;
       document.getElementById("zenrin_longitude").value = center_lng;
       
       $("div#tag_zenrin_map").remove();
       strHtml = "<div id='tag_zenrin_map'>";
       strHtml = strHtml + "<iframe src=" + url + "/zenrin_map?header_no_dsp=1&map_width=" + mapWidth + "&map_height=" + mapHeight + "&center_lat=" + center_lat + "&center_lng=" + center_lng + " height=" + intHeight + " width=" + intWidth + ">";
       strHtml = strHtml + "</iframe>";
       strHtml = strHtml + "</div>";
       $("#tag_sub_zenrin_map_common").after(strHtml);
       $('#modal_zenrin_map_common').dialog({
         title: "ゼンリン住宅地図　",
         modal: true,
         show : "fade",
         hide : "fade",
         width: intWidth,
         height: intHeight,
         open:function(event, ui){
           $(this).css('width', '100%');
           $(this).css('height', '100%');
           $(".ui-dialog-titlebar-close").hide();
         },
         close: Jzenrin_common_display_block
       });
     }
     function Jzenrin_common_display_block(){
       var center_position = new google.maps.LatLng(document.getElementById("zenrin_latitude").value, document.getElementById("zenrin_longitude").value);
       map.setCenter(center_position);
     }
