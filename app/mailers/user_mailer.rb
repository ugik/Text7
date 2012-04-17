class UserMailer < ActionMailer::Base
  default :from => "u@text7.com"


	def general(email, subject, body="")
		@email = email
		@body = body
		mail(:to => "<#{email}>", :subject => subject)
	end


	def receipt_confirmation(user)
		@user = user
#		attachments["foo.jpg"] = File.read("#{Rails.root}/public/images/foo.jpg")
#		mail(:to => "#{user.name} <#{email}>", :subject => "Received")
		mail(:to => "<#{email}>", :subject => "Received")
	end

end

