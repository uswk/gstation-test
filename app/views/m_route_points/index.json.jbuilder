json.array!(@m_route_points) do |m_route_point|
  json.extract! m_route_point, :route_code, :tree_no, :cust_kbn, :cust_code
  json.url m_route_point_url(m_route_point, format: :json)
end