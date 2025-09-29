class MRoutePointRundate < ApplicationRecord
  belongs_to :m_route_point

  validates :run_week, combo_code: { class_1: G_WEEK_CLASS_1 }
  validates :run_yobi, combo_code: { class_1: G_YOBI_CLASS_1 }
  validates :item_kbn, combo_code: { class_1: G_ITEM_CLASS_1 }
  validates :unit_kbn, combo_code: { class_1: G_UNIT_CLASS_1 }

  validates :m_route_point_id, uniqueness: {
    scope: [:run_week, :run_yobi, :item_kbn],
    message: "同一点の(週×曜日×品目)が重複しています"
  }
end
