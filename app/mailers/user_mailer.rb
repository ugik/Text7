class UserMailer < ActionMailer::Base
  default :from => "u@text7.com"

	def general(email, subject, from, body=nil, logo=false)
		@email = email
		@content = body

		attachments["Text7.png"] = File.read("#{Rails.root}/public/images/Text7.png") if logo

		if from.nil?
			mail(:to => "<#{email}>", :subject => subject)
		else
			mail(:to => "<#{email}>", :from => from, :subject => subject)
		end
	end


	def receipt_confirmation(user)
		@user = user
#		attachments["foo.jpg"] = File.read("#{Rails.root}/public/images/foo.jpg")
#		mail(:to => "#{user.name} <#{email}>", :subject => "Received")
		mail(:to => "<#{email}>", :subject => "Received")
	end

end

