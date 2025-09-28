json.array!(@m_combo_bigs) do |m_combo_big|
  json.extract! m_combo_big, :class_1, :class_name, :class_namea, :system_name, :system_flg
  json.url m_combo_big_url(m_combo_big, format: :json)
end