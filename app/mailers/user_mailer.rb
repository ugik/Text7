class UserMailer < ActionMailer::Base
  default :from => "ugikma@gmail.com"

	def registration_confirmation(email)
		@email = email
#		mail(:to => "#{user.name} <#{email}>", :subject => "Registered")
		mail(:to => "<#{email}>", :subject => "Registered")
	end

	def receipt_confirmation(user)
		@user = user
#		attachments["foo.jpg"] = File.read("#{Rails.root}/public/images/foo.jpg")
#		mail(:to => "#{user.name} <#{email}>", :subject => "Received")
		mail(:to => "<#{email}>", :subject => "Received")
	end

end

