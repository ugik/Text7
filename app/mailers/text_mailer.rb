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
        puts message.body.decoded
    end

    mail = MMS2R::Media.new(message)        # process mail to handle MMS if sent from phone

    @email = message.from[0].to_s	# first address in array
    if mail.is_mobile?
	puts "Mobile"
        @subject = "<None>"
	@cell = mail.number
        file = mail.default_text
	text = IO.readlines(mail.media['text/plain'].first).join
#	puts "mail had text: #{text}" unless text.nil?
#      puts "cell #: #{@cell}" unless @cell.nil?

        @subject = text unless text.nil?
        file = mail.default_media
#        puts "mail had media: #{file.inspect}" unless file.nil?
	if file.inspect.include? '.txt'
		puts "but media was text" 
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
			user.settings["pings"] = 1	# keep track of times used
		end
		responder(@email, "registration_confirmation")
	else
		user.settings.["pings"] += 1
		responder(@email, "registration_existing")
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
	responder(@email,"registration_email_denial")

    end

    puts @email + " : " + @subject
    puts "**************************"

    return true
  end

# called when ready to respond to user
  def responder(email, type, subject=nil)

	@subject = subject
	@email = email
	@msg = ""
	if @email.include? 'att'	# handle at&t (use 41 chars in subject)

	end
	@user = User.find_by_cell(@email)
	@ping = @user.settings["ping"] unless @user.nil?

	case type
		when "registration_confirmation"
                                      #1234567890123456789012345678901234567890
			@msg = "You are now registered on Text7.com, Text HELP for assistance"
		when "registration_existing"
			@msg = "Text7.com visit ##{@ping}, Text HELP for assistance"
		when "registration_email_denial"
			@msg = "To register on Text7.com please Text(sms) to: u@Text7.com"
		when "general"
			@msg = subject
		else
			puts "Responder Type #{type} ?"
	end
 

	case type
		when "registration_confirmation"
			UserMailer.registration_confirmation(@email, @subject).deliver unless @email.nil?
		when "registration_confirmation_existing"
			UserMailer.registration_existing(@email, @subject).deliver unless @email.nil?
		when "registration_email_denial"
			UserMailer.registration_email_denial(@email, @subject).deliver unless @email.nil?
		when "general"
			UserMailer.general(@email, @subject).deliver unless @email.nil?
		else
		  puts "Responder Type #{type} ?"
	end
  end

end

