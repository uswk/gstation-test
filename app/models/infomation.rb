class Infomation < ActiveRecord::Base
  #attr_accessible :info_date, :info_message

  validates_presence_of :info_date, :message => "　日付は入力必須です。"
  validates_presence_of :info_message, :message => "　メッセージは入力必須です。"
end
