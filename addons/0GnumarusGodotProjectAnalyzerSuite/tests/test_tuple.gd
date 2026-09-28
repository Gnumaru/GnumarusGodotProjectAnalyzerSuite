# @integrity_ignore_file (test harness uses virtual paths)
extends RefCounted

## \@tuple suite: definitions (explicit size, unions, markers), semantic
## compatibility, literal shapes, index access and Array fallback.

const Syn = preload("res://addons/0GnumarusGodotProjectAnalyzerSuite/GnumarusGodotProjectAnalyzerSuiteGdscriptSyntaticParser.gd")
const Sem = preload("res://addons/0GnumarusGodotProjectAnalyzerSuite/GnumarusGodotProjectAnalyzerSuiteGdscriptSemanticParser.gd")
const H = preload("res://addons/0GnumarusGodotProjectAnalyzerSuite/tests/helpers.gd")


func run() -> Dictionary:
	var h = H.new()
	h.suite = "tuple"
	_t_def(h)
	_t_def_errors(h)
	_t_sem(h)
	_t_use(h)
	_t_index(h)
	_t_store(h)
	_t_mutate(h)
	_t_members(h)
	_t_json(h)
	return h.result()


func _kinds(res: Dictionary) -> Array:
	var out: Array = []
	for e in res.get("errors", []):
		out.append(str((e as Dictionary).get("kind", "")))
	return out


func _has_err(res: Dictionary, kind: String, part: String) -> bool:
	for e in res.get("errors", []):
		if str((e as Dictionary).get("kind", "")) == kind and part in str((e as Dictionary).get("message", "")):
			return true
	return false


func _clean(res: Dictionary) -> bool:
	return (res.get("errors", []) as Array).is_empty()


func _sem_errors(src: String, path: String) -> Array:
	var sem = Sem.new()
	var ast: Dictionary = sem.analyze(Syn.new().parse_text(src), path)
	return ast.get("semantic_errors", [])


func _sem_kinds(src: String, path: String) -> Array:
	var out: Array = []
	for e in _sem_errors(src, path):
		out.append(str((e as Dictionary).get("kind", "")))
	return out


func _t_def(h) -> void:
	h.check(_clean(h.analyze_text("extends Node\n# @tuple TupleName 5 int|String float|bool Object Variant *\n# @var x TupleName\nvar x: Array = [1, 2.0, null, null, null]\n", "res://tests/tmp_tup_d1.gd")), "full example clean")
	h.check(_clean(h.analyze_text("extends Node\n# @tuple Inner2 1 int\n# @tuple Outer2 2 Inner2 String\n# @var x Outer2\nvar x: Array = [[1], \"a\"]\n", "res://tests/tmp_tup_d2.gd")), "nested tuple clean")
	h.check(_clean(h.analyze_text("extends Node\n# @tuple Outer2 2 Inner2 String\n# @tuple Inner2 1 int\n# @var x Outer2\nvar x: Array = [[1], \"a\"]\n", "res://tests/tmp_tup_d3.gd")), "forward nested ref clean")
	h.check(_clean(h.analyze_text("extends Node\n# @tuple E 0\n# @var x E\nvar x: Array = []\n", "res://tests/tmp_tup_d4.gd")), "empty tuple clean")
	h.check(_clean(h.analyze_text("extends Node\n# @tuple T 2 * variant\n# @var x T\nvar x: Array = [1, \"a\"]\n", "res://tests/tmp_tup_d5.gd")), "any and unknown markers clean")


