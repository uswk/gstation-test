class TCarrunList < ActiveRecord::Base
  #attr_accessible :out_timing,:car_code, :tree_no, :work_kind, :work_kbn, :latitude, :longitude, :address, :work_timing, :note, :end_timing

  def self.status(t_carrun_list)
    list_record = self.active_record(t_carrun_list)
    if  list_record
       list_record.latitude = t_carrun_list.latitude
       list_record.longitude = t_carrun_list.longitude
       list_record.address = t_carrun_list.address
       list_record.work_timing = t_carrun_list.work_timing
       return list_record.errors.full_messages unless list_record.save
    else
       return t_carrun_list.errors.full_messages unless t_carrun_list.save
       return nil
    end
  end

  def self.active_record(t_carrun_list)
    list_records = TCarrunList.where(:car_code => t_carrun_list.car_code,:out_timing => t_carrun_list.out_timing,:tree_no => t_carrun_list.tree_no)
    return list_records.first
  end

end