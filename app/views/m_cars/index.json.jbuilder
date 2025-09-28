json.array!(@m_cars) do |m_car|
  json.extract! m_car, :car_code, :car_reg_code, :section_code, :car_maker, :type_code, :itaku_code
  json.url m_car_url(m_car, format: :json)
end