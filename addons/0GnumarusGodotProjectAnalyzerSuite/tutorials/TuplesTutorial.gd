# please, enable line wrapping (alt+z) to propperly read the text.

# ================
# ==== TUPLES ====
# ================
# A tuple is an array with fixed size and fixed type for each index.
# You define a tuple in the following format:

# 	<annotation-name> <tuple-name> <size> <first-index-type> <second-index-type> ... <last-index-type>

# Like bellow

# @tuple My2SlotTupleOfIntAndString 2 int String
# @tuple My2SlotTupleOfIntAndInt 2 int int

# The tuple size could be perfectly infered using the argument count but as a design choice I decided to make it explicit.
# A declared tuple name (as all other type names except for generic argument names) is globaly valid. This means that a tuple name declared in one script is valid in all scripts in the same project. So you can declare it in one script and use it, for example, as a \@param in other script.

func tuple_usage()->void:
	# To annotate a \@var, \@param or \@return as a tuple (as for any other declared type), the annotated type must be COMPATIBLE AND NARROWER or equal (not wider) than the gdscript declared type. this means that, for a tuple, the variable must be declared as "Array", "Variant" or untyped.
	# If your tupple happens to be homogeneous (all indexes have the same type) you can use a typed array, but that's completely optional. Since you'll probably use different index types for each value you'll be forced to use an untyped array anyway.
	# @var a0 My2SlotTupleOfIntAndInt
	var a0: Array[int] = [0, 0]
	var a1: Array[int] = [0, 0]
	a0 = a1 # tuples may ONLY be assigned through literals, any other asignment kind yields error.
	a0 = [1, 1] # works because it's an array literal

	# @var a My2SlotTupleOfIntAndString
	var a: Array = [0, ''] # works because My2SlotTupleOfIntAndString is narrower than Array

	# @var b My2SlotTupleOfIntAndString
	var b: Variant = [0, ''] # works because My2SlotTupleOfIntAndString is narrower than Variant

	# @var c My2SlotTupleOfIntAndString
	var c = [0, ''] # works because My2SlotTupleOfIntAndString is narrower than untyped

	# @var c2 My2SlotTupleOfIntAndString
	var c2 # unlike arrays, tuples MUST be initialized at the declaration site using a compatible array literal

	# the line bellow yields an error because My2SlotTupleOfIntAndString is incompatible with int. the analyzer considers the inheritance of both types as "int < Variant" and "My2SlotTupleOfIntAndString < Array < Variant"
	# @var d My2SlotTupleOfIntAndString
	var d: int

	# trying to assign an array literal with incompatible format will yield an error, be it in the variable declaration
	# @var e My2SlotTupleOfIntAndString
	var e: Array = [1] # initialized using a wrong sized array literal

	# or throughout the code
	e = [1] # wrong size
	e = ['', 1] # wrong index types
	# tuples are NOT imutable, only their 'shape' is imutable, so you can always change the values as long as the types are compatible
	e[0] = 90

	# trying to set the indexes also yields errors
	e[-3] = '' # trying to set unexisting index
	e[2] = '' # trying to set unexisting index
	e[0] = '' # index 0 type is incompatible with string
	e.set(0, '') # also works with "set"
	var f = e[2] # trying to get an unexisting index is also an error

	# actual array content is not tracked by the analyzer, but mutating method calls yield errors
	e.push_back(0) # error: whould increase tuple size
	e.pop_back() # error: whould decrease tuple size
