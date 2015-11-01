class Search
  attr_accessor :sw_lat, :sw_lng, :ne_lat, :ne_lng

  def initialize(lat, lng)
    set_bounds(lat.to_f, lng.to_f)
  end

  def set_bounds(lat, lng)
    unless(lat.nil? || lng.nil?)
      lat_range = (ne_lat.nil? || ne_lat == 0) ? 0.08 : (ne_lat - sw_lat).abs / 2
      lng_range = (ne_lng.nil? || ne_lng == 0) ? 0.08 : (ne_lng - sw_lng).abs / 2

      self.sw_lat = lat - lat_range
      self.sw_lng = lng - lng_range

      self.ne_lat = lat + lat_range
      self.ne_lng = lng + lng_range
    end
  end
end
