class MetaData < ActiveRecord::Base
	belongs_to :venue
	belongs_to :venue_comment

	def self.increment_relevance_score(data, v_id)
		md = MetaData.where("meta = ? AND venud_id = ?", data, v_id).first
		relevance_half_life = 360.0

		begin
			old_score = md.relevance_score
			new_score = old_score * 2 ** ((-(Time.now - md.updated_at)/60.0) / (relevance_half_life)).round(4)+1.0
			md.update_columns(relevance_score: new_score)
		rescue
			puts "Could not locate MetaData object"
		end
	end

	def increment_relevance_score
		relevance_half_life = 360.0 #minutes
		old_score = relevance_score
		new_score = old_score * 2 ** ((-(Time.now - updated_at)/60.0) / (relevance_half_life)).round(4)+1.0
		update_columns(relevance_score: new_score)
	end

	def update_and_return_relevance_score
		relevance_half_life = 360.0
		old_score = self.relevance_score
		new_score = old_score * 2 ** ((-(Time.now - self.updated_at)/60.0) / (relevance_half_life)).round(4)+1.0
		self.update_columns(relevance_score: new_score)
		return self.relevance_score
	end

	def self.cluster_top_meta_tags(venue_ids)
		venue_count = venue_ids.count
		sql = "SELECT meta, SUM(relevance_score)*(COUNT(distinct (case when venue_id IN (#{venue_ids}) then venue_id end))) AS weighted_avg FROM meta_data WHERE venue_id IN (#{venue_ids}) GROUP BY meta ORDER BY weighted_avg DESC LIMIT 5"
		results = ActiveRecord::Base.connection.execute(sql)
	end
end