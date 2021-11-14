## Load scramble from any according source, used as static class.
extends Node

const TEST_VALUES = {
	0: ["Test", {"t":"z", "e":"u", "s":"q"}],
	1: ["Hello World!", {"h":"z", "e":"u", "l":"q"}]
}

const TUTORIAL_VALUES = {
	0: ["Fake news", {
		"f":"f", "a":"e", "k":"s", "e":"a", "n":"n", "w":"k", "s":"w"
		}],
	1: ["No news is good news", {
		'd':'i', 'e':'d', 'g':'o', 'i':'s', 'n':'n', 'o':'e', 's':'g', 'w':'w'
		}],
	2: ["Who Knows the News by Patrick W. Crawford", {
		"a":"d", "b":"a", "c":"c", "d":"f", "e":"t", "f":"i", "h":"n", "i":"r",
		"k":"b", "n":"s", "o":"k", "p":"p", "r":"e", "s":"o", "t":"h", "w":"w",
		"y":"y"}],
}

const TUTORIAL_META = {
	0: ["TUT_01_META", "TUT_01_HINT"],
	1: ["TUT_02_META", "TUT_02_HINT"],
	2: ["TUT_03_META", "TUT_03_HINT"]
}

const ONLY_SCRAMBLE_CHARS = "abcdefghijklmnopqrstuvwxyz"


signal article_loaded(solution, start)
signal article_load_failed(reason)
signal article_metadata(article_dict)

var use_cloud_proxy = true

## Generate a random, valid scramble transform.
## 
## initial_phrase: initial phrase, used to limit the set of characters to swap.
## Output is a dict of all 26 english start-end character mappings, no repeats.
static func generate_transform(initial_phrase:String):
	var transform = {}
	
	var available = []
	var tmp = initial_phrase.to_lower()
	for ch in ONLY_SCRAMBLE_CHARS:
		if ch in tmp:
			available.append(ch)
	
	# Because there's no deep copy in gdscript??
	var avail_cp = []
	for ch in available:
		avail_cp.append(ch)

	for src in avail_cp:
		var selection = available[randi() % available.size()]
		available.erase(selection)
		transform[src] = selection
	#print_debug(transform)
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
		var keyl = key.to_lower()
		if len(keyl) != 1:
			push_error("Key (%s) in transform is not a single char" % key)
			return null
		if len(transform[keyl]) != 1:
			push_error("Value (%s) of key (%s) in transform is not a single char" % [transform[keyl], keyl])
			return null
		if keyl in lookup:
			push_error("Duplicate source mappings for %s in apply_scramble" % keyl)
			return null
		if transform[keyl] in assignments:
			push_error("Duplicate end mappings for %s in apply_scramble" % transform[keyl])
			return null
		lookup[keyl] = transform[keyl].to_lower()
		assignments.append(transform[keyl])
	
	# Now perform the transform, ensuring that each letter has a lookup match.
	for i in range(len(source)):
		var ch = source[i].to_lower()
		if not ch in ONLY_SCRAMBLE_CHARS:
			continue
		if not ch in lookup:
			#print_debug(source)
			#print_debug(transform)
			#print_debug(lookup)
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
	if not transform: # Apparently can't just use == {}, won't return true
		transform = generate_transform(solution)
	var start = apply_scramble(solution, transform)
	var ret = [solution, start]
	return ret


## Start loading an article from Google news RSS feed.
## Caller must run queue_free() node returned.
##
## topic: The rss keyword/phrase feed to pull from.
## country_code: Filter for countries, default = US if empty.
## language: Language of articles, en for English.
static func get_rss_article_url(topic:String, country_code:String, language:String) -> HTTPRequest:
	if not country_code:
		country_code = "US"
	if not language:
		language = "en"
	var url
	if topic:
		# Will pull from RSS query feed based on input keyword (no spaces)
		url = "https://news.google.com/rss/search?q=%s&hl=%s-%s" % [
			topic, language, country_code
		]
	else:
		# Will pull from top articles from today.
		url = "https://news.google.com/rss?hl=%s-%s" % [language, country_code]
		
	print_debug("Loading article from RSS from: %s" % url)
	return url