func _t_def_errors(h) -> void:
	h.check(_has_err(h.analyze_text("extends Node\n# @tuple T 3 int String\nvar x: T\n", "res://tests/tmp_tup_e1.gd"), "tuple_malformed", "declares size 3 but lists 2"), "count mismatch malformed")
	h.check(_kinds(h.analyze_text("extends Node\n# @tuple T int String\nvar x: T\n", "res://tests/tmp_tup_e2.gd")).has("tuple_malformed"), "missing count malformed")
	h.check(_kinds(h.analyze_text("extends Node\n# @tuple\nvar x := 1\n", "res://tests/tmp_tup_e3.gd")).has("tuple_malformed"), "empty malformed")
	h.check(_has_err(h.analyze_text("extends Node\n# @tuple T 1 void\nvar x: T\n", "res://tests/tmp_tup_e4.gd"), "tuple_malformed", "invalid type"), "void malformed")
	h.check(_clean(h.analyze_text("extends Node\n# @tuple T 1 object\n# @var x T\nvar x: Array = [null]\n", "res://tests/tmp_tup_e5b.gd")), "lowercase object corrected")
	h.check(_has_err(h.analyze_text("extends Node\n# @tuple T 1 Nope\nvar x: T\n", "res://tests/tmp_tup_e6.gd"), "tuple_unknown_type", "'Nope'"), "unknown item errors")
	h.check(_has_err(h.analyze_text("extends Node\n# @tuple T 1 int\n# @tuple T 1 int\nvar x: T\n", "res://tests/tmp_tup_e7.gd"), "tuple_conflict", "more than once"), "duplicate conflicts")
	h.check(_has_err(h.analyze_text("extends Node\n# @tuple Item 1 int\nclass Item:\n\tpass\n", "res://tests/tmp_tup_e8.gd"), "tuple_conflict", "script member"), "class conflict")
	h.check(_has_err(h.analyze_text("extends Node\n# @tuple Node 1 int\n", "res://tests/tmp_tup_e9.gd"), "tuple_conflict", "existing type"), "builtin conflict")
	h.check(_kinds(h.analyze_text("extends Node\nfunc f(\n\t\t# @tuple T 1 int\n\t\ta: int\n\t) -> void:\n\tpass\n", "res://tests/tmp_tup_e10.gd")).has("tuple_misplaced"), "param misplaced")
	h.check(_clean(h.analyze_text("extends Node\n# @tuple T 1 int\nfunc f():\n\tpass\n", "res://tests/tmp_tup_e11.gd")), "leading definition clean")
	h.check(_kinds(h.analyze_text("extends Node\nfunc f():\n\t# @tuple T 1 int\n\n\tpass\n", "res://tests/tmp_tup_e12.gd")).has("tuple_misplaced"), "body misplaced")
	h.check(_kinds(h.analyze_text("# @tuple T 1 int\nclass_name Foo\n", "res://tests/tmp_tup_e13.gd")).is_empty(), "header definition clean")


func _t_sem(h) -> void:
	h.check(_sem_kinds("extends Node\n# @tuple T2 2 int String\nvar x: T2\n", "res://tests/tmp_tup_s1.gd").is_empty(), "semantic accepts tuple vartype")
	h.check(_sem_kinds("extends Node\nvar x: Nope\n", "res://tests/tmp_tup_s2.gd").has("unknown_type"), "semantic still rejects unknown")
	h.check(_sem_kinds("extends Node\n# @tuple T2 2 int String\nvar t: T2\nvar a: Array = t\n", "res://tests/tmp_tup_s3.gd").is_empty(), "semantic tuple to array clean")
	h.check(_has_err_sem("extends Node\n# @tuple T2 2 int String\nvar arr := [1]\nvar x: T2 = arr\n", "res://tests/tmp_tup_s4.gd", "assign", "shape not provable"), "semantic array to tuple rejects")
	h.check(_sem_kinds("extends Node\n# @tuple T2 2 int String\nvar x: T2 = [1, 2, 3]\n", "res://tests/tmp_tup_s5.gd").is_empty(), "semantic defers literals")
	h.check(_sem_kinds("extends Node\n# @tuple T2 2 int String\nvar v: Variant\nvar x: T2 = v\n", "res://tests/tmp_tup_s6.gd").is_empty(), "semantic variant flows")
	h.check(_has_err_sem("extends Node\n# @tuple T2 2 int String\n# @tuple T3 1 int\nvar a: T2\nvar b: T3 = a\n", "res://tests/tmp_tup_s7.gd", "assign", "different tuple types"), "semantic nominal mismatch")


func _has_err_sem(src: String, path: String, kind: String, part: String) -> bool:
	for e in _sem_errors(src, path):
		if str((e as Dictionary).get("kind", "")) == kind and part in str((e as Dictionary).get("message", "")):
			return true
	return false


