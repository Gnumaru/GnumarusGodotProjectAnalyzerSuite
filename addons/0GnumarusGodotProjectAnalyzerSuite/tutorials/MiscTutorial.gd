# please, enable line wrapping (alt+z) to propperly read the text.
#class_name MiscTutorial

# ===========================
# ==== OTHER ANNOTATIONS ====
# ===========================
# besides tuples, structs, interfaces and generics, there are other annotations you may use
# \@var narrows the type of a variable. notice that you may use type union since every type in the union is equal or narrower than the declared variable type

# @var v1 Sprite2D|AnimatedSprite2D
var v1: Node2D

# \@alias is usefull to define a globally acessible type alians
# @alias IntOrFloat int|float @end_alias
# \@end_alias is required because you could use a complex type expression, like nested generic types, so the parser needs an easy way to know where the expression ends

# \@return and \@param are used to narrow the type return type and the parameter types of a function
# @param p int
# @return String
func my_func(p: Variant)->Variant:
	return 'j'.repeat(p)

# @deprecated
enum DepEnum{a}
# @deprecated
const c=0
# @deprecated
signal depsig
# @deprecated
var v_dep
# @deprecated
func fdep():
	return
# @deprecated
class DepClass:
	pass

func test_deprecated():
	# all usage of deprecated members get warned
	fdep()
	depsig.emit()
	DepClass.new()
	print(v_dep)
	print(c)
	print(DepEnum.a)

func test_private():
	# all usage of private members from outside the file that declared them is an error
	TuplesTutorial.fdep()
	TuplesTutorial.depsig.emit() # for some reason the native godot parser is giving me an error here =S
	TuplesTutorial.DepClass.new()
	print(TuplesTutorial.v_dep)
	print(TuplesTutorial.c)
	print(TuplesTutorial.DepEnum.a)

# =====================
# ==== NULLABILITY ====
# =====================

# In godot, Objects may be null, and a null object is most of the times unusable. The analiser has two different policies to treat null, "trust" where the object is trusted to not containe null and "distrust" where object access is warned unless guarded against null.

# "nullable" and "not_null" are modifiers (without '@') that you use alongside \@var, \@param and \@return. they come after the type and say wether that thing should be distrusted as maybe containing null (when using "nullable") or trusted to never be null (when using "not_null").

# the "nullable" to the right of Object says that this variable may or may not be null. acesses to it are warned about it maybe being null unless you guard against it.
# @var a Object nullable
var a: Object
# the "not_null" says the opposing, that this variable should be trusted to never be null
# @var b Object not_null
var b: Object

func test_nullable():
	a.free() # will warn that it may be null
	b.free() # on the other hand, will never warn, it is trusted

	if a != null:
		a.free() # guarded call wont warn

	if not a == null:
		a.free() # also guarded, wont warn

	if a:
		a.free() # also guarded, wont warn

	a.free() # not guarded, will warn

	if a == null:
		return
	# guarded from here onward
	a.free() # guarded call

# if you do not use 'nullable' or 'not_null' in the variable/parameter/return, the analizer will search for the \@nullable_policy annotation at the start of the file. it should be used as "\@nullable_policy trust" or "\@nullable_policy distrust". it tells what the default policy will be when the var/param/return does not have a null/not_null modifier.
# besides the file annotation, there is a project setting 'gnumarus_analyzer/nullable_policy' where you chose what is the default project wise. the default value, unless you change it, is 'trust'
