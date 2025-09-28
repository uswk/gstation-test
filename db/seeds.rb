require 'csv'

User.find_or_create_by!(user_id: 'admin') do |admin|
  admin.user_name = '管理者'
  admin.password = 'uswkadmin2160'
  admin.authority = 1
  admin.login_authority = 1
end

MCombo.delete_all
CSV.foreach(Rails.root.join('db', 'seeds', 'm_combos.csv'), headers: true) do |row| MCombo.create(row.to_hash) end

MComboBig.delete_all
CSV.foreach(Rails.root.join('db', 'seeds', 'm_combo_bigs.csv'), headers: true) do |row| MComboBig.create(row.to_hash) end
