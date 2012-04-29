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
    to_address = message.to[0].to_s   # explicitly named to address

    if mail.is_mobile? or email == "ugikma@gmail.com"
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

	persist_text(message.date, email, to_address, subject)	# Create/Update User and Text

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
	responder(email, subject, to_address, "registration_email_denial")

    end

    subject ||= ""
    puts email + " : " + subject.to_s
    puts "**************************"

    return true
  end

# called when ready to respond to user
  def responder(email, subject, to_address, type="response")

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

			if response["all"] or response["group-msg"]
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
					if !keyWords.include? user_make.upcase	# check list of key words

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
								user.settings["default-group"]=group.id
								user.save
							end
							subject = "#{user_make} created"
                                                                   #012345678901234567890123456789
							body = "others can text: JOIN #{user_make}"
						else
							if user.settings["default-group"]==group.id
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
puts "Usergroup created for User: #{user.id} Group: #{group.id}"
						end
						user.settings["default-group"]=group.id
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
					user_group = user.settings["default-group"]
					group = Group.find_by_id(user_group) unless user_group.nil?
					subject = "You are texting in group #{group.name}" unless group.nil?
					body = ""
				else
					group = Group.find_by_name(user_group.upcase)
					if !group.nil?
					        ug = Usergroup.find(:first, :conditions => { :user_id => user.id, :group_id => group.id }) unless user.nil?
						if !ug.nil?
							puts "= DEFAULT-GROUP: #{group.id}"
							user.settings["default-group"]=group.id
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
							group.destroy
							subject = "Group #{user_drop} dropped"
							body = ""
						else
							ug.delete
							subject ="You are no longer in group #{user_drop}"
							body = ""
						end
					end
				        ug = Usergroup.find(:first, :conditions => { :user_id => user.id }) unless user.nil?
					if !ug.nil? and !ug.group.nil?
						user.settings["default-group"]=ug.group_id
						user.save
						body = "Now texting in group #{ug.group.name}"
					else
						user.settings["default-group"]=nil
						user.save
						subject ="You are no longer in a group"
						body = "Text MAKE GROUP to create new one"
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

			sender(email, subject, to_address, body)
                        if type == "registration_confirmation"
				sender(email, "#{email} registered", to_address, "")	# confirmation email
			end
		else		# responses to multiple users
			count = 0
			if response["all"]	# response to all
				User.find_each do |user|
					if user.cell!=email		# don't send msg to sender
						sender(user.cell, subject, to_address, body)
					end
				end
				count = User.count-1
				sender(email, "Sent #{count} msgs", to_address)	# echo back number of msgs sent
			else		# response to group
				explicit_group = to_address[0, to_address.index("@")] unless to_address.index("@").nil?
 				if !explicit_group.nil? and explicit_group!="u"
					puts "Explicit group: #{explicit_group}"
					grp  = Group.find_by_name(explicit_group.upcase)
					if !grp.nil?
						default_group = grp.id
					else
						sender(email, "No group named #{explicit_group}", to_address) 
					end
				else
					default_group = user.settings["default-group"]
				end
				if !default_group.nil?
					group = Group.find_by_id(default_group)
					@usergroup = Usergroup.find_all_by_group_id(group.id)
					count = 0
					@usergroup.each do |ug|
						if !ug.user.nil? and ug.user.cell!=email	 # don't send msg to sender
							sender(ug.user.cell, subject, to_address, body)
							count+=1
						end
					end
					sender(email, "sent #{count} msgs to group:#{group.name}", to_address) # echo back number of msgs sent
				end
			end
		end
	end
  end

