class TCarrun < ActiveRecord::Base
  #attr_accessible :out_timing, :car_code, :route_code, :in_timing, :input_flg, :driver_code, :sub_driver_code1, :sub_driver_code2, :use_item_flg, :mater_out, :mater_in, :run_distance

  validates :out_timing, :uniqueness => {:scope => :car_code, :message =>"　出庫日時、車両が重複しています。"}

  def self.out(t_carrun)
    out_record = self.active_record(t_carrun)
    #return nil if not out_record.nil?
    #return t_carrun.errors.full_messages if not out_record.nil?
    return 1 if not out_record.nil?
    return t_carrun.errors.full_messages unless t_carrun.save
    return nil
  end

  def self.in(t_carrun)
    out_record = self.active_record(t_carrun)
    return nil unless out_record
    out_record.in_timing = t_carrun.in_timing
    out_record.mater_out = t_carrun.mater_out
    out_record.mater_in = t_carrun.mater_in
    out_record.run_distance = t_carrun.run_distance
    out_record.updated_at = Time.now
    return out_record.errors.full_messages unless out_record.save
    return nil
  end

  def self.active_record(t_carrun)
    #out_records = TCarrun.where(:car_code => t_carrun.car_code,:out_timing => t_carrun.out_timing,:in_timing => nil)
    out_records = TCarrun.where(:car_code => t_carrun.car_code,:out_timing => t_carrun.out_timing)
    return out_records.first
  end

end
