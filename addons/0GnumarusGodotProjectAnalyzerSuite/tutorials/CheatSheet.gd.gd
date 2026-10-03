##################
### CHEATSHEET ###
##################

# Please, enable line wrapping (alt+z) to propperly read the text.

# Every annotation starts with an at sign "@" followed by one or more latin letters, in snake case. they live inside comments and it doesnt matter how many hash signs you use at the begginnig. they usually are used in the line imediatly before the thing they are refering to but it may vary from one annotation to the other. if you want to mention an annotation without triggering the analyser, you must escape the @ sign with a backslash, like \@var for example. The current list has 16 annotations, 2 end marker annotations and 2 nullability modifiers. The list in no particular order is as follows:

## modifiers
# nullable
# not_null

## annotations
# \@deprecated
# \@private
# \@nullable_policy
# \@strict_untyped
# \@alias
# \@var
# \@param
# \@return
# \@tuple
# \@struct
# \@implements
# \@interface
# \@template
# \@generic_class
# \@generic_func
# \@generic_call

## end marker annotations
# \@end_alias
# \@end_interface

# their purpuse and usage is as follow

# \@deprecated
# used right before anything (root class, inner class, enum, const, signal, property, func, func parameter, func variable). The annotation has no parameters. A member marked as deprecated triggers an analyzer error anywhere it is used. If it doesn't, then that's a bug in the analyzer, please report it.

# \@private
# used right before anything (root class, inner class, enum, const, signal, property, func, func parameter, func variable). The annotation has no parameters. A member marked as private can only be used inside the same file, and anywhere inside it. This means that inner classes have access to private member of outer classes and vice versa, this mirrors the behavior of C#, Java and other languages. Any usage from outside the .gd file that the member lives triggers an analyzer error. If it doesn't, then that's a bug in the analyzer, please report it.

# \@nullable_policy
# Can be used only right at the start of a file. It tells what is the default nullable policy for that file and it will be used for every \@var \@param and \@return that does not declare an specific nullable policy. This annotation only has one parameter, either 'trust' or 'distrust', like in '\@nullable_policy trust' and '\@nullable_policy distrust'. When using the 'trust' nullable policy the analyzer will not warn about usage of maybe-null objects. When using 'distrust' every usage of a maybe-null object will trigger a warning unless the usage is guarded by some branching condition (like an if or else branch) that guarantees the non nullability of that object. For examples see the code in 'func test_nullable()' in MiscTutorial.gd

# \@strict_untyped
# Similar to \@nullable_policy, it can only be used right at the start of a file. It is a hardening of the 'distrust' nullable policy. It accepts 0 or 1 parameters, and the parameters are either 'on' or 'off'. If using 0 parameters it will act as 'on'. When nullable_policy is distrust and strict_untyped is off, the nullability checks will only take place for values declared as Object or as a subtype of it, the checks will ignore untyped variables or variables declared as Variant. On the other hand, when strict_untyped is on, even untyped values or values declared as Variant will raise an analyser warning when used without a guard against null.

# \@alias and # \@end_alias
# Declare a globally available alias name for a complex type expression. This allows subdividing complex type expressions in smaller aliases and declaring complex type expressions using multiple comment lines for more readability. Imagine that you need a type union with nested generic types, where the type parameter of a generic type is also another generic type. In this scenario, declaring the type expression in a single line becomes an unreadable mess. so alias and end_alias allow splitting the expression in several lines and reusing it in all project files. The usage is something like '\@alias MyGlobalAlias my|complex[type[expression]] \@end_alias' where each part may be in a separate comment line (comment lines must always be contiguous) and the type expresion itself may also have line breaks between '|' and inside '[]' between the commas that separate the type paramters.

# \@var
# Declare a type narrowing for a variable. It may be used right before a variable declaration, or any moment later to modify the narrowing. To narrow a type means to declare that a given declared variable like 'var a: Variant' cannot accept the entirety of the value range a 'Variant' could usually accept, but will only accept a subset of that, like 'Object|String|int'. The usage format is '\@var <var-name> <type-expression> [nullability-modifier]' like in '\@var myvar Object|String|int nullable' or '\@var myvar Node2D|Node3D not_null'

# \@param
# Like \@var, but used right before a function declaration. the usage format is exactly the same as \@var, but using \@param

