ActionMailer::Base.delivery_method = :smtp

# SendGrid
ActionMailer::Base.smtp_settings = {
	:address		=> "smtp.sendgrid.net",
	:port		=> 587,
	:domain		=> "text7.com",
	:user_name	=> "app4057330@heroku.com",
	:password	=> "cassimere",
	:authentication => "plain",
	:enable_starttls_auto => true
}

# GoDaddy
#ActionMailer::Base.smtp_settings = {
#	:address		=> "smtpout.secureserver.net",
#	:port		=> 80,
#	:domain		=> "text7.com",
#	:user_name	=> "u@text7.com",
#	:password	=> "cassimere",
#	:authentication => "plain",
#	:enable_starttls_auto => true
#}

# Gmail
#ActionMailer::Base.smtp_settings = {
#	:address		=> "smtp.gmail.com",
#	:port		=> 587,
#	:domain		=> "gmail.com",
#	:user_name	=> "ugikma",
#	:password	=> "cassimere",
#	:authentication => "plain",
#	:enable_starttls_auto => true
#}