func _t_use(h) -> void:
	h.check(_clean(h.analyze_text("extends Node\n# @tuple T2 2 int String\n# @var x T2\nvar x: Array = [1, \"a\"]\n", "res://tests/tmp_tup_u1.gd")), "conforming literal clean")
	h.check(_has_err(h.analyze_text("extends Node\n# @tuple T2 2 int String\n# @var x T2\nvar x: Array = [1, 2, 3]\n", "res://tests/tmp_tup_u2.gd"), "tuple_mismatch", "expects 2 elements, got 3"), "wrong length mismatches")
	h.check(_has_err(h.analyze_text("extends Node\n# @tuple T2 2 int String\n# @var x T2\nvar x: Array = [\"a\", \"b\"]\n", "res://tests/tmp_tup_u3.gd"), "tuple_mismatch", "element 0"), "wrong element mismatches")
	h.check(_has_err(h.analyze_text("extends Node\n# @tuple T2 2 int String\nvar arr := [1]\n# @var x T2\nvar x: Array = arr\n", "res://tests/tmp_tup_u4.gd"), "tuple_mismatch", "must be initialized with a compatible literal"), "non-literal init demands literal")
	h.check(_clean(h.analyze_text("extends Node\n# @tuple T2 2 int String\n# @var x T2\nvar x: Array = [foo(), \"a\"]\n", "res://tests/tmp_tup_u5.gd")), "complex element skipped")
	h.check(_has_err(h.analyze_text("extends Node\n# @tuple T2 2 int String\n# @var x T2\nvar x: Array = [1, 2, 3] # trailing note\n", "res://tests/tmp_tup_u6.gd"), "tuple_mismatch", "expects 2 elements, got 3"), "trailing comment keeps mismatch")
	h.check(_clean(h.analyze_text("extends Node\n# @tuple T2 2 int String\n# @var x T2\nvar x: Array = [1, \"a\"] # trailing note\n", "res://tests/tmp_tup_u7.gd")), "trailing comment keeps clean literal clean")
	h.check(_has_err(h.analyze_text("extends Node\n# @tuple T1 1 int\n# @var x T1\nvar x: Array = [3.14]\n", "res://tests/tmp_tup_u8.gd"), "tuple_mismatch", "element 0 expects 'int', got 'float'"), "float narrowing mismatches")
	h.check(_clean(h.analyze_text("extends Node\n# @tuple T1 1 float\n# @var x T1\nvar x: Array = [1]\n", "res://tests/tmp_tup_u9.gd")), "int widening clean")
	h.check(_has_err(h.analyze_text("extends Node\n# @tuple T2 2 int String\nfunc f():\n\t# @var d T2\n\tvar d: Array = [1, \"a\"]\n\td = [1]\n", "res://tests/tmp_tup_u11.gd"), "tuple_mismatch", "expects 2 elements, got 1"), "reassign size mismatches")
	h.check(_has_err(h.analyze_text("extends Node\n# @tuple T2 2 int String\nfunc f():\n\t# @var d T2\n\tvar d: Array = [1, \"a\"]\n\td = [\"a\", 1]\n", "res://tests/tmp_tup_u12.gd"), "tuple_mismatch", "element 0 expects 'int'"), "reassign element mismatches")
	h.check(_clean(h.analyze_text("extends Node\n# @tuple T2 2 int String\nfunc f():\n\t# @var d T2\n\tvar d: Array = [1, \"a\"]\n\td = [2, \"b\"]\n", "res://tests/tmp_tup_u13.gd")), "reassign conforming clean")
	h.check(_has_err(h.analyze_text("extends Node\n# @tuple T2 2 int String\nfunc f():\n\t# @var d T2\n\tvar d: Array\n", "res://tests/tmp_tup_u15.gd"), "tuple_mismatch", "must be initialized with a compatible literal"), "missing init demands literal")
	h.check(_has_err(h.analyze_text("extends Node\n# @tuple T2 2 int String\nfunc f():\n\t# @var d T2\n\tvar d: Variant\n", "res://tests/tmp_tup_u16.gd"), "tuple_mismatch", "must be initialized with a compatible literal"), "variant decl demands literal")
	h.check(_has_err(h.analyze_text("extends Node\n# @tuple T2 2 int String\nfunc f():\n\t# @var d T2\n\tvar d\n", "res://tests/tmp_tup_u17.gd"), "tuple_mismatch", "must be initialized with a compatible literal"), "bare decl demands literal")
	h.check(_has_err(h.analyze_text("extends Node\n# @tuple T2 2 int String\nfunc f():\n\t# @var d T2\n\tvar d: Array = [1, \"a\"]\n\tvar e := [1]\n\td = e\n", "res://tests/tmp_tup_u14.gd"), "tuple_mismatch", "can only be assigned a literal value"), "reassign variable demands literal")
	h.check(_has_err(h.analyze_text("extends Node\n# @tuple T2 2 int int\nfunc f():\n\t# @var a0 T2\n\tvar a0: Array = [0, 0]\n\tvar g: Array = []\n\ta0 = g\n", "res://tests/tmp_tup_u18.gd"), "tuple_mismatch", "can only be assigned a literal value"), "reassign incompatible array demands literal")
	h.check(_has_err(h.analyze_text("extends Node\n# @tuple T2 2 int int\nfunc f():\n\t# @var a0 T2\n\tvar a0: Array = [0, 0]\n\ta0 = mk()\n", "res://tests/tmp_tup_u19.gd"), "tuple_mismatch", "can only be assigned a literal value"), "reassign call demands literal")
	h.check(_has_err(h.analyze_text("extends Node\n# @tuple T2 2 int String\nfunc f():\n\t# @var d T2\n\tvar d: Object # trailing\n", "res://tests/tmp_tup_u10.gd"), "var_mismatch", "is neither 'Object'"), "tuple vs Object trailing mismatches")


