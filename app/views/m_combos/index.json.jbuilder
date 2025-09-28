json.array!(@m_combos) do |m_combo|
  json.extract! m_combo, :class_1, :class_2, :class_code, :class_name, :class_namea, :value, :value2, :value3, :value4, :value5, :system_flg
  json.url m_combo_url(m_combo, format: :json)
end