class TextMailer < ActionMailer::Base

  # Create an attachment file with some paperclip aware features
#  class AttachmentFile < Tempfile
#   attr_accessor :original_filename, :content_type
#  end

  # Called whenever a message is received on the movies controller
  def receive(message)
    # For now just take the first attachment and assume there is only one
    attachment = message.attachments.first

    puts "**************************"
    if message.body.decoded.include? 'confirmation code'	# handle email forwarding verification
#        puts message.body.decoded
    end

    mail = MMS2R::Media.new(message)        # process mail to handle MMS if sent from phone

    @email = message.from[0].to_s	# first address in array
    if mail.is_mobile?
        @subject = "<None>"
	@cell = mail.number
        file = mail.default_text
	text = IO.readlines(mail.media['text/plain'].first).join unless mail.media['text/plain'].nil?
#	puts "mail had text: #{text}" unless text.nil?
#      puts "cell #: #{@cell}" unless @cell.nil?

        @subject = text unless text.nil?
        file = mail.default_media
#        puts "mail had media: #{file.inspect}" unless file.nil?
	if file.inspect.include? '.txt'
#		puts "but media was text" 
	else
#		avatar_file = file 
	end

	if @email.include? 'att'	# handle at&t cell, switch to mms
		@email.gsub!('txt','mms')
	end

	@user = User.find_by_cell(@email)
	if @user.nil?
		User.create do |user|	# create the user
			user.cell = @email
			user.settings["pings"]=1	# keep track of times used
		end
		responder(@email, @subject, "registration_confirmation")
	else
		if @user.settings["pings"].nil?
			@user.settings["pings"]=1
		else
			@user.settings["pings"]+=1
		end
		@user.save
		responder(@email, @subject, "registration_existing")
	end
    else
	@subject = message.subject

        # Create an AttachmentFile subclass of a tempfile with paperclip aware features and add it
	if attachment!=nil
#	        avatar_file = AttachmentFile.new('test.jpg')
#        	avatar_file.write attachment.decoded.force_encoding("utf-8")
#     		avatar_file.flush
#        	avatar_file.original_filename = attachment.filename
#       	avatar_file.content_type = attachment.mime_type
	end
	responder(@email, @subject, "registration_email_denial")

    end

    puts @email + " : " + @subject
    puts "**************************"

    return true
  end

# called when ready to respond to user
  def responder(email, subject, type="general")

	user = User.find_by_cell(email)
	pings = user.settings["pings"] unless user.nil?

	single_response = true

	case type
		when "registration_confirmation"
			subject = "You are now registered, welcome."
			body = "Reply HELP for assistance"
		when "registration_existing"
			response = processor(email, subject)
			subject = response["subject"]
			body = response["body"]

			if response["blank"]
				subject = "Visit ##{pings} Reply HELP for assistance"
				body = ""
			end

			if response["all"]
				single_response = false
			end

		when "registration_email_denial"
			subject = "To register:"
			body = "Please Text(sms) to: u@Text7.com"
		when "response"
			subject = "Text7.com"
			body = subject
		else
			puts "Responder Type #{type} ?"
	end

	if single_response	# single response cases
		sender(email, subject, body)
	else		# responses to multiple users
		User.find_each do |user|
			if user.cell!=email		# don't send msg to sender
				sender(user.cell, subject, body)
				puts "Sent msg to #{user.cell}"
			end
		end
		sender(email, "Sent #{User.count-1} msgs")
	end
  end

# called to send text
  def sender (email, subject, body=nil, logo=false)
	if email.include? 'att'	# handle at&t (use 41 char CHUNKS in subject, no body)
		if (subject+body).length<39	# can it fit in subject?
			UserMailer.general(email, subject+" / "+body).deliver
		else
			UserMailer.general(email, subject).deliver
			UserMailer.general(email, body[0..40]).deliver if body.length>0
			UserMailer.general(email, body[41..80]).deliver if body.length>40
			UserMailer.general(email, body[81..120]).deliver if body.length>80
		end
	else
		UserMailer.general(email, subject, body).deliver unless email.nil?
	end
  end

# called when processing user request
  def processor(email, subject)

	sub = subject.split[0...1][0].upcase	unless subject.nil?   # get first word from subject
	response = {}
	case sub
		when "HELLO"
                                                   #1234567890123456789012345678901234567890123456789
			response["subject"]="Hello, thanks for texting."
		when "HELP"
                                                   #1234567890123456789012345678901234567890123456789
			response["subject"]="HELP | HELLO | ALL {msg}"
#			response["subject"]="HELP | CREATE {group} |  JOIN {group}"
#			response["body"]="MSG {group} | LEAVE {group} | DELETE {group}"
		when "ALL"
			response["all"]=true
			response["subject"]=email[email.index("@")-4,4] unless email.index("@").nil?
			response["body"]=subject.split[1...99].join(' ')	# the msg with whitespaces trimmed
		else
			puts "Not sure how to process: #{subject}"
			response["blank"]=true
	end
	return response
  end
end

