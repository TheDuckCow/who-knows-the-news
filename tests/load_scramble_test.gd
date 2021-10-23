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
	describe("When loading (unmocked) feed from an rss feed")
	var url = LoadScramble.get_rss_article_url("Godot", "US", "en")
	asserts.is_not_null(url, "generated rss url is not empty")
	
	# Must add loader to scene in order to use http request.
	var loader = LoadScramble.new()
	
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
	# http.queue_free()
	
	loader.queue_free()
	
	
