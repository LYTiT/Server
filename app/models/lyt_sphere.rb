class LytSphere < ActiveRecord::Base
  belongs_to :venue

  def self.create_new_sphere(v)
  	lyt_sphere = LytSphere.new(:venue_id => v.id, :sphere => v.l_sphere)
	lyt_sphere.save
  end

end
