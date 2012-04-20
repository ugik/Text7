class User < ActiveRecord::Base
  attr_accessible :cell, :settings
  serialize :settings, Hash

  validates :cell,  :presence => true,
                    :length   => { :maximum => 45 },
                    :uniqueness => { :case_sensitive => false }

  has_many :texts

end
