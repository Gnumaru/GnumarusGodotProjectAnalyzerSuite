# @integrity_ignore_file (test harness uses virtual paths)
extends RefCounted

## \@struct suite: definitions (mandatory size, fields, markers),
## semantic compatibility, literal shapes, key/member access.

const Syn = preload("res://addons/0GnumarusGodotProjectAnalyzerSuite/GnumarusGodotProjectAnalyzerSuiteGdscriptSyntaticParser.gd")
const Sem = preload("res://addons/0GnumarusGodotProjectAnalyzerSuite/GnumarusGodotProjectAnalyzerSuiteGdscriptSemanticParser.gd")
const H = preload("res://addons/0GnumarusGodotProjectAnalyzerSuite/tests/helpers.gd")


func run() -> Dictionary:
	var h = H.new()
	h.suite = "struct"
	_s_def(h)
	_s_def_errors(h)
	_s_sem(h)
	_s_use(h)
	_s_keys_members(h)
	_s_field_access(h)
	_s_mutate(h)
	_s_canon(h)
	_s_json(h)
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


func _sem_kinds(src: String, path: String) -> Array:
	var out: Array = []
	var sem = Sem.new()
	var ast: Dictionary = sem.analyze(Syn.new().parse_text(src), path)
	for e in ast.get("semantic_errors", []):
		out.append(str((e as Dictionary).get("kind", "")))
	return out


func _has_err_sem(src: String, path: String, kind: String, part: String) -> bool:
	var sem = Sem.new()
	var ast: Dictionary = sem.analyze(Syn.new().parse_text(src), path)
	for e in ast.get("semantic_errors", []):
		if str((e as Dictionary).get("kind", "")) == kind and part in str((e as Dictionary).get("message", "")):
			return true
	return false


func _s_def(h) -> void:
	h.check(_clean(h.analyze_text("extends Node\n# @tuple MyTuple 1 int\n# @struct MyStructB 4 field1:MyTuple field2:int|bool field3 field4:Variant\n# @var x MyStructB\nvar x: Dictionary = {\"field1\": [1], \"field2\": 1, \"field3\": 1, \"field4\": 1}\n", "res://tests/tmp_st_d1.gd")), "full example clean")
	h.check(_clean(h.analyze_text("extends Node\n# @struct Outer 2 a:Inner b:int\n# @struct Inner 1 x:int\n# @var v Outer\nvar v: Dictionary = {\"a\": {\"x\": 1}, \"b\": 2}\n", "res://tests/tmp_st_d2.gd")), "forward struct ref clean")
	h.check(_clean(h.analyze_text("extends Node\n# @struct ES 0\n# @var x ES\nvar x: Dictionary = {}\n", "res://tests/tmp_st_d3.gd")), "empty struct clean")
	h.check(_has_err(h.analyze_text("extends Node\n# @tuple E 0\n# @struct E 0\nvar x: E\n", "res://tests/tmp_st_d4.gd"), "struct_conflict", "existing type"), "tuple vs struct collides")
	h.check(_has_err(h.analyze_text("extends Node\n# @struct S 2 a:int b:String\n# @var x S\nvar x: Dictionary\n", "res://tests/tmp_st_d5.gd"), "struct_mismatch", "must be initialized with a compatible literal"), "missing init demands literal")
	h.check(_has_err(h.analyze_text("extends Node\n# @struct S 2 a:int b:String\n# @var x S\nvar x: Variant\n", "res://tests/tmp_st_d6.gd"), "struct_mismatch", "must be initialized with a compatible literal"), "variant decl demands literal")
	h.check(_has_err(h.analyze_text("extends Node\n# @struct S 2 a:int b:String\n# @var x S\nvar x\n", "res://tests/tmp_st_d7.gd"), "struct_mismatch", "must be initialized with a compatible literal"), "bare decl demands literal")


