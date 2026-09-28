# please, enable line wrapping (alt+z) to propperly read the text.
class_name GenericsTutorial

# ==================
# ==== GENERICS ====
# ==================
# Generics is the feature a language has to define a class or method by means of a "type placeholder" instead of an actual type, a type template, like for example declaring "var my_var: T" where the type "T" does not exist at all, it's just a placeholder. But this placeholder must be replaced by an actual existing type sooner or later, and that time is when you instantiate an object of that class (for generic classes) or call a generic method of a non generic class.

# for example, this declares a "type placeholder" name, a template name
# @template T1

# it can be used anywhere in this script file, and in this file only. you can use it for example as a parameter, return type or variable inside a  to tell that a generic function.
# @generic_func T1
# @param p T1
# @return T1
func my_gen_func(p: Variant)->Variant:
	return p

func test_generics1():
	# TODO: should raise error?
	var a: int = my_gen_func(0) # this works because my_gen_func is not inside a generic class and was not called with a generic_call

	# @generic_call my_gen_func[float]
	var b: Object = my_gen_func(0) # error: float is not compatible with Object

	# @generic_call my_gen_func[Object]
	var c: Object = my_gen_func(0) # error: expected 'Object' as a parameter and int is not compatible with 'Object'

	# @generic_call my_gen_func[Object]
	var d: Object = my_gen_func(Object.new()) # works. the generic function had a single template argument which was used as both parameter and return, so the call was valid

# "free" generic functions are available as seen before but are not as useful as a generic class. the class itself receives the template arguments and everything inside the class can use the template types as seen fit. for example

# @template T2 of Node2D|Node3D

# @generic_class T2
class MyGenericClass:
	# @var v T2
	var v: Variant
	# @return T2
	func ret_v()->Variant:
		return v

	# not everything needs to use the template args though
	var v2: int
	func ret_int()->int:
		return v2

func test_generics2():
	# the line bellow errors out because "Node" is not compatible with the constraints of T2 (Node2D or Node3D, and "Node" is not the same of either nor inherit from either of those two)
	# @var a GenericsTutorial.MyGenericClass[Node]
	var a: GenericsTutorial.MyGenericClass = MyGenericClass.new()

	# did I mention that inside the class that declares the inner classes you don't need to write the full "path" of the class name? the error bellow is the same as the one above
	# @var b MyGenericClass[Node]
	var b: MyGenericClass = MyGenericClass.new()


	# "c" instance used "Sprite2D" as a generic parameter, wich matches the "Node2D" constraint of T2
	# @var c MyGenericClass[Sprite2D]
	var c: MyGenericClass = MyGenericClass.new()

	# notice that, since "c" is an instance of a generic class we don't need to use \@generic_call here
	var cc: int = c.ret_v() # error: c was instantiated using Sprite2D as T2, ret_v returns T2, thus the return of ret_v is incompatible with cc, which is an int
