class Usergroup < ActiveRecord::Base
  attr_accessible :owner, :settings
  serialize :settings, Hash

  belongs_to :user
  belongs_to :group
  
  validates :user_id, :presence => true
  validates :group_id, :presence => true

end
