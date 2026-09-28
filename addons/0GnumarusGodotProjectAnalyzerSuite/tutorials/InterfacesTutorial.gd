class_name InterfacesTutorial
# please, enable line wrapping (alt+z) to propperly read the text.

# ====================
# ==== INTERFACES ====
# ====================

# An interface is a contract for the api of a class and it's instances, that is, the instance and static members of an object and it's class. it is a promise that a given class or object will have implemented said member
# You can declare an interface with annotations as you would with tuples and structs.
# the format is <annotation-name> <interface-name> <first-member-string> <second-member-string> ... <last-member-string> <end-annotation-name>
# you can either declare in a single line or in multiple lines of CONTIGUOUS comments, but whichever way you do, you will have to use an \@end_interface after the last member declaration

# @interface
#  MyInterface1
#  func:my_func:void
# @end_interface

# @implements MyInterface1
class Implementer1: # error: method my_func is not implemented
	pass

# @implements MyInterface1
class Implementer2:
	# TODO: SHOULD WORK OR SHOULD GIVE ERROR
	func my_func():
		return 0

# @implements MyInterface1
class Implementer3:
	# error: my_func should return void, not Variant
	func my_func()->Variant:
		return 0

# @implements MyInterface1
class Implementer4:
	# error, should be instance method, not static method
	static func my_func()->void:
		return

# @implements MyInterface1
class Implementer5:
	# only matching implementation works
	func my_func()->void:
		return

# @interface
#  MyInterface2
#  static:var:my_var:int
# @end_interface

# @implements MyInterface2
class Implementer6:
	pass # error: does not have an instance variable 'my_var: int'

# @implements MyInterface2
class Implementer7:
	var my_var: int # error: 'my_var: int' should be a static property, not instance

# you DON'T need to declare an interface with \@interface. in fact every valid type name or alias (like "Array", "Node" or script class_name or inner classes class names) can always be used as interfaces with \@implements. That means that every type is already an interface in itself. this inner class bellow is an interface and can be used even in other script files
class MyAwesomeInterface:
	func something()->int:
		return 0

# @implements InterfacesTutorial.MyAwesomeInterface
class Implementer8: # error: should implement "something()"
	pass

# interfaces are not limited to instance/static func/var. in fact, every kind of member of a class counts
class SomeOtherInterface:
	signal asdf

class SomeOtherInterface2:
	const thing: int = 0

class SomeOtherInterface3:
	enum SomeEnum{a=0}

# @implements InterfacesTutorial.SomeOtherInterface
class Implementer9: # error: should implement signal "asdf"
	pass

# @implements InterfacesTutorial.SomeOtherInterface2
class Implementer10: # error: should implement const "thing"
	pass

# @implements InterfacesTutorial.SomeOtherInterface3
class Implementer11: # error: should implement enum "SomeEnum"
	pass

func test_interfaces():
	var a: Object
	a.my_func() # godot usually does not bother if you try an unexisting method, but the analyser get's pretty upset

	# @var b MyInterface1
	var b: Object
	b.my_func() # but here it doesn't because b implicitly became typed as the union Object|MyInterface1, and altough "Object" does not have my_func(), "MyInterface1" has
