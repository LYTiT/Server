class TwitterWave
	def TwitterWave.live_ny_san_fran_stream
		client = Twitter::Streaming::Client.new do |config|
			config.consumer_key        = '286I5Eu8LD64ApZyIZyftpXW2'
			config.consumer_secret     = '4bdQzIWp18JuHGcKJkTKSl4Oq440ETA636ox7f5oT0eqnSKxBv'
			config.access_token        = '2846465294-QPuUihpQp5FjOPlKAYanUBgRXhe3EWAUJMqLw0q'
			config.access_token_secret = 'mjYo0LoUnbKT4XYhyNfgH4n0xlr2GCoxBZzYyTPfuPGwk'
	    end

		new_york = [[-74,40], [-73,41]]
		san_fran = [[-122.75,36.8], [-121.75,37.8]]
		geo_query = (new_york<<san_fran).join(",")
		client.filter(locations: geo_query) do |object|
			if object.is_a?(Twitter::Tweet)
				puts "#{object.text} ----- #{(Time.now-object.created_at)/60.0}mins ago"
	  			#puts object.text if object.is_a?(Twitter::Tweet)
	  		end
		end
	end
end