func _s_def_errors(h) -> void:
	h.check(_has_err(h.analyze_text("extends Node\n# @struct S 3 a:int b:int\nvar x: S\n", "res://tests/tmp_st_e1.gd"), "struct_malformed", "declares size 3 but lists 2"), "count mismatch malformed")
	h.check(_kinds(h.analyze_text("extends Node\n# @struct S a:int\nvar x: S\n", "res://tests/tmp_st_e2.gd")).has("struct_malformed"), "missing count malformed")
	h.check(_kinds(h.analyze_text("extends Node\n# @struct\nvar x := 1\n", "res://tests/tmp_st_e3.gd")).has("struct_malformed"), "empty malformed")
	h.check(_has_err(h.analyze_text("extends Node\n# @struct S 2 a:int a:String\n", "res://tests/tmp_st_e4.gd"), "struct_malformed", "repeats field"), "duplicate field malformed")
	h.check(_has_err(h.analyze_text("extends Node\n# @struct S 1 a:void\nvar x: S\n", "res://tests/tmp_st_e5.gd"), "struct_malformed", "not a valid field type"), "void malformed")
	h.check(_has_err(h.analyze_text("extends Node\n# @struct S 1 a:Nope\nvar x: S\n", "res://tests/tmp_st_e6.gd"), "struct_unknown_type", "'Nope'"), "unknown field type errors")
	h.check(_has_err(h.analyze_text("extends Node\n# @struct S 1 a:int\n# @struct S 1 a:int\nvar x: S\n", "res://tests/tmp_st_e7.gd"), "struct_conflict", "more than once"), "duplicate conflicts")
	h.check(_has_err(h.analyze_text("extends Node\n# @struct Item 1 a:int\nclass Item:\n\tpass\n", "res://tests/tmp_st_e8.gd"), "struct_conflict", "script member"), "class conflict")
	h.check(_has_err(h.analyze_text("extends Node\n# @struct Node 1 a:int\n", "res://tests/tmp_st_e9.gd"), "struct_conflict", "existing type"), "builtin conflict")
	h.check(_kinds(h.analyze_text("extends Node\nfunc f(\n\t\t# @struct S 1 a:int\n\t\ta: int\n\t) -> void:\n\tpass\n", "res://tests/tmp_st_e10.gd")).has("struct_misplaced"), "param misplaced")
	h.check(_kinds(h.analyze_text("extends Node\nfunc f():\n\t# @struct S 1 a:int\n\n\tpass\n", "res://tests/tmp_st_e11.gd")).has("struct_misplaced"), "body misplaced")
	h.check(_kinds(h.analyze_text("# @struct S 1 a:int\nclass_name Foo\n", "res://tests/tmp_st_e12.gd")).is_empty(), "header definition clean")


func _s_sem(h) -> void:
	h.check(_sem_kinds("extends Node\n# @struct S 2 a:int b:String\nvar x: S\n", "res://tests/tmp_st_s1.gd").is_empty(), "semantic accepts struct vartype")
	h.check(_sem_kinds("extends Node\n# @struct S 2 a:int b:String\nvar s: S\nvar d: Dictionary = s\n", "res://tests/tmp_st_s2.gd").is_empty(), "semantic struct to dict clean")
	h.check(_has_err_sem("extends Node\n# @struct S 2 a:int b:String\nvar d := {}\nvar x: S = d\n", "res://tests/tmp_st_s3.gd", "assign", "shape not provable"), "semantic dict to struct rejects")
	h.check(_sem_kinds("extends Node\n# @struct S 2 a:int b:String\nvar x: S = {\"a\": 1}\n", "res://tests/tmp_st_s4.gd").is_empty(), "semantic defers literals")
	h.check(_has_err_sem("extends Node\n# @struct S 2 a:int b:String\n# @struct T 1 q:int\nvar a: S\nvar b: T = a\n", "res://tests/tmp_st_s5.gd", "assign", "different struct types"), "semantic nominal mismatch")


