json.array!(@t_carruns) do |t_carrun|
  json.extract! t_carrun, :out_timing, :car_code, :route_code, :in_timing
  json.url t_carrun_url(t_carrun, format: :json)
end