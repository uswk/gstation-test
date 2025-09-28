class TLogHistsController < ApplicationController

  before_action :authenticate_user!

  # GET /t_log_hists
  def index
    userid = params[:search].nil? ? "" : params[:search][:query]
    strdate = params[:search_str].nil? ? Date.today.try(:strftime, "%Y/%m/%d") : params[:search_str][:str_date]
    enddate = params[:search_end].nil? ? Date.today.try(:strftime, "%Y/%m/%d") : params[:search_end][:end_date]
    change_type = params[:search].nil? ? "" : params[:search][:change_type]
    log_kbn = params[:search].nil? ? "" : params[:search][:log_kbn]
    strwhere = "1=1"
    # ユーザー
    if current_user.authority.to_s=="1"
      if userid.blank?
        if not current_user.itaku_code.blank?
          strwhere = strwhere + " AND u.itaku_code='#{current_user.itaku_code}'"
        end
      else
        strwhere = strwhere + " AND t_log_hists.user_id='#{userid}'"
      end
    else
      strwhere = strwhere + " AND t_log_hists.user_id='#{current_user.id}'"
    end
    # 期間
    if strdate != ""
      strwhere = strwhere + " AND t_log_hists.log_time>='#{strdate}'"
    end
    if enddate != ""
      enddate2 = enddate.to_date+1
      strwhere = strwhere + " AND t_log_hists.log_time<'#{enddate2}'"
    end
    # 作業内容
    if not log_kbn.blank?
      strwhere = strwhere + " and t_log_hists.menu_id='#{log_kbn}'"
    end
    # 種別
    if not change_type.blank?
      strwhere = strwhere + " and t_log_hists.change_type='#{change_type}'"
    end
    
    @t_log_hists = TLogHist.joins("left join users u on u.id=t_log_hists.user_id").joins("left join m_combos mc1 on mc1.class_1='#{G_LOG_KBN_CLASS_1}' and mc1.class_2=0 and mc1.class_code=t_log_hists.menu_id").joins("left join m_combos mc2 on mc2.class_1='#{G_CHANGE_TYPE_CLASS_1}' and mc2.class_2=0 and mc2.class_code=t_log_hists.change_type").page(params[:page]).per("#{G_DEF_PAGE_PER}").select("t_log_hists.*, u.user_name, mc1.class_name as menu_name, mc2.class_name as change_type_name").where("#{strwhere}").order("t_log_hists.id desc")
    if current_user.itaku_code.blank?
      userwhere = ""
    else
      userwhere = "itaku_code='#{current_user.itaku_code}'"
    end
    @users = User.where("#{userwhere}").order("users.user_id asc").map{|i| [i.user_name.to_s, i.id] }
    @change_types = MCombo.where("class_1=? and delete_flg=0", G_CHANGE_TYPE_CLASS_1).order("class_code, id").map{|i| [i.class_name.to_s, i.class_code] }
    @log_kbns = MCombo.where("class_1=? and delete_flg=0", G_LOG_KBN_CLASS_1).order("class_code, id").map{|i| [i.class_name.to_s, i.class_code] }
    
    respond_to do |format|
      format.html # index.html.erb
    end
  end
end
