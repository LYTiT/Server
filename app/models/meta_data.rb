class MetaData < ActiveRecord::Base
	belongs_to :venue
	belongs_to :venue_comment

	searchable do 
		text :meta
	end

	def self.m_search(q)
		meta_search = MetaData.search do
			fulltext q
		end
		return meta_search.results
	end
end