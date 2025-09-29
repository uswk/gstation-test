class CreateMCustomRundates < ActiveRecord::Migration[7.1] # ← 既存に合わせて
  def change
    create_table :m_custom_rundates do |t|
      t.references :m_custom, null: false, foreign_key: true

      # m_combos によるコード値
      t.integer :run_week, null: false, default: 0  # 0: 毎週, 1..5: 第N週
      t.integer :run_yobi, null: false             # 0..6: 日..土
      t.integer :item_kbn, null: false            # class_1=4（品目）
      t.integer :unit_kbn                         # class_1=21（単位）
      t.string  :itaku_code                       # 任意：委託先コード

      t.timestamps
    end

    add_index :m_custom_rundates,
              [:m_custom_id, :run_week, :run_yobi, :item_kbn],
              unique: true,
              name: "idx_custom_rundates_on_mcustom_and_week_yobi_item"

    add_index :m_custom_rundates, :run_week
    add_index :m_custom_rundates, :run_yobi
    add_index :m_custom_rundates, :item_kbn
  end
end
