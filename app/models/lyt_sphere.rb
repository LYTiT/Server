class LytSphere < ActiveRecord::Base
  belongs_to :venue

  def self.create_new_sphere(v)
  	if v.l_sphere != nil
  		begin
	  		LytSphere.create!(:venue_id => v.id, :sphere => v.l_sphere)
		rescue
			puts "Could not create LytSphere"
		end
	end
  end

end
