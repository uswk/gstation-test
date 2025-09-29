# frozen_string_literal: true

class ComboCodeValidator < ActiveModel::EachValidator
  # Usage:
  #   validates :run_week, combo_code: { class_1: MCombo::CLASS_WEEK }
  #   validates :unit_kbn, combo_code: { class_1: MCombo::CLASS_UNIT, allow_blank: true }
  def validate_each(record, attribute, value)
    return if value.blank? && options[:allow_blank]

    required_class1 = options.fetch(:class_1)
    unless MCombo.valid_code?(class_1: required_class1, class_code: value)
      record.errors.add(attribute, "は m_combos(class_1=#{required_class1}) に存在するコードを指定してください")
    end
  end
end

