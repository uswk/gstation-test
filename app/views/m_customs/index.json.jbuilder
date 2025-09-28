json.array!(@m_customs) do |m_custom|
  json.extract! m_custom, :cust_kbn, :cust_code, :cust_name, :latitude, :longitude
  json.url m_custom_url(m_custom, format: :json)
end