func _s_use(h) -> void:
	h.check(_clean(h.analyze_text("extends Node\n# @struct S 2 a:int b:String\n# @var x S\nvar x: Dictionary = {\"a\": 1, \"b\": \"s\"}\n", "res://tests/tmp_st_u1.gd")), "conforming literal clean")
	h.check(_has_err(h.analyze_text("extends Node\n# @struct S 2 a:int b:String\n# @var x S\nvar x: Dictionary = {\"a\": 1}\n", "res://tests/tmp_st_u2.gd"), "struct_mismatch", "expects 2 fields, got 1"), "missing key mismatches")
	h.check(_has_err(h.analyze_text("extends Node\n# @struct S 2 a:int b:String\n# @var x S\nvar x: Dictionary = {\"a\": 1, \"b\": \"s\", \"c\": 2}\n", "res://tests/tmp_st_u3.gd"), "struct_mismatch", "expects 2 fields, got 3"), "extra key mismatches")
	h.check(_has_err(h.analyze_text("extends Node\n# @struct S 2 a:int b:String\n# @var x S\nvar x: Dictionary = {\"a\": \"s\", \"b\": \"s\"}\n", "res://tests/tmp_st_u4.gd"), "struct_mismatch", "field 'a' expects 'int'"), "wrong value mismatches")
	h.check(_has_err(h.analyze_text("extends Node\n# @struct S 2 a:int b:String\nvar d := {}\n# @var x S\nvar x: Dictionary = d\n", "res://tests/tmp_st_u5.gd"), "struct_mismatch", "must be initialized with a compatible literal"), "non-literal init demands literal")
	h.check(_clean(h.analyze_text("extends Node\n# @struct S 1 m:Variant\n# @var x S\nvar x: Dictionary = {\"m\": 1}\n", "res://tests/tmp_st_u6.gd")), "unknown field accepts literal")
	h.check(_has_err(h.analyze_text("extends Node\n# @struct S 2 a:int b:String\n# @var x S\nvar x: Dictionary = {\"a\": 1} # trailing note\n", "res://tests/tmp_st_u7.gd"), "struct_mismatch", "expects 2 fields, got 1"), "trailing comment keeps mismatch")
	h.check(_clean(h.analyze_text("extends Node\n# @struct S 2 a:int b:String\n# @var x S\nvar x: Dictionary = {\"a\": 1, \"b\": \"s\"} # trailing note\n", "res://tests/tmp_st_u8.gd")), "trailing comment keeps clean literal clean")
	h.check(_has_err(h.analyze_text("extends Node\n# @struct S 1 a:int\n# @var x S\nvar x: Dictionary = {\"a\": 3.14}\n", "res://tests/tmp_st_u9.gd"), "struct_mismatch", "field 'a' expects 'int', got 'float'"), "float narrowing mismatches")
	h.check(_clean(h.analyze_text("extends Node\n# @struct S 1 a:float\n# @var x S\nvar x: Dictionary = {\"a\": 1}\n", "res://tests/tmp_st_u10.gd")), "int widening clean")
	h.check(_has_err(h.analyze_text("extends Node\n# @struct S 2 a:int b:String\nfunc f():\n\t# @var x S\n\tvar x: Dictionary = {\"a\": 1, \"b\": \"s\"}\n\tx = {\"a\": 1}\n", "res://tests/tmp_st_u11.gd"), "struct_mismatch", "expects 2 fields, got 1"), "reassign missing key mismatches")
	h.check(_has_err(h.analyze_text("extends Node\n# @struct S 2 a:int b:String\nfunc f():\n\t# @var x S\n\tvar x: Dictionary = {\"a\": 1, \"b\": \"s\"}\n\tx = {\"a\": \"s\", \"b\": \"s\"}\n", "res://tests/tmp_st_u12.gd"), "struct_mismatch", "field 'a' expects 'int'"), "reassign value mismatches")
	h.check(_clean(h.analyze_text("extends Node\n# @struct S 2 a:int b:String\nfunc f():\n\t# @var x S\n\tvar x: Dictionary = {\"a\": 1, \"b\": \"s\"}\n\tx = {\"a\": 2, \"b\": \"t\"}\n", "res://tests/tmp_st_u13.gd")), "reassign conforming clean")
	h.check(_has_err(h.analyze_text("extends Node\n# @struct S 2 a:int b:String\nfunc f():\n\t# @var x S\n\tvar x: Dictionary = {\"a\": 1, \"b\": \"s\"}\n\tvar y: Dictionary = {\"a\": 1, \"b\": \"s\"}\n\tx = y\n", "res://tests/tmp_st_u14.gd"), "struct_mismatch", "can only be assigned a literal value"), "reassign variable demands literal")
	h.check(_has_err(h.analyze_text("extends Node\n# @struct S 2 a:int b:String\nfunc f():\n\t# @var x S\n\tvar x: Dictionary = {\"a\": 1, \"b\": \"s\"}\n\tx = mk()\n", "res://tests/tmp_st_u15.gd"), "struct_mismatch", "can only be assigned a literal value"), "reassign call demands literal")


