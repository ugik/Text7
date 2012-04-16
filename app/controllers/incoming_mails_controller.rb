class IncomingMailsController < ApplicationController    
  require 'mail'
  skip_before_filter :verify_authenticity_token

  def create
    stuff = TextMailer.receive(Mail.new(params[:message]))

     if !stuff
	render :text => "Success", :status => 201, :content_type => Mime::TEXT.to_s
    else
	render :text => stuff.errors.full_messages.join(', '), :status => 422, :content_type => Mime::TEXT.to_s
    end

    # Do some other stuff with the mail message

  end
end