## Non static loader to send request for rss feed values.
## Will fire a signal on http load
func load_rss_article_request(url) -> HTTPRequest:
	var http = HTTPRequest.new()
	http.set_timeout(30) # 15 seconds.

	# There are many limitations of the http node in html5 exports:
	# https://docs.godotengine.org/en/3.0/getting_started/workflow/export/exporting_for_web.html#httpclient
	# The biggest issue is that CORS is not enabled on our google feed.
	# So, the workaround is to use a proxy cloud function created specifically
	# for this project. This cloud function is locked down so that only requests
	# to that google rss domain are allowed (but it is public access).
	# This cloud function takes a single param which is the full url.

	add_child(http)
	http.use_threads = false
	http.connect("request_completed", self, "_on_rss_load_parse")

	if use_cloud_proxy:
		# Use the cloud function.
		var cloud_url = "https://us-central1-mcprep-cloud.cloudfunctions.net/dcg-know-news-cors-proxy"
		# Note: Cors related headers are in the *servers* response to an OPTIOIN
		# (vs POST) request, and if it gives a 204, the following is narrowly allowed
		# ie: Post, with this specific kind of header.
		var headers = ["Content-Type: application/json"]
		var use_ssl = true
		var query = JSON.print({"url": url})
		http.request(cloud_url, headers, use_ssl, HTTPClient.METHOD_POST, query)
	else:
		# Non webbrowser, can directly make the RSS feed call without proxy.
		var headers = []
		http.request(url, headers, true)
	return http
	

func _on_rss_load_parse(result, response_code, _headers, body):
	print_debug("RSS request completed, parse XML now")
	if response_code == 0:
		print_debug("0 response code: %s, body: %s" % [result, body])
		emit_signal("article_load_failed", "Could not connect to server (likely due to CORS)")
		return
	if response_code != HTTPClient.RESPONSE_OK:
		print_debug("Non 200 response code (%s): %s, body: %s" % [
			response_code, result, body])
		emit_signal("article_load_failed", "Non 200 response code (%s): %s" % [
			response_code, result])
		return
	
	# Cloud function proxy errors to handle.
	if body.get_string_from_utf8() == "No URL provided":
		print_debug("Missing url in proxy request")
		emit_signal("article_load_failed", "Missing url in proxy request")
		return
	elif body.get_string_from_utf8() == "No data found":
		print_debug("No data returned from proxy request")
		emit_signal("article_load_failed", "No data returned from proxy request")
		return
	elif body.get_string_from_utf8() == "Invalid request domain":
		print_debug("Invalid url prefix")
		emit_signal("article_load_failed", "No data returned from proxy request")
		return

	# Debug mode to save the xml to a file.
	var debug = false
	if debug:
		print_debug("tmp file at: %s/", OS.get_user_data_dir())
		var save_xml = File.new()
		var filename = "user://tmp_article_data.xml"
		save_xml.open(filename, File.WRITE)
		save_xml.store_buffer(body)
		#var parser = XMLParser.new()
		#var err = parser.open(filename)
	
	var articles := parse_articles_xml(body)
	if articles == []:
		return # Should have already raised signal if needed.
	
	var this_article := select_target_article(articles)
	var solution = this_article["title"]
	var transform = generate_transform(solution)
	var initial_state = apply_scramble(solution, transform)
	emit_signal("article_metadata", this_article) # To load other scene visuals.
	emit_signal("article_loaded", solution, initial_state, this_article["link"])


