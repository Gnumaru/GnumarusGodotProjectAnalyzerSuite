# please, enable line wrapping (alt+z) to propperly read the text.

# ================
# ==== TUPLES ====
# ================
# a tuple is an array with fixed size and fixed type for each index.
# you define a tuple in the following format
# 	<annotation-name> <tuple-name> <size> <first-index-type> <second-index-type> ... <last-index-type>
# like bellow
# 	@tuple My2SlotTupleOfIntAndString 2 int String
# the tuple size could be infered by the argument count but as a design choice I decided to make it explicit.
# a declared tuple name (as all other type names except for generic argument names) is globaly valid. that means a tuple name declared in one script is valid in all scripts for the same project so you can declare it in one script and use it, for example, as a \@param in other script.
func tupletest1()->void:
	# to annotate a \@var, \@param or \@return as a tuple (as for any other declared type), the annotated type must be COMPATIBLE AND NARROWER or equal (not wider) than the gdscript declared type. this means that, for a tuple, the variable must be declared as Array, Variant or untyped.
	# @var a My2SlotTupleOfIntAndString
	var a: Array = [0, ''] # works because My2SlotTupleOfIntAndString is narrower than Array
	# @var b My2SlotTupleOfIntAndString
	var b: Variant = [0, ''] # works because My2SlotTupleOfIntAndString is narrower than Variant
	# @var c My2SlotTupleOfIntAndString
	var c = [0, ''] # works because My2SlotTupleOfIntAndString is narrower than untyped
	# @var c2 My2SlotTupleOfIntAndString
	var c2 # unlike arrays, tuples MUST be initialized on creation using a compatible array literal
	# @var d My2SlotTupleOfIntAndString
	var d: int # yields an error because My2SlotTupleOfIntAndString is incompatible with int. the analyzer considers the inheritance of both types as "int < Variant" and "My2SlotTupleOfIntAndString < Array < Variant"
	# trying to assign an array literal with incompatible format will yield an error, be it in the variable declaration
	# @var e My2SlotTupleOfIntAndString
	var e: Array = [1] # initialized using a wrong sized array literal
	# or throughout the code
	e = [1] # wrong size
	e = ['', 1] # wrong index types
	# trying to set the indexes also yields errors
	e[-3] = '' # trying to set unexisting index
	e[2] = '' # trying to set unexisting index
	e[0] = '' # index 0 type is incompatible with string
	# actual array content is not tracked by the analyzer, so please do not mutate the tuple size
	e.pop_back() # these will faile silently
	e.push_back('') # these will faile silently
	# neither set with 'set' instead of '[]'
	e.set(0, '') # will also fail silenty
