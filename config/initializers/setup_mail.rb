ActionMailer::Base.delivery_method = :smtp


ActionMailer::Base.smtp_settings = {
      :address => "email-smtp.us-east-1.amazonaws.com",
      :user_name => ENV["SES_USERNAME"],
      :password => ENV["SES_PASSWORD"],
      :authentication => :login,
      :enable_starttls_auto => true
  }

# Mailgun
#ActionMailer::Base.smtp_settings = {
#    :authentication => :plain,
#    :address => "smtp.mailgun.org",
#    :port => 25,
#    :domain => "app4057330.mailgun.org ",
#    :user_name => "postmaster@app4057330.mailgun.org ",
#    :password => "..."
#}

# SendGrid
#ActionMailer::Base.smtp_settings = {
#	:address		=> "smtp.sendgrid.net",
#	:port		=> 587,
#	:domain		=> "text7.com",
#	:user_name	=> "app4057330@heroku.com",
#	:password	=> ENV["SENDGRID_PASSWORD"],
#	:authentication => "plain",
#	:enable_starttls_auto => true
#}

# GoDaddy
#ActionMailer::Base.smtp_settings = {
#	:address		=> "smtpout.secureserver.net",
#	:port		=> 80,
#	:domain		=> "text7.com",
#	:user_name	=> "u@text7.com",
#	:password	=> "...",
#	:authentication => "plain",
#	:enable_starttls_auto => true
#}

# Gmail
#ActionMailer::Base.smtp_settings = {
#	:address		=> "smtp.gmail.com",
#	:port		=> 587,
#	:domain		=> "gmail.com",
#	:user_name	=> "ugikma",
#	:password	=> "...",
#	:authentication => "plain",
#	:enable_starttls_auto => true
#}

