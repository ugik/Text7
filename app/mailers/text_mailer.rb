class TextMailer < ActionMailer::Base

  # Create an attachment file with some paperclip aware features
#  class AttachmentFile < Tempfile
#   attr_accessor :original_filename, :content_type
#  end

  # Called whenever a message is received on the incoming mail controller
  def receive(message)
    # For now just take the first attachment and assume there is only one
    attachment = message.attachments.first

    puts "**************************"
#    puts "Inspect:"+ message.inspect
    puts "Date: "+ message.date.to_s

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
	puts "Msg text: #{text}" unless text.nil?
        puts "cell #: #{@cell}" unless @cell.nil?

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

	persist_text(message.date, @email, @subject)	# Create/Update User and Text

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

    puts @email + " : " + @subject + " : " + message.date.to_s
    puts "**************************"

    return true
  end

# called when ready to respond to user
  def responder(email, subject, type="response")

	user = User.find_by_cell(email)
	pings = user.settings["pings"] unless user.nil?

	single_response = true
	
	case type
		when "registration_confirmation"
			subject = "You are now registered, welcome."
			body = "Reply HELP for assistance"
		when "process_existing"
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

			if !response["alias"].nil?
				# check if alias is 5 alphanumeric chars
				valid = false
				user_alias = response["alias"]
				if (user_alias.size=5 and user_alias.scan(/[a-z0-9#]+/i).size=1)    # is alphanumeric
					if user_alias.scan(/[a-z0-9#]+/i)[0].size=5	# and still 5 in length
						valid = true
					end
				end
				if valid
					user.settings["alias"]=user_alias
					user.save
					subject = "Alias #{alias} is set"
					body = ""
				else
					subject = "Alias must be 5 letters/numbers"
					body = ""
				end
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
			end
		end
		sender(email, "Sent #{User.count-1} msgs")	# echo back number of msgs sent
	end
  end

# called to send text
  def sender (email, subject="", body="", logo=false)
	subject = "" if subject.nil?
	body = "" if body.nil?

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

	user = User.find_by_cell(email)

	sub = subject.split[0...1][0].upcase	unless subject.nil?   # get first word from subject
	response = {}
	case sub
		when "HELLO"
                                                   #1234567890123456789012345678901234567890123456789
			replies=["Hello, thanks for texting", "Hi, thanks for using Text7", "Check out www.Text7.com", "Let your friends know about Text7", "Remember to text HELP for assistance", "What's up?", "How you doing'?", "Text7 is #1 in group texting!", "See you again soon.", "Thanks for using Text7"]
			response["subject"]=replies[rand(replies.length)]
		when "HELP"
                                                   #1234567890123456789012345678901234567890123456789
			response["subject"]="HELP | HELLO | ALL {msg} | ALIAS {alias}"
#			response["subject"]="HELP | CREATE {group} |  JOIN {group}"
#			response["body"]="MSG {group} | LEAVE {group} | DELETE {group}"
		when "ALIAS"
			if subject.split[1...2][0].nil?	# handle ALIAS with no 2nd parameter
				if user.settings["alias"].nil?
					response["subject"]="No alias, text ALIAS {alias} to set"
				else
					response["subject"]="Your alias is #{user.settings["alias"]}"
				end
			else
				response["alias"]=subject.split[1...2][0].upcase unless subject.nil?	# get alias
			end
		when "ALL"
			response["all"]=true
			response["subject"]=email[email.index("@")-4,4] unless email.index("@").nil?
			response["subject"]=user.settings["alias"] unless user.settings["alias"].nil?
			puts "ALIAS #{user.settings["alias"] unless user.settings["alias"].nil?
			response["body"]=subject.split[1...99].join(' ')	# the msg with whitespaces trimmed
		else
			puts "Not sure how to process command: '#{subject}'"
			response["blank"]=true
	end
	return response
  end

# called to persist inbound messages
  def persist_text(sent, email, subject)
	new_user = false
	duplicate = false

	user = User.find_by_cell(email)
	if user.nil?
		User.create do |user|	# create the user
			user.cell = email
			user.settings["pings"]=1	# keep track of times used
		end
		new_user = true
	else
		if user.settings["pings"].nil?
			user.settings["pings"]=1
		else
			user.settings["pings"]+=1
		end
		user.save
	end

	user = User.find_by_cell(email)
        text = Text.find(:first, :conditions => { :sent => sent, :user_id => user.id }) unless user.nil?
	if text.nil?
		Text.create do |t|	# create the user
			t.sent = sent
			t.user_id = user.id
			t.subject = subject
			t.settings["pings"]=1	# keep track of times used
		end
	else
		puts "=> Duplicate Text"		# no 2 inbound texts with same datetime + user
		if text.settings["pings"].nil?
			text.settings["pings"]=1
		else
			text.settings["pings"]+=1
		end
		text.save
		duplicate = true
	end

	if !duplicate
		if new_user
			responder(email, subject, "registration_confirmation")
		else
			responder(email, subject, "process_existing")
		end
	end
  end

end

