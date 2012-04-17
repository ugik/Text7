class UserMailer < ActionMailer::Base
  default :from => "u@text7.com"

	def registration_confirmation(email, subject)
		@email = email
		mail(:to => "<#{email}>", :subject => subject)
	end

	def registration_confirmation_existing(email, subject)
		@email = email
		mail(:to => "<#{email}>", :subject => subject)
	end

	def registration_email_denial(email, subject)
		@email = email
		mail(:to => "<#{email}>", :subject => subject)
	end

	def general(email, subject)
		@email = email
		mail(:to => "<#{email}>", :subject => subject)
	end


	def receipt_confirmation(user)
		@user = user
#		attachments["foo.jpg"] = File.read("#{Rails.root}/public/images/foo.jpg")
#		mail(:to => "#{user.name} <#{email}>", :subject => "Received")
		mail(:to => "<#{email}>", :subject => "Received")
	end

end

