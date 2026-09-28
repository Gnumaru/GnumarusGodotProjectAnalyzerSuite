# please, enable line wrapping (alt+z) to propperly read the text.

# =================
# ==== STRUCTS ====
# =================
# A struct is a dictionary with fixed size, fixed key names (only string keys) and fixed type for each value.
# You define a struct in the following format:
#
# 	<annotation-name> <struct-name> <size> <first-key-name>:<first-value-type> <second-key-name>:<second-value-type> ... <last-key-name>:<last-value-type>
#
# Like bellow
# 	@struct My2PairStructOfIntAndString 2 age:int name:String
# 	@struct My2PairStructOfIntAndInt 2 x:int y:int
#
# The struct size could be perfectly infered using the argument count but as a design choice I decided to make it explicit.
# A declared struct name (as all other type names except for generic argument names) is globaly valid. This means that a struct name declared in one script is valid in all scripts in the same project. So you can declare it in one script and use it, for example, as a \@param in other script.

func struct_usage()->void:
	# To annotate a \@var, \@param or \@return as a struct (as for any other declared type), the annotated type must be COMPATIBLE AND NARROWER or equal (not wider) than the gdscript declared type. this means that, for a struct, the variable must be declared as "Dictionary", "Variant" or untyped.
	# If your struct happens to be homogeneous (all values have the same type) you can use a typed dictionary, but that's completely optional. Since you'll probably use different types for each value you'll be forced to use an untyped dictionary anyway.
	# @var a0 My2PairStructOfIntAndInt
	var a0: Dictionary[String, int] = {x=0, y=0}

	# you may initialize using either javascript/python style dictionary (keys as quoted strings followed by colon ':') or lua style (unquoted keys folowed by equal '=')
	# @var a1 My2PairStructOfIntAndInt
	var a1: Dictionary[String, int] = {"x":0, "y":0}
	var a2: Dictionary[String, int] = {x=0, y=0}
	a0 = a2 # structs may ONLY be assigned through literals, any other asignment kind yields error.
	a0 = {x=1, y=1} # works because it's an dictionary literal

	# @var a My2PairStructOfIntAndString
	var a: Dictionary = {age=0, name=''} # works because My2PairStructOfIntAndString is narrower than Dictionary

	# @var b My2PairStructOfIntAndString
	var b: Variant = {age=0, name=''} # works because My2PairStructOfIntAndString is narrower than Variant

	# @var c My2PairStructOfIntAndString
	var c = {age=0, name=''} # works because My2PairStructOfIntAndString is narrower than untyped

	# @var c2 My2PairStructOfIntAndString
	var c2 # unlike dictionaries, structs MUST be initialized at the declaration site using a compatible dictionary literal
	# the line bellow yields an error because My2PairStructOfIntAndString is incompatible with int. the analyzer considers the inheritance of both types as "int < Variant" and "My2PairStructOfIntAndString < Dictionary < Variant"

	# @var d My2PairStructOfIntAndString
	var d: int

	# trying to assign a dictionary literal with incompatible format will yield an error, be it in the variable declaration
	# @var e My2PairStructOfIntAndString
	var e: Dictionary = {age=0} # initialized using a wrong sized dictionary literal

	# or throughout the code
	e = {age=0} # wrong size
	e = {age='', name=0} # wrong value types

	# trying to set the indexes also yields errors
	e.asdf = '' # trying to set unexisting key name
	e['asdf'] = '' # trying to set unexisting key name
	e.age = '' # key 'age' type is incompatible with string
	e['age'] = '' # key 'age' type is incompatible with string
	e.set('age', '') # key 'age' type type is incompatible with string
	var f = e.asdf # trying to get an unexisting index is also an error
	f = e['asdf']
	# structs are NOT imutable, only their 'shape' is imutable, so you can always change the values as long as the types are compatible
	e.age = 90

	# actual dictionary content is not tracked by the analyzer, but mutating method calls yield errors
	e.clear() # error: would decrease struct size
	e.erase('age') # error: would decrease struct size
