class CreateMRoutePointRundates < ActiveRecord::Migration[8.0]
  def change
    create_table :m_route_point_rundates do |t|
      t.references :m_route_point, null: false, foreign_key: true

      # m_combos で管理されるコード値たち
      t.integer :run_week, null: false, default: 0  # 0: 毎週, 1..5: 第N週
      t.integer :run_yobi, null: false             # 0..6 : 日..土
      t.integer :item_kbn, null: false             # class_1 = 4（収集品目）
      t.integer :unit_kbn                          # class_1 = 21（単位）
      t.string  :itaku_code                        # 委託先（任意）

      t.timestamps
    end

    add_index :m_route_point_rundates,
              [:m_route_point_id, :run_week, :run_yobi, :item_kbn],
              unique: true,
              name: "idx_point_rundates_on_point_week_yobi_item"

    add_index :m_route_point_rundates, :item_kbn
    add_index :m_route_point_rundates, :run_yobi
    add_index :m_route_point_rundates, :run_week
  end
end
