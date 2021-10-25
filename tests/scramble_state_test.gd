## Unit test for using loading scrambles
extends WAT.Test

const ScrambleState = preload("res://logic/scramble_state.gd")

func title() -> String:
	return "Given ScrambleState"

func test_allowed_keys() -> void:
	describe("When getting allowed unsolved characters")
	var state = ScrambleState.new('abc', 'cba', 'http://url.com')
	asserts.is_true(not state.is_solved, "ensure puzzle not initially solved")
	var scrambled = state.allowed_keys()
	asserts.is_equal(scrambled, ['a', 'c'], "pre swap two chars allowed")
	
	state.swap_chars('a', 'c')
	scrambled = state.allowed_keys()
	asserts.is_equal(scrambled, [], "post swap only 0 char allowed")


func test_domain_from_url() -> void:
	describe("When converting url to domain")
	var res = ScrambleState.domain_from_url("http://hello.com/")
	asserts.is_equal(res, "http://hello.com", "http + /")
	
	res = ScrambleState.domain_from_url("www.hello.com/")
	asserts.is_equal(res, "www.hello.com", "www + /")
	
	res = ScrambleState.domain_from_url("www.hello.com")
	asserts.is_equal(res, "www.hello.com", "www only")
	
	res = ScrambleState.domain_from_url("hello.com")
	asserts.is_equal(res, "hello.com", "domain only")
	
	res = ScrambleState.domain_from_url("www.hello.com/dogs/cats.html")
	asserts.is_equal(res, "www.hello.com", "www + pages")
	
	res = ScrambleState.domain_from_url("www.hi.hello.com/dogs/cats.html")
	asserts.is_equal(res, "www.hi.hello.com", "www + sub + pages")
	
	res = ScrambleState.domain_from_url("https://hi.hello.com/dogs/cats.html")
	asserts.is_equal(res, "https://hi.hello.com", "https + sub + pages")
	
	res = ScrambleState.domain_from_url("http://www.hi.hello.com/www/cats.html")
	asserts.is_equal(res, "http://www.hi.hello.com", "http + sub + www + pages")
	
	res = ScrambleState.domain_from_url("")
	asserts.is_equal(res, "", "empty")
