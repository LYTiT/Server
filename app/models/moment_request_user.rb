class MomentRequestUser < ActiveRecord::Base
	belongs_to :user
	belongs_to :moment_request


end