class MCustomRundate < ApplicationRecord
  belongs_to :m_custom
  
  validates :run_week, :run_yobi, :item_kbn, presence: true

  # ⇨ m_combos に存在するコードであることを検証
  validates :run_week, combo_code: { class_1: G_CLASS_WEEK_CLASS_1 }
  validates :run_yobi, combo_code: { class_1: G_YOBI_CLASS_1 }
  validates :item_kbn, combo_code: { class_1: G_ITEM_CLASS_1 }
  validates :unit_kbn, combo_code: { class_1: G_UNIT_CLASS_1 }

  validates :m_custom_id, uniqueness: {
    scope: [:run_week, :run_yobi, :item_kbn],
    message: "同一取引先の(週×曜日×品目)が重複しています"
  }
end