func _s_keys_members(h) -> void:
	h.check(_clean(h.analyze_text("extends Node\n# @struct S 2 a:int b:String\n# @var x S\nvar x: Dictionary = {\"a\": 1, \"b\": \"s\"}\nfunc f():\n\tprint(x.a)\n", "res://tests/tmp_st_k1.gd")), "member read clean")
	h.check(_has_err(h.analyze_text("extends Node\n# @struct S 2 a:int b:String\n# @var x S\nvar x: Dictionary = {\"a\": 1, \"b\": \"s\"}\nfunc f():\n\tprint(x.nope)\n", "res://tests/tmp_st_k2.gd"), "missing_member", "has no member 'nope'"), "member bogus errors")
	h.check(_clean(h.analyze_text("extends Node\n# @struct S 1 a:int\n# @var x S\nvar x: Dictionary = {\"a\": 1}\nfunc f():\n\tprint(x.keys())\n", "res://tests/tmp_st_k3.gd")), "dict method clean")
	h.check(_clean(h.analyze_text("extends Node\n# @struct S 2 a:int b:String\n# @var x S\nvar x: Dictionary = {\"a\": 1, \"b\": \"s\"}\nfunc f():\n\tprint(x[\"a\"])\n", "res://tests/tmp_st_k4.gd")), "key read clean")
	h.check(_has_err(h.analyze_text("extends Node\n# @struct S 2 a:int b:String\n# @var x S\nvar x: Dictionary = {\"a\": 1, \"b\": \"s\"}\nfunc f():\n\tprint(x[\"z\"])\n", "res://tests/tmp_st_k5.gd"), "missing_member", "has no member 'z'"), "key unknown errors")
	h.check(_clean(h.analyze_text("extends Node\n# @struct S 2 a:int b:String\n# @var x S\nvar x: Dictionary = {\"a\": 1, \"b\": \"s\"}\nfunc f(k):\n\tprint(x[k])\n", "res://tests/tmp_st_k6.gd")), "dynamic key skips")


func _s_field_access(h) -> void:
	var head := "extends Node\n# @struct S 2 x:int y:int\nfunc f():\n\t# @var a S\n\tvar a: Dictionary = {\"x\": 0, \"y\": 0}\n"
	h.check(_has_err(h.analyze_text(head + "\ta.x = ''\n", "res://tests/tmp_st_w1.gd"), "struct_mismatch", "field 'x' expects 'int', got 'String'"), "member store wrong type mismatches")
	h.check(_clean(h.analyze_text(head + "\ta.x = 1\n", "res://tests/tmp_st_w2.gd")), "member store conforming clean")
	h.check(_clean(h.analyze_text(head + "\tvar v := ''\n\ta.x = v\n", "res://tests/tmp_st_w3.gd")), "member store dynamic silent")
	h.check(_clean(h.analyze_text(head + "\ta.x += 1\n", "res://tests/tmp_st_w4.gd")), "member compound store silent")
	var unknown_member: Dictionary = h.analyze_text(head + "\ta.nope = 1\n", "res://tests/tmp_st_w5.gd")
	h.check(_has_err(unknown_member, "missing_member", "has no member 'nope'"), "member store unknown still reported")
	h.check((unknown_member.get("errors", []) as Array).size() == 1, "member store unknown never double reports")
	h.check(_has_err(h.analyze_text(head + "\ta['x'] = ''\n", "res://tests/tmp_st_w6.gd"), "struct_mismatch", "field 'x' expects 'int', got 'String'"), "key store wrong type mismatches")
	h.check(_clean(h.analyze_text(head + "\ta['x'] = 1\n", "res://tests/tmp_st_w7.gd")), "key store conforming clean")
	var unknown_key: Dictionary = h.analyze_text(head + "\ta['nope'] = 1\n", "res://tests/tmp_st_w8.gd")
	h.check(_has_err(unknown_key, "missing_member", "has no member 'nope'"), "key store unknown still reported")
	h.check((unknown_key.get("errors", []) as Array).size() == 1, "key store unknown never double reports")
	h.check(_has_err(h.analyze_text(head + "\ta.set('x', '')\n", "res://tests/tmp_st_w9.gd"), "struct_mismatch", "field 'x' expects 'int', got 'String'"), "set wrong type mismatches")
	h.check(_clean(h.analyze_text(head + "\ta.set('x', 1)\n", "res://tests/tmp_st_w10.gd")), "set conforming clean")
	var unknown_set: Dictionary = h.analyze_text(head + "\ta.set('nope', 1)\n", "res://tests/tmp_st_w11.gd")
	h.check(_has_err(unknown_set, "missing_member", "has no member 'nope'"), "set unknown key errors")
	h.check((unknown_set.get("errors", []) as Array).size() == 1, "set unknown never double reports")
	h.check(_clean(h.analyze_text(head + "\tvar k := 'x'\n\ta.set(k, 1)\n", "res://tests/tmp_st_w12.gd")), "set dynamic key silent")
	h.check(_clean(h.analyze_text("extends Node\nfunc f():\n\tvar d := {\"x\": 0}\n\td.x = ''\n", "res://tests/tmp_st_w13.gd")), "plain dict stores untouched")
	h.check(_has_err(h.analyze_text(head + "\tvar s: String = a.x\n", "res://tests/tmp_st_r1.gd"), "assign_mismatch", "from struct field 'S.x'"), "member read into slot mismatches")
	h.check(_clean(h.analyze_text(head + "\tvar i: int = a.x\n", "res://tests/tmp_st_r2.gd")), "member read conforming clean")
	h.check(_has_err(h.analyze_text(head + "\tvar s: String\n\ts = a.x\n", "res://tests/tmp_st_r3.gd"), "assign_mismatch", "from struct field 'S.x'"), "member reassign mismatches")
	h.check(_has_err(h.analyze_text(head + "\tvar s: String = a['x']\n", "res://tests/tmp_st_r4.gd"), "assign_mismatch", "from struct field 'S.x'"), "key read into slot mismatches")
	h.check(_clean(h.analyze_text(head + "\tvar i: int = a['x']\n", "res://tests/tmp_st_r5.gd")), "key read conforming clean")
	h.check(_has_err(h.analyze_text(head + "\tvar s: String = a.get('x', 0)\n", "res://tests/tmp_st_r6.gd"), "assign_mismatch", "from struct field 'S.x'"), "get read into slot mismatches")
	h.check(_clean(h.analyze_text(head + "\tvar i: int = a.get('x', 0)\n", "res://tests/tmp_st_r7.gd")), "get read conforming clean")
	h.check(_clean(h.analyze_text(head + "\tvar s: String = a.get('nope', 0)\n", "res://tests/tmp_st_r8.gd")), "get unknown key skips slot")
	h.check(_clean(h.analyze_text(head + "\tvar k := 'x'\n\tvar s: String = a.get(k, 0)\n", "res://tests/tmp_st_r9.gd")), "get dynamic key skips slot")
	h.check(_clean(h.analyze_text(head + "\tvar s = a.x\n", "res://tests/tmp_st_r10.gd")), "untyped read target silent")
	h.check(_clean(h.analyze_text("extends Node\nfunc f():\n\tvar d := {\"x\": 0}\n\tvar s: String = d.x\n", "res://tests/tmp_st_r11.gd")), "plain dict reads untouched")


