class LytSphere < ActiveRecord::Base
  belongs_to :venue

  def self.create_new_sphere(v)
  	if v.l_sphere != nil && LytSphere.where("venue_id = ?", v.id).any? == false
  		LytSphere.create!(:venue_id => v.id, :sphere => v.l_sphere)
	end
  end

end
