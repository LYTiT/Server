import sys, requests, random, time, json

SERVERS = {
			'localhost' : 'localhost:3000',
			'dev' : 'lytit-dev.herokuapp.com',
			'stage' : 'lytit-stage.herokuapp.com',
			'prod' : 'lytit-prod.herokuapp.com'
		  }

USER_TOKEN = "3bbffc8a454620b86cb64fd3e441b9a0"

def vote(server='localhost', user=USER_TOKEN, interval=10):
	flag = -1

	server_url = "http://" + SERVERS[server]
	print "Pointing to %s\n" % server_url

	while True:
		venue_id = random.randint(1, 1015)
		vote = random.random() * flag
		flag = flag * -1

		vote_json = {"auth_token" : user, "rating" : vote, "venue_id" : venue_id}
		headers = {'content-type': 'application/json'}

		req = requests.post((server_url + "/api/v1/venues/%s/vote") % venue_id, data=json.dumps(vote_json), headers=headers)

		if req.status_code == 200:
			print req.json()
		else:
			print "could not vote, error: " + str(req.status_code) + "detail: " + req.json()

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
		exit(0)
