ActionMailer::Base.smtp_settings = {
	:address		=> "smtpout.secureserver.net",
	:port		=> 3535,
	:domain		=> "text7.com",
	:user_name	=> "u",
	:password	=> "cassimere",
	:authentication => "plain"
}


#ActionMailer::Base.smtp_settings = {
#	:address		=> "smtp.gmail.com",
#	:port		=> 587,
#	:domain		=> "gmail.com",
#	:user_name	=> "ugikma",
#	:password	=> "cassimere",
#	:authentication => "plain",
#	:enable_starttls_auto => true
#}