## Parse for article data and return in structured way
##
## A single article in the RSS xml feed is structured like so:
## <item>
##   <title>Playco acquires Goodboy for HTML5 game engine PixiJS - VentureBeat</title>
##   <link>https://link.com/article/</link>
##   <guid isPermaLink="false">unique_id</guid>
##   <pubDate>Tue, 28 Sep 2021 07:00:00 GMT</pubDate>
##   <description>Description of article with link tags...</description>
##   <source url="https://link.com">SiteName</source>
## </item>
##
## body: The raw xml response from the http node
## Returns: array of dictionaries, with structure:
##   {title, link, pubDate, source}
func parse_articles_xml(body:PoolByteArray) -> Array:
	var parser = XMLParser.new()
	var err = parser.open_buffer(body)
	if err != OK:
		push_error("Failed to open response as XML")
		emit_signal("article_load_failed", "Failed to open response as XML")
		return []
	
	if parser.is_empty():
		push_error("XML parser found response to be empty")
		emit_signal("article_load_failed", "XML parser found response to be empty")
		return []
	
	var articles = []
	var mid_article_data = {}
	var found_first_itm = false
	
	# Idea is to partition by "item", where each item is and then filter down
	# only for sections which the right attributes.
	while parser.read() != ERR_FILE_EOF:
		var ntype = parser.get_node_type()
		var node_name # Populate if NODE_ELEMENT (not NODE_TEXT).
		if ntype == XMLParser.NODE_ELEMENT_END:
			continue
		elif ntype == XMLParser.NODE_TEXT:
			continue # Always reading from within structure of NODE_ELEMENT.
		elif ntype == XMLParser.NODE_ELEMENT:
			node_name = parser.get_node_name() # Always save name if element
			if node_name == 'item':
				found_first_itm = true
				if _is_article_data_complete(mid_article_data):
					mid_article_data['pubDate'] = _extract_rss_date(mid_article_data['pubDate'])
					articles.append(mid_article_data)
				mid_article_data = {}
		elif found_first_itm == false:
			continue # Skip all headers before first <item> tag.
		else:
			push_warning("Unrecognized xml element")

		if not node_name in ['title', 'link', 'pubDate', 'source', 'description']:
			continue
		
		# Do another read to get the next attribute value within this article.
		parser.read()
		mid_article_data[node_name] = parser.get_node_data()
		
	# Closing condition.
	if _is_article_data_complete(mid_article_data):
		mid_article_data['pubDate'] = _extract_rss_date(mid_article_data['pubDate'])
		articles.append(mid_article_data)
	
	print_debug("Parsed data, article count: ", len(articles))
	return articles


## Ensure complete coverage of the required articles keys are present.
func _is_article_data_complete(article_data:Dictionary) -> bool:
	if not 'title' in article_data:
		return false
	elif not 'link' in article_data:
		return false
	elif not 'pubDate' in article_data:
		return false
	elif not 'source' in article_data:
		return false
	#elif not 'description' in article_data:
	#	return false
	return true


## Extract date e.g. "Mon, 25 Oct 2021" from "Mon, 25 Oct 2021 07:00:00 GMT".
static func _extract_rss_date(date_str:String) -> String:
	var final:String
	if ":" in date_str:
		# Get the : after the hour figure
		var split_ary = date_str.split(":", true, 1)
		var split:String = split_ary[0]

		# Get last space, and show everything until then.
		var last_space:int
		for i in range(len(split)):
			if split[i] == " ":
				last_space = i

		 # 8: Ensure length at least a year, month, day in numbers.
		if last_space and last_space > 8 and last_space < len(split):
			final = split.substr(0, last_space)
		else:
			final = date_str
	else:
		final = date_str
	return final


## Select a suitable article from the total list of articles present.
func select_target_article(articles:Array) -> Dictionary:
	# TODO: Rate by ensuring not too long, some indication of number of chars,
	# and potentially a flag to decide how difficult or not.
	# Could also keep a session cache of which article links have already been
	# used, to avoid repeats.
	if not articles:
		push_error("No articles included to return")
		return {}

	# For now, just returning the shortest article by name for ease.
	var shortest_headline_ind = 0
	var shortest_headline_len = -1
	var shortest_title_value = ""
	for i in range(len(articles)):
		# If already known to be too long, try to cut out the org name from
		# title suffix. Almost every article will end in " - PublisherName",
		# sometimes it is doubled up e.g. " - Name - Name"
		var title:String = articles[i]["title"]
		if len(title) > 40:
			title = title.split("|", true, 1)[0]
		if len(title) > 40:
			title = title.split(" - ", true, 1)[0]

		# print_debug("article: ", articles[i]["title"])
		# print_debug("Shortened: ", title)

		if shortest_headline_len < 0:
			shortest_headline_ind = i
			shortest_headline_len = len(title)
			shortest_title_value = title
		elif len(title.replace(" ", "")) < 15:
			continue # Title is too short (but ok if this is the first)
		#elif articles[i]["link"] in Cache.headlines_played:
		elif title in Cache.headlines_played:
			print_debug("Skipping already solved puzzle")
			continue
		elif len(title) < shortest_headline_len:
			shortest_headline_ind = i
			shortest_headline_len = len(title)
			shortest_title_value = title

	#print_debug("Selected shortest_headline_len: %s, index %s" % [
	#	shortest_headline_len, shortest_headline_ind])
	#print(articles[shortest_headline_ind])

	# Update the title to the shortened version, and return the whole structure.
	if shortest_title_value: # Not set if nothing was shortened.
		articles[shortest_headline_ind]['title'] = shortest_title_value
	return articles[shortest_headline_ind]
