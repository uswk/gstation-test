class MCombo < ActiveRecord::Base
  #attr_accessible :class_1, :class_2, :class_code, :class_name, :class_namea, :value, :value2, :value3, :value4, :value5, :system_flg, :delete_flg

  validates :class_1, :uniqueness => {:scope => [:class_2, :class_code], :message =>"　分類コードが重複しています。"}

  scope :weeks, -> { where(class_1: G_WEEK_CLASS_1).order(:class_code) }
  scope :yobis, -> { where(class_1: G_YOBI_CLASS_1).order(:class_code) }
  scope :items, -> { where(class_1: G_ITEM_CLASS_1).order(:class_code) }
  scope :units, -> { where(class_1: G_UNIT_CLASS_1).order(:class_code) }

  def label
    class_name.presence || class_namea.presence || class_code.to_s
  end

  def self.valid_code?(class_1:, class_code:)
    where(class_1: class_1, class_code: class_code).exists?
  end
end
