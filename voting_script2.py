import sys, requests, random, time, json, numpy

SERVERS = {
			'localhost' : 'localhost:3000',
			'dev' : 'lytit-dev.herokuapp.com',
			'stage' : 'lytit-stage.herokuapp.com',
			'prod' : 'lytit-prod.herokuapp.com'
		  }

USER_TOKEN = "012b5c949996f20ce537b43fb88b5aad"

def vote(server='localhost', user=USER_TOKEN, interval=10):
	flag = -1

	server_url = "http://" + SERVERS[server]
	print "Pointing to %s\n" % server_url

	while True:
		r = requests.get(server_url + "/api/v1/bar/position")
		bar = r.json()['bar_position']
		print "bar position: %f" % bar

		venue_id = random.randint(1, 999)
		probs = []

		if venue_id >= 1 and venue_id < 333:
			probs = [0.2, 0.8]
		elif venue_id >= 333 and venue_id < 666:
			probs = [0.5, 0.5]
		else:
			probs = [0.8, 0.2]

		is_up_vote = numpy.random.choice([True, False], p=probs)

		vote = None
		if is_up_vote:
			vote = bar + 0.1
		else:
			vote = bar - 0.1

		print "current vote: %f" % vote

		vote_json = {"auth_token" : user, "rating" : vote, "venue_id" : venue_id}
		headers = {'content-type': 'application/json'}

		req = requests.post((server_url + "/api/v1/venues/%s/vote") % venue_id, data=json.dumps(vote_json), headers=headers)

		if req.status_code == 200:
			print req.json()
		else:
			print "could not vote, error: " + str(req.status_code) + "detail: " + str(req.json())

		time.sleep(interval)

if __name__ == "__main__":
	if len(sys.argv) < 4:
		print 'Usage: python voting_script.py localhost|dev|stage|prod <USER_TOKEN> <INTERVAL>'
		sys.exit(1)
	print 'Press CTRL+C to exit...\n'

	try:
		vote(sys.argv[1], sys.argv[2], int(sys.argv[3]))
	except KeyboardInterrupt:
		print '\n\nBye :)'
		sys.exit(0)