# called to send text
  def sender (email, subject, from, body="", logo=false)
	subject = "" if subject.nil?
	body = "" if body.nil?

	if email.include? 'att'	# handle at&t (use 41 char CHUNKS in subject, no body)
		if (subject+body).length<39	# can it fit in subject?
			UserMailer.general(email, subject+" / "+body, from).deliver
		else
			UserMailer.general(email, subject, from).deliver
			UserMailer.general(email, body[0..40], from).deliver if body.length>0
			UserMailer.general(email, body[41..80], from).deliver if body.length>40
			UserMailer.general(email, body[81..120], from).deliver if body.length>80
		end
	else
		UserMailer.general(email, subject, from, body).deliver unless email.nil?
	end

  end

# called when processing user request
  def processor(email, subject)

	user = User.find_by_cell(email)

	sub = subject.split[0...1][0].upcase	unless subject.nil?   # get first word from subject
	response = {}
	case sub
		when "HELLO"
			replies=["Hello, thanks for texting", "Hi, thanks for using Text7", "Check out www.Text7.com", "Let your friends know about Text7", "Remember to text HELP for assistance", "What's up?", "How you doing'?", "Text7 is #1 in group texting!", "See you again soon.", "Thanks for using Text7"]
			response["subject"]=replies[rand(replies.length)]
		when "HELP"
                                                       #1234567890123456789012345678901234567890123456789
			response["subject"]="HELP | ALIAS name | MAKE GROUP"
			response["body"]=   "MAKE group | DROP group | JOIN group"

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
			# handle non-command text
			if user.settings["default-group"].nil?
				puts "Not sure how to process command: '#{subject}'"
				response["blank"]=true
			else
				response["group-msg"]=true
				response["subject"]=email[email.index("@")-4,4] unless email.index("@").nil?	# last 4 digits of cell #
				response["subject"]=user.settings["alias"] unless user.settings["alias"].nil?
				puts "GROUP MSG, ALIAS #{user.settings["alias"]}" unless user.settings["alias"].nil?
				response["body"]=subject.split[0...99].join(' ')	# the msg with whitespaces trimmed
			end
	end
	return response
  end

# called to persist inbound messages
  def persist_text(sent, email, to_address, subject)
	new_user = false
	duplicate = false

	user = User.find_by_cell(email)
	if user.nil?
		User.create do |user|	# create the user
			user.cell = email
			user.settings["pings"]=1	# keep track of times used
		end

		user = User.find_by_cell(email)
		explicit_group = to_address[0, to_address.index("@")] unless to_address.index("@").nil?
		if !explicit_group.nil? and explicit_group!="u"
			puts "Explicit group: #{explicit_group}"
			group  = Group.find_by_name(explicit_group.upcase)
			if group.nil?
				Group.create do |new_group|		# create the usergroup if necessary
					new_group.name = explicit_group.upcase
puts "Registration Group created: #{new_group.name}"
				end
			end
			group  = Group.find_by_name(explicit_group.upcase)
puts "Group: #{group.inspect}"
		        ug = Usergroup.find(:first, :conditions => { :user_id => user.id, :group_id => group.id }) unless user.nil?
			if ug.nil?
				Usergroup.create do |new_usergroup|		# create the usergroup if necessary
					new_usergroup.user_id = user.id
					new_usergroup.group_id = group.id
					new_usergroup.owner = false
puts "Registration Usergroup created for User: #{user.id} Group: #{group.id}"
				end
			end
			user.settings["default-group"]=group.id
			user.save
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
	if text.nil? and subject.length<256
		Text.create do |t|	# create the user
			t.sent = sent
			t.user_id = user.id
			t.subject = subject
			t.settings["pings"]=1	# keep track of times used
		end
	else
		puts "=> Duplicate Text"		# no 2 inbound texts with same datetime + user
		if !text.nil?
			if text.settings["pings"].nil?
				text.settings["pings"]=1
			else
				text.settings["pings"]+=1
			end
			text.save
		end
		duplicate = true
	end

	if !duplicate
		sub = subject.split[0...1][0].upcase	unless subject.nil? 		# get command
		if new_user 	# new registration
			responder(email, subject, to_address, "registration_confirmation")
		end
		responder(email, subject, to_address, "process_existing")
	end
  end

end

