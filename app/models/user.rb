class User < ActiveRecord::Base
  attr_accessible :cell, :settings
  serialize :settings, Hash

  validates :cell,  :presence => true,
                    :length   => { :maximum => 25 },
                    :uniqueness => { :case_sensitive => false }

end
