## Load scramble from any according source, used as static class.
extends Node

const TEST_VALUES = {
	0: ["Test", {"t":"z", "e":"u", "s":"q"}],
	1: ["Hello World!", {"h":"z", "e":"u", "l":"q"}]
}

const TUTORIAL_VALUES = {
	0: ["Fake news", {"f":"k", "a":"e", "k":"s", "e":"a", "n":"f", "w":"n", "s":"w"}], # Hint: Alternative facts
	1: ["No news is good news", {"n":"o"}], # , Hint: When you don't hear something...
	2: ["Who Knows the News", {"k":"n"}], # Hint: The name of the game
}

const ONLY_SCRAMBLE_CHARS = "abcdefghijklmnopqrstuvwxyz"


## Generate a random, valid scramble transform.
## 
## Output is a dict of all 26 english start-end character mappings, no repeats.
static func generate_transform():
	var transform = {}
	#var num = len(ONLY_SCRAMBLE_CHARS)
	
	var available = []
	for ch in ONLY_SCRAMBLE_CHARS:
		available.append(ch)
	
	for src in ONLY_SCRAMBLE_CHARS:
		var selection = available[randi() % available.size()]
		available.erase(selection)
		transform[src] = selection
	return transform


## Perform a deterministic scramble from a source, unscrambled string.
##
## Should generate "az" from ("Go", {"g":"a", "o":"z"}).
##
## source: Source string, the "answer"
## transform: dict of source:target (scrambled) letter mappings
##
## Returns:
##   result, or null if an error
static func apply_scramble(source:String, transform:Dictionary):
	var scrambled_string = source
	
	# Validate the transform provided.
	var lookup = {} # Converted
	var assignments = []
	for key in transform:
		if len(key) != 1:
			push_error("Key (%s) in transform is not a single char" % key)
			return null
		if len(transform[key]) != 1:
			push_error("Value (%s) of key (%s) in transform is not a single char" % [transform[key], key])
			return null
		if key in lookup:
			push_error("Duplicate source mappings for %s in apply_scramble" % key)
			return null
		if transform[key] in assignments:
			push_error("Duplicate end mappings for %s in apply_scramble" % transform[key])
			return null
		lookup[key] = transform[key]
		assignments.append(transform[key])
	
	# Now perform the transform, ensuring that each letter has a lookup match.
	for i in range(len(source)):
		var ch = source[i].to_lower()
		if not ch in ONLY_SCRAMBLE_CHARS:
			continue
		if not ch in lookup:
			push_error("Char %s not in lookup map from %s" % [ch, source])
			return null
		
		# Valid match, apply the according upper or lower case letter.
		if scrambled_string[i] == scrambled_string[i].to_upper():
			scrambled_string[i] = lookup[ch].to_upper()
		else:
			scrambled_string[i] = lookup[ch].to_lower()
	return scrambled_string


static func load_test(index:int) -> Array:
	#print_debug("Raw data for selected test: ", TEST_VALUES[index])
	var solution = TEST_VALUES[index][0]
	var transform = TEST_VALUES[index][1]
	var start = apply_scramble(solution, transform)
	var ret = [solution, start]
	return ret


static func load_tutorial(index:int) -> Array:
	#print_debug("Raw data for selected test: ", TUTORIAL_VALUES[index])
	var solution = TUTORIAL_VALUES[index][0]
	var transform = TUTORIAL_VALUES[index][1]
	var start = apply_scramble(solution, transform)
	var ret = [solution, start]
	return ret


## Start loading an article from Google news RSS feed.
## Caller must run queue_free() node returned.
##
## keyphrase: The rss feed to pull from.
## country_code: Filter for countries, default = US if empty.
static func get_rss_article_url(keyphrase:String, country_code:String) -> HTTPRequest:
	if not country_code:
		country_code = "US"
	var url = "https://news.google.com/rss/search?q=%s&hl=en-%s" % [
		keyphrase, country_code
	]
	print_debug("Loading article from RSS from: %s" % url)
	return url

## Non static loader to send request for rss feed values.
func load_rss_article_request(url) -> HTTPRequest:
	var http = HTTPRequest.new()
	http.set_timeout(15) # 15 seconds.
	add_child(http)
	http.connect("request_completed", http, "_on_rss_load_parse")
	http.request(url)
	return http
	

func _on_rss_load_parse(result, response_code, headers, body):
	print_debug("RSS request completed")
	#var json = JSON.parse(body.get_string_from_utf8())
	print_debug(body.get_string_from_utf8())
	
	# Send "parsed" signal, and then self-destruct here.
	# queue_free() # Queues free the Loader itself, and any child HTTP nodes.
