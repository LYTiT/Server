class LytSphere < ActiveRecord::Base
  belongs_to :venue

  def self.create_new_sphere(v)
  	if v.l_sphere != nil
	  	lyt_sphere = LytSphere.new(:venue_id => v.id, :sphere => v.l_sphere)
		lyt_sphere.save
	end
  end

end
