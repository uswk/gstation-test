class MCar < ActiveRecord::Base
  #attr_accessible :car_code, :car_reg_code, :section_code, :car_maker, :type_code, :itaku_code, :delete_flg
  
  validates :car_code,  :uniqueness => {:case_sensitive => false, :message =>"　車両コードが重複しています。"}

end
