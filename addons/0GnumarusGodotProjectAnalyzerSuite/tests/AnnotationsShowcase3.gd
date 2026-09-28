# @nullable_policy distrust
# Migration showcase: this file opts into distrust while the rest of
# the project stays trust. Every WARNING below is our analyzer's
# maybe_null; every OK is proven non-null. Legacy files migrate by
# adding this tag, then converting each warning (guards, markers).

class_name GnumarusGodotProjectAnalyzerSuiteAnnotationsShowcase3
extends RefCounted


func legacy_use(n: Node) -> void:
	n.queue_free() # WARNING: implicitly nullable under distrust


func guarded_use(n: Node) -> void:
	if n == null:
		return
	n.queue_free() # OK: guard clause proves non-null


func is_use(v: Variant) -> void:
	if v is Node:
		v.queue_free() # OK: is proves non-null


# @var watched Node nullable
var watched: Node


func marked_use() -> void:
	watched.queue_free() # WARNING: explicitly watched


# @var trusted Node not_null
var trusted: Node


func trusted_use() -> void:
	trusted.queue_free() # OK: never null by contract


# @return Node nullable
func make_maybe() -> Node:
	return null # OK: nullable may return null


func taint_demo() -> void:
	var r = make_maybe()
	r.queue_free() # WARNING: tainted result


# @param p Node not_null
func need(p: Node) -> void:
	pass


func refusal_demo() -> void:
	need(watched) # WARNING: maybe argument for not_null parameter
	need(null) # ERROR: null literal for not_null parameter
	need(Node.new()) # OK
