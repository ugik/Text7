class Group < ActiveRecord::Base
  attr_accessible :name, :settings
  serialize :settings, Hash

  validates :name,  :presence => true,
                    :length => { :in => 2..5 },
                    :uniqueness => { :case_sensitive => false }

  has_many :texts
  has_many :usergroups
end