func _t_index(h) -> void:
	h.check(_clean(h.analyze_text("extends Node\n# @tuple T2 2 int String\n# @var x T2\nvar x: Array = [1, \"a\"]\nfunc f():\n\tprint(x[0])\n\tprint(x[-1])\n", "res://tests/tmp_tup_i1.gd")), "literal index clean")
	h.check(_has_err(h.analyze_text("extends Node\n# @tuple T2 2 int String\n# @var x T2\nvar x: Array = [1, \"a\"]\nfunc f():\n\tprint(x[5])\n", "res://tests/tmp_tup_i2.gd"), "tuple_bounds", "out of bounds"), "oob errors")
	h.check(_clean(h.analyze_text("extends Node\n# @tuple T2 2 int String\n# @var x T2\nvar x: Array = [1, \"a\"]\nfunc f(i):\n\tprint(x[i])\n", "res://tests/tmp_tup_i3.gd")), "dynamic index skips")
	h.check(_has_err(h.analyze_text("extends Node\n# @tuple T2 2 int String\n# @var x T2\nvar x: Array = [1, \"a\"]\nfunc f():\n\tprint(x[\"k\"])\n", "res://tests/tmp_tup_i4.gd"), "tuple_bounds", "indexed by int"), "string index errors")


func _t_store(h) -> void:
	h.check(_clean(h.analyze_text("extends Node\n# @tuple T2 2 int String\nfunc f():\n\t# @var d T2\n\tvar d: Array = [1, \"a\"]\n\td[0] = 2\n", "res://tests/tmp_tup_s1.gd")), "conforming store clean")
	h.check(_clean(h.analyze_text("extends Node\n# @tuple T2 2 int String\nfunc f():\n\t# @var d T2\n\tvar d: Array = [1, \"a\"]\n\td[-1] = \"b\"\n", "res://tests/tmp_tup_s2.gd")), "negative store clean")
	h.check(_has_err(h.analyze_text("extends Node\n# @tuple T2 2 int String\nfunc f():\n\t# @var d T2\n\tvar d: Array = [1, \"a\"]\n\td[0] = \"b\"\n", "res://tests/tmp_tup_s3.gd"), "tuple_mismatch", "element 0 expects 'int', got 'String'"), "store type mismatches")
	h.check(_has_err(h.analyze_text("extends Node\n# @tuple T2 2 int String\nfunc f():\n\t# @var d T2\n\tvar d: Array = [1, \"a\"]\n\td[-2] = \"b\"\n", "res://tests/tmp_tup_s4.gd"), "tuple_mismatch", "element 0 expects 'int'"), "negative store mismatches")
	h.check(_has_err(h.analyze_text("extends Node\n# @tuple T2 2 int String\nfunc f():\n\t# @var d T2\n\tvar d: Array = [1, \"a\"]\n\td[2] = 1\n", "res://tests/tmp_tup_s5.gd"), "tuple_bounds", "out of bounds"), "oob store bounds errors")
	h.check(not _kinds(h.analyze_text("extends Node\n# @tuple T2 2 int String\nfunc f():\n\t# @var d T2\n\tvar d: Array = [1, \"a\"]\n\td[2] = 1\n", "res://tests/tmp_tup_s5.gd")).has("tuple_mismatch"), "oob store never double reports")
	h.check(_clean(h.analyze_text("extends Node\n# @tuple T2 2 int String\nfunc f():\n\t# @var d T2\n\tvar d: Array = [1, \"a\"]\n\tvar e := \"b\"\n\td[0] = e\n", "res://tests/tmp_tup_s6.gd")), "non-literal store silent")
	h.check(_clean(h.analyze_text("extends Node\nfunc f():\n\tvar d := [1, \"a\"]\n\td[0] = \"b\"\n", "res://tests/tmp_tup_s7.gd")), "untyped base silent")
	h.check(_clean(h.analyze_text("extends Node\n# @tuple T2 2 int String\nfunc f():\n\t# @var d T2\n\tvar d: Array = [1, \"a\"]\n\td[0] += 1\n", "res://tests/tmp_tup_s8.gd")), "compound store silent")


