## Unit test for using loading scrambles
extends WAT.Test

const LoadScramble = preload("res://logic/load_scramble.gd")

func title() -> String:
	return "Given LoadScramble"


func test_apply_scramble_valid_transform() -> void:
	describe("When applying scramble to valid examples")
	var start = "Go"
	var transform = {"g":"a", "o":"z"}
	var expected = "Az"
	var res = LoadScramble.apply_scramble(start, transform)
	asserts.is_equal(res, expected, "transform of Go matches expectation")
	
	start = "test"
	transform = {"t":"z", "e":"f", "s":"q"}
	expected = "zfqz"
	res = LoadScramble.apply_scramble(start, transform)
	asserts.is_equal(res, expected, "transform of test matches expectation")
	
	start = "Some, example!"
	transform = {"s":"o", "o":"m", "m":"e", "e":"x", "x":"a", "a":"p", "p":"l", "l":"s"}
	expected = "Omex, xapelsx!"
	res = LoadScramble.apply_scramble(start, transform)
	asserts.is_equal(res, expected, "transform of phrase matches expectation")


func test_apply_scramble_bad_transform() -> void:
	describe("When applying scramble to a invalid example")
	var start = "Go"
	
	var transform = {"g":"a", "o":"a"}
	var res = LoadScramble.apply_scramble(start, transform)
	asserts.is_null(res, "null for repeat of output mapping")
	
	transform = {"g":"a"}
	res = LoadScramble.apply_scramble(start, transform)
	asserts.is_null(res, "null for missing letter mapping")
	
	transform = {"g":"a", "o":"bc"}
	res = LoadScramble.apply_scramble(start, transform)
	asserts.is_null(res, "null for wrong length of source transform value")


func test_generate_transform() -> void:
	describe("When generating a new transform")
	var transform = LoadScramble.generate_transform("sample")
	asserts.is_not_null(transform, "transform is not null")
	
	var res = LoadScramble.apply_scramble("sample", transform)
	asserts.is_not_null(res, "transform was valid")


func test_load_tutorials() -> void:
	describe("When loading tutorials")
	var res
	for i in range(3):
		res = LoadScramble.load_tutorial(i)
		asserts.is_not_null(res, "tutorial %s loads correctly" % i)


func test_load_rss() -> void:
	describe("When loading (live, unmocked) feed from an rss feed")
	# Must add loader to scene in order to use http request.
	var loader = LoadScramble.new()
	var url = loader.get_rss_article_url("Godot", "US", "en")
	asserts.is_not_null(url, "generated rss url is not empty")
	
	# Now set up and send the request.
	add_child(loader)
	var http = loader.load_rss_article_request(url)
	
	# Setup WAT signal watching
	watch(http, "request_completed")
	yield(until_signal(http, "request_completed", 5), YIELD)
	
	# Ensure signal occurred.
	asserts.auto_pass("yielding on request_completed Signal")
	asserts.signal_was_emitted(
		http, "request_completed", "http node completed request")
	unwatch(http, "request_completed")
	loader.queue_free()
	
func _load_mock_xml(path:String) -> PoolByteArray:
	asserts.file_exists(path, "mock file exists")
	var file = File.new()
	file.open(path, File.READ)
	var data = file.get_buffer(file.get_len())
	file.close()
	return data


