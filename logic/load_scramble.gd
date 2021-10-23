## Load scramble from any according source, used as static class.
extends Node

const TEST_VALUES = {
	0: ["Test", {"t":"z", "e":"u", "s":"q"}],
	1: ["Hello World!", {"h":"z", "e":"u", "l":"q"}]
}

const TUTORIAL_VALUES = {
	0: ["Fake news", {"f":"k", "a":"e", "k":"s", "e":"a", "n":"f", "w":"n", "s":"w"}], # Hint: Alternative facts
	1: ["No news is good news", {}], # , Hint: When you don't hear something...
	2: ["Who Knows the News\nby Patrick W. Crawford", {}], # Hint: The name of the game
}

const TUTORIAL_META = {
	0: ["    Tutorial stage 1/3. Solve the puzzle by unscrambling the letters above in as few steps as possible. Press two letters in a row to swap them. You can either use the virtual keyboard below, or simply type the letter on your physical keyboard.",
		"Alternate Facts"],
	1: ["    Tutorial stage 2/3. Longer phrases may be harder, but take note when gray letters turn black - that means the letter is in the correct spot already! Just be careful that you don’t turn solved black characters back into gray ones (and yes, that also means no cheating by just mashing on your keyboard).",
	"When you hear no updates"],
	2: ["   Tutorial stage 3/3. If you are really stuck, you can consider the topic at the top left. There’s a good chance that word will appear in the article, or otherwise hint at the solution. Another option is to click on the Publisher Name link, which will appear to the left just underneath the scrambled headline. You could try searching for the actual news article there!",
		"The name of the game"]
}

const ONLY_SCRAMBLE_CHARS = "abcdefghijklmnopqrstuvwxyz"


signal article_loaded(solution, start)
signal article_load_failed(reason)
signal article_metadata(article_dict)


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
			print_debug(source)
			print_debug(transform)
			print_debug(lookup)
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
	var url = "https://news.google.com/rss/search?q=%s&hl=%s-%s" % [
		topic, language, country_code
	]
	print_debug("Loading article from RSS from: %s" % url)
	return url

## Non static loader to send request for rss feed values.
## Will fire a signal on http load
func load_rss_article_request(url) -> HTTPRequest:
	var http = HTTPRequest.new()
	http.set_timeout(15) # 15 seconds.
	add_child(http)
	http.connect("request_completed", self, "_on_rss_load_parse")
	http.request(url)
	return http
	

func _on_rss_load_parse(result, response_code, _headers, body):
	print_debug("RSS request completed, parse XML now")
	if response_code != HTTPClient.RESPONSE_OK:
		emit_signal("article_load_failed", "Non 200 response code (%s): %s" % [
			response_code, result])
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
	emit_signal("article_loaded", solution, initial_state) # To load puzzle.


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
	
	# Idea is to partition by "item", where each item is and then filter down only for sections
	# which the right attributes
	while parser.read() != ERR_FILE_EOF:
		#print_debug(parser.get_node_type())
		#if parser.get_node_type() != XMLParser.NODE_TEXT:
		#	continue
		if parser.get_node_name() == 'item':
			found_first_itm = true
			if _is_article_data_complete(mid_article_data):
				articles.append(mid_article_data)
			mid_article_data = {}
		elif found_first_itm == false:
			continue # Skip all headers before first item tag.
		var node_name = parser.get_node_name()
		if not node_name in ['title', 'link', 'pubDate', 'source']: # 'description'
			continue
		# TODO: need some special handling of 'description'
		if node_name in mid_article_data:
			continue # Would be a </closing> tag, so skip it.
		
		# Do another read to get the next attribute value within this article.
		parser.read()
		mid_article_data[node_name] = parser.get_node_data()
		
	# Closing condition.
	if _is_article_data_complete(mid_article_data):
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


## Select a suitable article from the total list of articles present.
func select_target_article(articles:Array) -> Dictionary:
	# TODO: Rate by ensuring not too long, some indication of number of chars,
	# and potentially a flag to decide how difficult or not.
	# Could also keep a session cache of which article links have already been
	# used, to avoid repeats.

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
		shortest_title_value = title
		
		# print_debug("article: ", articles[i]["title"])
		# print_debug("Shortened: ", title)
		
		if shortest_headline_len < 0:
			shortest_headline_ind = i
			shortest_headline_len = len(title)
		elif len(title) < 8:
			continue # Title is too short (but ok if this is the first)
		elif len(title) < shortest_headline_len:
			shortest_headline_ind = i
			shortest_headline_len = len(title)
	
	# Update the title to the shortened version, and return the whole structure.
	articles[shortest_headline_ind]['title'] = shortest_title_value
	return articles[shortest_headline_ind]