func _t_mutate(h) -> void:
	var head := "extends Node\n# @tuple T2 2 int int\nfunc f():\n\t# @var a0 T2\n\tvar a0: Array = [0, 0]\n"
	for m in ["push_back(1)", "push_front(1)", "pop_back()", "pop_front()", "append(1)", "append_array([1])", "insert(0, 1)", "remove_at(0)", "erase(0)", "clear()", "resize(5)", "assign([1, 2])", "sort()", "sort_custom(func(a, b): return a < b)", "shuffle()", "reverse()", "pop_at(0)"]:
		h.check(_has_err(h.analyze_text(head + "\ta0." + m + "\n", "res://tests/tmp_tup_mx.gd"), "tuple_mutate", "fixed-shape"), "shape method mutates: " + m)
	h.check(_has_err(h.analyze_text(head + "\ta0.set(0, '')\n", "res://tests/tmp_tup_ms1.gd"), "tuple_mismatch", "element 0 expects 'int', got 'String'"), "set wrong type mismatches like store")
	h.check(_clean(h.analyze_text(head + "\ta0.set(1, 5)\n", "res://tests/tmp_tup_ms2.gd")), "set conforming clean")
	h.check(_clean(h.analyze_text(head + "\ta0.set(9, 5)\n", "res://tests/tmp_tup_ms3.gd")), "set oob silent")
	h.check(_clean(h.analyze_text(head + "\tvar i := 0\n\ta0.set(i, '')\n", "res://tests/tmp_tup_ms4.gd")), "set dynamic index silent")
	h.check(_clean(h.analyze_text(head + "\tvar v := ''\n\ta0.set(0, v)\n", "res://tests/tmp_tup_ms5.gd")), "set dynamic value silent")
	h.check(_has_err(h.analyze_text(head + "\ta0.fill('')\n", "res://tests/tmp_tup_mf1.gd"), "tuple_mismatch", "element 0 expects 'int', got 'String'"), "fill wrong type mismatches")
	h.check(_clean(h.analyze_text(head + "\ta0.fill(3)\n", "res://tests/tmp_tup_mf2.gd")), "fill conforming clean")
	h.check(_clean(h.analyze_text("extends Node\nfunc f():\n\tvar a: Array = [0, 0]\n\ta.push_back(1)\n\ta.set(0, '')\n", "res://tests/tmp_tup_mp.gd")), "plain Array untouched")
	h.check(_clean(h.analyze_text(head + "\tvar b: Array = a0.duplicate()\n", "res://tests/tmp_tup_md.gd")), "readers untouched")
	h.check(_clean(h.analyze_text(head + "\ta0.make_read_only()\n", "res://tests/tmp_tup_mr.gd")), "read-only freeze untouched")


func _t_members(h) -> void:
	h.check(_clean(h.analyze_text("extends Node\n# @tuple T2 2 int String\n# @var x T2\nvar x: Array = [1, \"a\"]\nfunc f():\n\tprint(x.size())\n", "res://tests/tmp_tup_m1.gd")), "tuple method via Array clean")
	h.check(_has_err(h.analyze_text("extends Node\n# @tuple T2 2 int String\n# @var x T2\nvar x: Array = [1, \"a\"]\nfunc f():\n\tx.bogus()\n", "res://tests/tmp_tup_m2.gd"), "missing_method", "has no method 'bogus()'"), "tuple method bogus errors")


func _t_json(h) -> void:
	h.analyze_text("extends Node\n# @tuple JTuple 2 int String\nvar x: JTuple\n", "res://tests/tmp_tup_j1.gd")
	var info: Dictionary = h.load_json("res://.godot/0GnumarusGodotProjectAnalyzerSuiteData/user/JTuple.json")
	h.check(str(info.get("kind", "")) == "tuple", "json kind tuple")
	h.check(int(info.get("size", -1)) == 2, "json size kept")
	var items: Array = info.get("tuple_items", [])
	h.check(items.size() == 2 and (items[0] as Dictionary).get("types", []) == ["int"], "json items kept")
	h.check((info.get("inheritance_chain", []) as Array) == ["JTuple"], "json chain kept")
