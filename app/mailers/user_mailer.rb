class UserMailer < ActionMailer::Base
  default :from => "ugikma@gmail.com"

	def registration_confirmation(user)
		@user = user
		mail(:to => "#{user.name} <#{user.email}>", :subject => "Registered")
	end

	def receipt_confirmation(user)
		@user = user
#		attachments["foo.jpg"] = File.read("#{Rails.root}/public/images/foo.jpg")
		mail(:to => "#{user.name} <#{user.email}>", :subject => "Received")
	end

end