func test_parse_articles_xml_small_mock() -> void:
	describe("When parsing a (mocked) rss feed from Google News")
	var path = "res://tests/test_article_data_mock.xml"
	var data:PoolByteArray = _load_mock_xml(path)
	asserts.is_not_null(data, "mock data is loaded as bytes")
	
	var loader := LoadScramble.new()
	var articles := loader.parse_articles_xml(data)
	asserts.is_equal(len(articles), 4, "the four mocked articles are detected")
	
	# Magic tests for these articles
	if not articles:
		push_error("Exited tests early due to assert not met")
		return
	asserts.is_equal(
		articles[0].get('title'),
		'Week Ahead in Energy and Environment: Oct. 25 - Reuters',
		'first article title matches')
	asserts.is_equal(
		articles[0].get('link'),
		"https://www.reuters.com/legal/transactional/week-ahead-energy-environment-oct-25-2021-10-22/",
		"first article full link matches")
	asserts.is_equal(
		articles[0].get('pubDate'),
		"Fri, 22 Oct 2021", # Shortened by rss date parser, chopped off:  21:07:00 GMT
		"first article publish date matches"
	)
	asserts.is_equal(
		articles[0].get('source'),
		"Reuters",
		"first article source matches"
	)
	asserts.is_equal(
		articles[0].get('description'),
		'Demo Simple Description',
		"first article description matches"
	)
	
	
	# Test last article
	asserts.is_equal(
		articles[-1].get('title'),
		'Roy Mathews: Plan would protect environment, financial security - Lewiston Sun Journal',
		'last article title matches')
	asserts.is_equal(
		articles[-1].get('link'),
		"https://www.sunjournal.com/2021/10/23/roy-mathews-plan-would-protect-environment-financial-security/?rel=related",
		"last article full link matches")
	asserts.is_equal(
		articles[-1].get('pubDate'),
		"Sat, 23 Oct 2021", # Orig: "Sat, 23 Oct 2021 08:00:57 GMT",
		"last article publish date matches"
	)
	asserts.is_equal(
		articles[-1].get('source'),
		"Lewiston Sun Journal",
		"last article source matches"
	)
	#print_debug("Raw string:")
	#print(articles[-1].get('description'))
	asserts.is_equal(
		articles[-1].get('description'),
		# Note how this is already 'converted' from the actual format in the src,
		# ie instead of `&lt;a` we have `<a` for tags,
		'<a href="https://www.sunjournal.com/2021/10/23/roy-mathews-plan-would-protect-environment-financial-security/?rel=related" target="_blank">Roy Mathews: Plan would protect environment, financial security</a>&nbsp;&nbsp;<font color="#6f6f6f">Lewiston Sun Journal</font>',
		"first article description matches"
	)
	
	
func test_parse_articles_xml_full_mock() -> void:
	describe("When parsing a (mocked) rss feed from Google News")
	var path = "res://tests/test_article_data_full.xml"
	var data:PoolByteArray = _load_mock_xml(path)
	asserts.is_not_null(data, "mock data is loaded as bytes")
	
	var loader := LoadScramble.new()
	var articles := loader.parse_articles_xml(data)
	asserts.is_equal(len(articles), 100, "all 100 mocked articles are detected")
	
	#print_debug("The last description found:")
	#print(articles[-1].get('description'))
	if not articles:
		push_error("Exited tests early due to assert not met")
		return
	asserts.is_equal(
		articles[-1].get('title'),
		"Building: What's the big deal for the environment? - DW (English)",
		'last article title matches')
	asserts.is_equal(
		articles[-1].get('link'),
		"https://www.dw.com/en/building-whats-the-big-deal-for-the-environment/a-57850391",
		"last article full link matches")
	asserts.is_equal(
		articles[-1].get('source'),
		"DW (English)",
		"last article source matches")
	asserts.is_equal(
		articles[-1].get('description'),
		# Had to escape one single quote below, and counter escape xml \.
		'<a href="https://www.dw.com/en/building-whats-the-big-deal-for-the-environment/a-57850391" target="_blank">Building: What\'s the big deal for the environment?</a>&nbsp;&nbsp;<font color="#6f6f6f">DW (English)</font>',
		"first article description matches"
	)

func test_select_target_article() -> void:
	describe("When Finding the optimal article and title-shortening")
	var path = "res://tests/test_article_data_mock.xml"
	var data:PoolByteArray = _load_mock_xml(path)
	asserts.is_not_null(data, "mock data is loaded as bytes")
	var loader := LoadScramble.new()
	var articles := loader.parse_articles_xml(data)
	asserts.is_equal(len(articles), 4, "the four mocked articles are detected")
	
	# Now test the sorting function.
	var target := loader.select_target_article(articles)
	asserts.is_true(target.has('link'), "returns non-empty dictionary")
	if not target:
		push_error("Ending test early due to empty dict")
		return
	print_debug('Selected target')
	print(target)
	asserts.is_equal(
		target['title'],
		'Week Ahead in Energy and Environment: Oct. 25',
		'The best and shortened title is identified'
	)
	asserts.is_equal(
		target['link'],
		'https://www.reuters.com/legal/transactional/week-ahead-energy-environment-oct-25-2021-10-22/',
		'and the correct link is still included'
	)
	
func test_extract_rss_date() -> void:
	describe("When extracting the date from the rss field")
	parameters([
		["start", "expected", "msg"],
		["Mon, 25 Oct 2021 07:00:00 GMT", "Mon, 25 Oct 2021", "base example matched"],
		["Mon, 25 Oct 2021 7:00pm", "Mon, 25 Oct 2021", "alt-base example matched"],
		["2021/10/10", "2021/10/10", "shorthand unchanged"],
		["10/1", "10/1", "super short unchanged"],
		["Monday: Jan 5th", "Monday: Jan 5th", "Alt format unchanged"]
	])
	var output = LoadScramble._extract_rss_date(p["start"])
	asserts.is_equal(output, p["expected"], p["msg"])
