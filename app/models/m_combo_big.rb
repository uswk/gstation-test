class MComboBig < ActiveRecord::Base
  #attr_accessible :class_1, :class_name, :class_namea, :system_name, :system_flg, :delete_flg

  validates :class_1,  :uniqueness => {:message =>"　大分類コードが重複しています。"}
end
