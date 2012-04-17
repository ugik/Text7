class UserMailer < ActionMailer::Base
  default :from => "u@text7.com"

	def registration_confirmation(email)
		@email = email
#		mail(:to => "#{user.name} <#{email}>", :subject => "Registered")
		mail(:to => "<#{email}>", :subject => "Registered")
	end

	def registration_confirmation_existing(email)
		@email = email
#		mail(:to => "#{user.name} <#{email}>", :subject => "Already Registered")
		mail(:to => "<#{email}>", :subject => "Already Registered")
	end

	def registration_email_denial(email)
		@email = email
#		mail(:to => "#{user.name} <#{email}>", :subject => "Please register via sms text")
		mail(:to => "<#{email}>", :subject => "Please register via sms text")
	end

	def receipt_confirmation(user)
		@user = user
#		attachments["foo.jpg"] = File.read("#{Rails.root}/public/images/foo.jpg")
#		mail(:to => "#{user.name} <#{email}>", :subject => "Received")
		mail(:to => "<#{email}>", :subject => "Received")
	end

end