func _s_mutate(h) -> void:
	var head := "extends Node\n# @struct S 2 x:int y:int\nfunc f():\n\t# @var a S\n\tvar a: Dictionary = {\"x\": 0, \"y\": 0}\n"
	for m in ["clear()", "erase('x')", "merge({\"z\": 1})", "assign({\"x\": 1})", "get_or_add('z', 1)"]:
		h.check(_has_err(h.analyze_text(head + "\ta." + m + "\n", "res://tests/tmp_st_x.gd"), "struct_mutate", "fixed-shape"), "shape method mutates: " + m)
	h.check(_clean(h.analyze_text(head + "\ta.sort()\n", "res://tests/tmp_st_x2.gd")), "key reorder untouched")
	h.check(_clean(h.analyze_text(head + "\ta.make_read_only()\n", "res://tests/tmp_st_x3.gd")), "read-only freeze untouched")
	h.check(_clean(h.analyze_text(head + "\tvar k: Array = a.keys()\n", "res://tests/tmp_st_x4.gd")), "readers untouched")
	h.check(_clean(h.analyze_text("extends Node\nfunc f():\n\tvar d := {\"x\": 0}\n\td.clear()\n", "res://tests/tmp_st_x5.gd")), "plain dict untouched")


func _s_canon(h) -> void:
	h.check(_clean(h.analyze_text("extends Node\n# @struct S 1 a:string\n# @var x S\nvar x: Dictionary = {\"a\": \"s\"}\n", "res://tests/tmp_st_c1.gd")), "lowercase field type corrected")
	h.check(_clean(h.analyze_text("extends Node\n# @tuple T 1 object\n# @var x T\nvar x: Array = [null]\n", "res://tests/tmp_st_c2.gd")), "lowercase tuple item corrected")
	h.check(_clean(h.analyze_text("extends Node\n# @return object\nfunc f():\n\tpass\n", "res://tests/tmp_st_c3.gd")), "lowercase return corrected")


func _s_json(h) -> void:
	h.analyze_text("extends Node\n# @struct JStruct 2 a:int b:String|int\nvar x: JStruct\n", "res://tests/tmp_st_j1.gd")
	var info: Dictionary = h.load_json("res://.godot/0GnumarusGodotProjectAnalyzerSuiteData/user/JStruct.json")
	h.check(str(info.get("kind", "")) == "struct", "json kind struct")
	h.check(int(info.get("size", -1)) == 2, "json size kept")
	var fields: Array = info.get("fields", [])
	h.check(fields.size() == 2 and str((fields[0] as Dictionary).get("type", "")) == "int", "json fields kept")
	h.check(str((fields[1] as Dictionary).get("type", "")) == "String|int", "json union spelled")