# \@return
# Like \@var, but used right before a function declaration. the usage format is exactly the same as \@var, but using \@return

# \@tuple
# Declares the format and globally available name for a tuple. A tupple is a format narrowing of an Array where the array size becames fixed and the type for each index also becames fixed and can be different for each index. It's declaration cannot span multiple lines. It's usage is in the format '\@tuple <tuple-name> <tuple-size> <index-0-type> <index-1-type> ... <last-index-type>' like in '\@tuple MyTuple 2 Node int|String'. Tuples must be initialized at declaration and the analyzer will trigger an error if the initialization value is not conformant to the tuple format. Every index access is validate either for getting and seeting

# \@struct
# Declares the format and globally available name for a struct. A struct is a format narrowing of a Dictionary where the dictionary size becames fixed, the key type can only be String, the key values are fixed and the type for value becames fixed and can be different for each value. It's declaration cannot span multiple lines. It's usage is in the format '\@struct <struct-name> <struct-size> <key-a>:<value-a-type> <key-b>:<value-b-type> ... <last-key>:<last-value-type>' like in '\@struct MyStruct 2 x:int|float y:int|float'. Structs must be initialized at declaration and the analyzer will trigger an error if the initialization value is not conformant to the struct format. Every key access is validate either for getting and seeting

# \@implements
# Declares that a given root class or inner class implements an 'Interface'. 'Interface' means any existing type and 'implementing an interface' means declaring everything (constants, enums, signals, properties, functions, inner classes) that is shallowly declared (not inherited) in the refered type. This means that you could use "\@implements Node" in a classe and the analyzer will warn you if you do not implement everything that is shallowly declared in the built-in Node class. You can implement every valid type, be it a built-in object-derived class like Node, a Variant derived class like Vector2, or a user declared script class_name which will probably be what you'll be using 99% of the time. The usage format is '\@implements <my-globally-available-type-name>' like in '\@implements IDamageable' where IDamageable may be a script IDamageable.gd that declares a 'class_name IDamageable' or an interface declared with the \@interface annotation.

# \@interface and \@end_interface
# Allows declaring an interface without having to write a script file for it. It can, and should, be declared in multiple lines for better readabililty. Almost everything that can be declared in a script class (constants, enums, signals, properties, functions) can be declared with \@interface in a concise manner. The usage format is '\@interface <interface-name> <fist-member-with-args> <second-member-with-args> ... <last-member-with-args> \@end_interface' like in
#'\@interface
#    MyInterface
#    func:myfunc:void
#    static:var:myvar:int
#\@end_interface'.

# \@template
# Declares a template type name to be used by generic classes and methods, valid only for the file it is declared on. A template type name, like 'T1', 'T2', 'TKey', 'TValue' (starting with 'T' is merely a convention, not enforced) are placeholders for actual type expressions that doesn't exist in the class or function itself, but will only be available at usage time, like when instantiatig an object of a generic class or calling a generic method of a non-generic class. The usage format is '\@template <template-name> [of <optional-template-narrowing>]' like in '\@template T1' or '\@template T2 of IDamageable'. The template may be declared anywhere in the file and will become available in the entire file.

# \@generic_class
# Generic classes allow using template parameters as type names in other annotations (like var, param and return) for that class. These template parameters are placeholders and must become concrete types when annotating an object of that class somewhere else using var, param and return. The usage format is '\@generic_class <class-name> <type-param-1> <type-param-2> ... <last-type-param> like in '\@generic_class MyGenericClass T1 T2'

# \@generic_func
# Allows declaring a generic function outside a generic class. Since you can declare a generic function outside a generic class you cant get template types from the class declaration so you have to declare the function itself as generic. Functions from generic classes don't need to use \@generic_func, they can freely use the same template types used by the class. The usage format is '\@generic_func <func-or-lambda-name> <first-template-name> ... <last-template-name>' like in '\@generic_func myfunc T1 T2'

# \@generic_call
# While calling generic functions from non generic classes OR when calling static methods, there are no concrete types held in the object instantiation, so you need to tell at call site what the concrete types for the teplates are.
# the usage format is '\@generic_call <func-name>[<concrete-type-1>, <concrete-type-2>, ..., <last-concrete-type>]' like in '\@generic_call myfunc[int, MyGenericClass[String, float]]'
