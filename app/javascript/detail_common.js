    //ステーション画面呼び出し
    function fcustom_detail_common(id, url, alter_path){
      var strHtml;
      var intWidth = eval(window.innerWidth)*9/10;
      var intHeight = eval(window.innerHeight)*9/10;
      
      $("div#tag_station_detail").remove();
      strHtml = "<div id='tag_station_detail'>";
      strHtml = strHtml + "<iframe src=" + url + "/m_customs/" + id + alter_path + "?header_no_dsp=1 height=" + intHeight + " width=" + intWidth + ">";
      strHtml = strHtml + "</iframe>";
      strHtml = strHtml + "</div>";
      $("#tag_sub_station_detail_common").after(strHtml);
      $('#modal_station_detail_common').dialog({
        title: "ステーション詳細画面　",
        modal: true,
        show : "fade",
        hide : "fade",
        width: intWidth,
        height: intHeight,
        open:function(event, ui){ 
          $(this).css('width', '100%');
          $(this).css('height', '100%');
          $(".ui-dialog-titlebar-close").show();
        }
      });
    }
    
    //ステーションメモ呼び出し
    function fcustom_memo_common(cust_code, url){
      var strHtml;
      var intWidth = eval(window.innerWidth)*9/10;
      var intHeight = eval(window.innerHeight)*9/10;

      $("div#tag_station_detail").remove();
      strHtml = "<div id='tag_station_detail'>";
      strHtml = strHtml + "<iframe src=" + url + "/t_custom_memos?cust_code=" + cust_code + " height=" + intHeight + " width=" + intWidth + ">";
      strHtml = strHtml + "</iframe>";
      strHtml = strHtml + "</div>";
      $("#tag_sub_station_detail_common").after(strHtml);
      $('#modal_station_detail_common').dialog({
        title: "ステーションメモ画面　",
        modal: true,
        show : "fade",
        hide : "fade",
        width: intWidth,
        height: intHeight,
        open:function(event, ui){ 
          $(this).css('width', '100%');
          $(this).css('height', '100%');
          $(".ui-dialog-titlebar-close").show();
        }
      });
    }

    //ステーション収集履歴呼び出し
    function fcustom_carrun_common(cust_kbn, cust_code, url){
      var strHtml;
      var intWidth = eval(window.innerWidth)*9/10;
      var intHeight = eval(window.innerHeight)*9/10;
      var title;
      if(cust_kbn=="3"){
        title = "荷降履歴画面　";
      }else{
        title = "ステーション収集履歴画面　";
      }
      
      $("div#tag_station_detail").remove();
      strHtml = "<div id='tag_station_detail'>";
      strHtml = strHtml + "<iframe src=" + url + "/t_custom_carruns?cust_kbn=" + cust_kbn + "&cust_code=" + cust_code + " height=" + intHeight + " width=" + intWidth + ">";
      strHtml = strHtml + "</iframe>";
      strHtml = strHtml + "</div>";
      $("#tag_sub_station_detail_common").after(strHtml);
      $('#modal_station_detail_common').dialog({
        title: title,
        modal: true,
        show : "fade",
        hide : "fade",
        width: intWidth,
        height: intHeight,
        open:function(event, ui){ 
          $(this).css('width', '100%');
          $(this).css('height', '100%');
          $(".ui-dialog-titlebar-close").show();
        }
      });
    }
    
    //荷下先画面呼び出し
    function funload_detail_common(id, url, alter_path){
      var strHtml;
      var intWidth = eval(window.innerWidth)*9/10;
      var intHeight = eval(window.innerHeight)*9/10;
      
      $("div#tag_station_detail").remove();
      strHtml = "<div id='tag_station_detail'>";
      strHtml = strHtml + "<iframe src=" + url + "/unloads/" + id + alter_path + "?header_no_dsp=1 height=" + intHeight + " width=" + intWidth + ">";
      strHtml = strHtml + "</iframe>";
      strHtml = strHtml + "</div>";
      $("#tag_sub_station_detail_common").after(strHtml);
      $('#modal_station_detail_common').dialog({
        title: "荷降先詳細画面　",
        modal: true,
        show : "fade",
        hide : "fade",
        width: intWidth,
        height: intHeight,
        open:function(event, ui){ 
          $(this).css('width', '100%');
          $(this).css('height', '100%');
          $(".ui-dialog-titlebar-close").show();
        }
      });
    }
    
