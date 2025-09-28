class TFeeGass < ActiveRecord::Base
  #attr_accessible :out_timing, :car_code, :gass_timing, :gass_kbn, :latitude, :longitude, :quantity, :amount
  
  # validates :out_timing, :uniqueness => {:scope => [:car_code, :gass_timing], :case_sensitive => false, :message =>"@‹‹–û‚ªd•¡‚µ‚Ä‚¢‚Ü‚·B"}
end
