class MRouteRundate < ActiveRecord::Base
  #attr_accessible :route_code, :tree_no, :run_week, :run_yobi, :item_kbn, :itaku_code, :unit_kbn
  
  validates :route_code,  :uniqueness => {:scope => [:run_week, :run_yobi, :item_kbn, :itaku_code], :message =>"　同一曜日で同じごみ種類を設定することはできません。"}
end
