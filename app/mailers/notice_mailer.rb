class NoticeMailer < ApplicationMailer

    default :charset => 'ISO-2022-JP'

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.notice_mailer.sendmail_confirm.subject
  #
  def sendmail_confirm(message, subject, to_mail, from_mail, send_file, original_file, display_name, reply_to_mail)
    #@greeting = message

    #attachments["日本語ファイル.jpg".tojis.force_encoding(Encoding::ASCII_8BIT)] = {
    #  :content => File.read(Rails.root.to_s + "/public/images/test.jpg")
    #}
    #mail(:to => to_mail, :subject => subject, :charset => 'iso-2022-jp')
    #mail(:to => to_mail, :subject => subject)

    if original_file != ""
      attachments[original_file] = {
        :content => File.read(send_file)
      }
    end
    #mail(:to => to_mail, :subject => subject, :from => from_mail) do |format|
    mail(:to => to_mail, :reply_to => "#{display_name} <#{reply_to_mail}>", :subject => subject, :from => "#{display_name} <#{from_mail}>") do |format|
      format.text { render :inline => message }
    end
  end
end
