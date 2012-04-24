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

    email = message.from[0].to_s	# first address in array
    if mail.is_mobile?
        subject = "<None>"
	cell = mail.number
        file = mail.default_text
	text = IO.readlines(mail.media['text/plain'].first).join unless mail.media['text/plain'].nil?
	puts "Msg text: #{text}" unless text.nil?
        puts "cell #: #{@cell}" unless @cell.nil?

        subject = text unless text.nil?
        file = mail.default_media
#        puts "mail had media: #{file.inspect}" unless file.nil?
	if file.inspect.include? '.txt'
#		puts "but media was text" 
	else
#		avatar_file = file 
	end

	if email.include? 'att'	# handle at&t cell, switch to mms
		email.gsub!('txt','mms')
	end

	persist_text(message.date, email, subject)	# Create/Update User and Text

    else
	subject = message.subject

        # Create an AttachmentFile subclass of a tempfile with paperclip aware features and add it
	if attachment!=nil
#	        avatar_file = AttachmentFile.new('test.jpg')
#        	avatar_file.write attachment.decoded.force_encoding("utf-8")
#     		avatar_file.flush
#        	avatar_file.original_filename = attachment.filename
#       	avatar_file.content_type = attachment.mime_type
	end
	responder(email, subject, "registration_email_denial")

    end

    subject ||= ""
    puts email + " : " + subject.to_s
    puts "**************************"

    return true
  end

