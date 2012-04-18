class UserMailer < ActionMailer::Base
  default :from => "u@text7.com"


	def general(email, subject, body=nil, logo=false)
		@email = email
		@body = body

puts "Body: "+ @body
		@test = "12345"

		attachments["Text7.png"] = File.read("#{Rails.root}/public/images/Text7.png") if logo

		mail(:to => "<#{email}>", :subject => subject)
	end


	def receipt_confirmation(user)
		@user = user
#		attachments["foo.jpg"] = File.read("#{Rails.root}/public/images/foo.jpg")
#		mail(:to => "#{user.name} <#{email}>", :subject => "Received")
		mail(:to => "<#{email}>", :subject => "Received")
	end

end

