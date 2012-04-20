class Text < ActiveRecord::Base
  attr_accessible :sent, :subject, :body, :settings
  serialize :settings, Hash


  belongs_to :user

end