# called when ready to respond to user
  def responder(email, subject, type="response")

	keyWords = ["HELLO", "ALIAS", "JOIN", "DROP", "MAKE", "GROUP"]

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
				# check if alias is 2-5 alphanumeric chars
				alias_valid = false
				user_alias = response["alias"]
				if (user_alias.size.between?(2,5) and 
                                    user_alias.scan(/[a-z0-9#]+/i).length==1)
					if user_alias.scan(/[a-z0-9#]+/i)[0].size.between?(2,5)
						alias_valid = true
					end
				end
				if alias_valid
					user.settings["alias"]=user_alias
					user.save
					subject = "Alias #{user_alias} is set"
					body = ""
				else
					subject = "Alias must be 2-5 letters/numbers"
					body = ""
				end
			end

			if !response["make"].nil?
				# check if make name is 2-5 alphanumeric chars
				make_valid = false
				user_make = response["make"]
				if user_make.upcase == "GROUP"	# make a default group name using last 4 digs of cell
					user_make = email[email.index("@")-4,4] unless email.index("@").nil?
				end
				if (user_make.size.between?(2,5) and 
                                    user_make.scan(/[a-z0-9#]+/i).length==1)
					if user_make.scan(/[a-z0-9#]+/i)[0].size.between?(2,5)
						make_valid = true
					end
				end
				if make_valid
					if !keyWords.include? user_make	# check list of key words

						group = Group.find_by_name(user_make.upcase)
						if group.nil?
							Group.create do |group|	# create the user
								group.name = user_make.upcase
							end
							group = Group.find_by_name(user_make.upcase)
							if !group.nil?
								Usergroup.create do |usergroup|		# create the usergroup
									usergroup.user_id = user.id
									usergroup.group_id = group.id
									usergroup.owner = true	
								end
puts "= DEFAULT-GROUP: #{group.id}"
								user.settings["defaut-group"]=group.id
								user.save
							end
							subject = "Group #{user_make} created"
							body = ""
						else
							if user.settings["defaut-group"]==group.id
								subject = "You are texting to this group already"
								body = "Text GROUP to see your texting group"
							else
								subject = "Group #{user_make} already exists"
								body = "Text MAKE <group> to create group"
							end
						end
					else
						subject = "Group name cannot be a Text7 command"
						body = ""
					end
				else
					subject = "Group must be 2-5 letters/numbers"
					body = ""
				end
			end

			if !response["join"].nil?
				user_join = response["join"]
				group = Group.find_by_name(user_join.upcase)
				if !group.nil?
				        ug = Usergroup.find(:first, :conditions => { :user_id => user.id, :group_id => group.id }) unless user.nil?
					if ug.nil?
						Usergroup.create do |usergroup|		# create the usergroup
							usergroup.user_id = user.id
							usergroup.group_id = group.id
							usergroup.owner = false
						end
puts "= DEFAULT-GROUP: #{group.id}"
						user.settings["defaut-group"]=group.id
						user.save
						subject = "You joined group #{user_join}"
						body = ""
					else
						subject ="You are allready in group:#{user_join}"
						body = ""
					end
				else
					subject = "Group #{user_join} doesn't exist"
					body = ""
				end
			end

			if !response["group"].nil?
				user_group = response["group"]
				if user_group == "default"
					user_group = user.settings["defaut-group"]
					group = Group.find_by_id(user_group) unless user_group.nil?
					subject = "You are texting in group #{group.name}" unless group.nil?
					body = ""
				else
					group = Group.find_by_name(user_group.upcase)
					if !group.nil?
					        ug = Usergroup.find(:first, :conditions => { :user_id => user.id, :group_id => group.id }) unless user.nil?
						if !ug.nil?
	puts "= DEFAULT-GROUP: #{group.id}"
							user.settings["defaut-group"]=group.id
							user.save
							subject = "Now texting to group #{user_group}"
							body = ""
						else
							subject ="You are not in group:#{user_group}"
							body = ""
						end
					else
						subject = "Group #{user_group} doesn't exist"
						body = ""
					end
				end
			end

			if !response["drop"].nil?
				user_drop=response["drop"]
				group = Group.find_by_name(user_drop.upcase)
				if group.nil?
					subject = "Group #{user_drop} doesn't exist"
					body = ""
				else
				        ug = Usergroup.find(:first, :conditions => { :user_id => user.id, :group_id => group.id }) unless user.nil?
					puts "DROPPING GROUP user_id: #{user.id}, group_id: #{group.id}"
					if !ug.nil?
						if ug.owner
							group.delete
							ug.delete
							subject = "Group #{user_drop} dropped"
							body = ""
						else
							subject ="You are not the owner of this group"
							body = ""
						end
					end
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

	if (subject.to_s+body.to_s).length>1
		if single_response	# single response cases
			sender(email, subject, body)
		else		# responses to multiple users
			User.find_each do |user|
				if user.cell!=email		# don't send msg to sender
					sender(user.cell, subject, body)
				end
			end
			group = user.settings["defaut-group"]
			if group.nil?
				sender(email, "Sent #{User.count-1} msgs")	# echo back number of msgs sent
			else
				sender(email, "#{User.count-1} msgs to #{group}")	# echo back number of msgs sent
			end
		end
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
			response["subject"]="HELP | HELLO | ALL <msg> | ALIAS <name>"
			response["body"]=   "MAKE <group> | DROP <group> | JOIN <group>"

		when "ALIAS"
			if subject.split[1...2][0].nil?	# handle ALIAS with no 2nd parameter
				if user.settings["alias"].nil?
					response["subject"]="No alias, text ALIAS {alias} to set"
				else
					response["subject"]="Your alias is #{user.settings["alias"]}"
				end
			else
				response["alias"]=subject.split[1...2][0] unless subject.nil?	# get alias
			end

		when "MAKE"
			if subject.split[1...2][0].nil?	# handle MAKE with no 2nd parameter
				response["subject"]="Text MAKE {name} to create group"
			else
				response["make"]=subject.split[1...2][0] unless subject.nil?	# get make group name
			end

		when "JOIN"
			if subject.split[1...2][0].nil?	# handle JOIN with no 2nd parameter
				response["subject"]="Text JOIN {name} to join group"
			else
				response["join"]=subject.split[1...2][0] unless subject.nil?	# get join group name
			end

		when "DROP"
			if subject.split[1...2][0].nil?	# handle MAKE with no 2nd parameter
				response["subject"]="Text DROP {name} to delete group you made"
			else
				response["drop"]=subject.split[1...2][0] unless subject.nil?	# get drop group name
			end

		when "GROUP"
			if subject.split[1...2][0].nil?	# handle GROUP with no 2nd parameter
				response["group"]="default"	# display current default group
			else
				response["group"]=subject.split[1...2][0] unless subject.nil?	# get  group name
			end

		when "ALL"
			response["all"]=true
			response["subject"]=email[email.index("@")-4,4] unless email.index("@").nil?	# last 4 digits of cell #
			response["subject"]=user.settings["alias"] unless user.settings["alias"].nil?
			puts "ALIAS #{user.settings["alias"]}" unless user.settings["alias"].nil?
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

