# @integrity_ignore_file (test harness uses virtual paths)
extends RefCounted

## Enum-as-type suite: per-enum JSONs (user declarations with computed
## values, dumper emission), enum names in type positions, the
## symmetric enum-int narrowing rule, literal value checks on
## writes, member reads through enum bases, and .new()/extends
## rejections. `is`/`typeof`, bitfields and call-site args stay
## documented gaps.

const H = preload("res://addons/0GnumarusGodotProjectAnalyzerSuite/tests/helpers.gd")
const Analyzer = preload("res://addons/0GnumarusGodotProjectAnalyzerSuite/GnumarusGodotProjectAnalyzerSuiteGdscriptAnalyzer.gd")
const Dumper = preload("res://addons/0GnumarusGodotProjectAnalyzerSuite/GnumarusGodotProjectAnalyzerSuiteGodotTypesInfoDumper.gd")


func run() -> Dictionary:
	var h = H.new()
	h.suite = "enum"
	_e_json(h)
	_e_dumper(h)
	_e_narrow(h)
	_e_values(h)
	_e_members(h)
	_e_misuse(h)
	return h.result()


func _has_err(res: Dictionary, kind: String, part: String) -> bool:
	for e in res.get("errors", []):
		if str((e as Dictionary).get("kind", "")) == kind and part in str((e as Dictionary).get("message", "")):
			return true
	return false


func _clean(res: Dictionary) -> bool:
	return (res.get("errors", []) as Array).is_empty()


func _e_json(h) -> void:
	h.check(Analyzer._parse_int_literal("42") == {"ok": true, "value": 42}, "decimal parses")
	h.check(Analyzer._parse_int_literal("0x10") == {"ok": true, "value": 16}, "hex parses")
	h.check(Analyzer._parse_int_literal("0b101") == {"ok": true, "value": 5}, "binary parses")
	h.check(Analyzer._parse_int_literal("0o17") == {"ok": true, "value": 15}, "octal parses")
	h.check(Analyzer._parse_int_literal("1_000") == {"ok": true, "value": 1000}, "underscores strip")
	h.check(Analyzer._parse_int_literal("-7") == {"ok": true, "value": -7}, "sign parses")
	h.check(not bool(Analyzer._parse_int_literal("12x").get("ok", true)), "trailing garbage rejects")
	h.check(not bool(Analyzer._parse_int_literal("").get("ok", true)), "empty rejects")
	h.check(not bool(Analyzer._parse_int_literal("0x").get("ok", true)), "bare prefix rejects")
	var src := "extends Node\nenum ValEnum { A, B = 5, C, D = -1, E = 0x10 }\nvar x := 1\n"
	var res: Dictionary = h.analyze_text(src, "res://tests/tmp_en_j1.gd")
	var info: Dictionary = h.load_json("res://.godot/0GnumarusGodotProjectAnalyzerSuiteData/user/tests_tmp_en_j1.ValEnum.json")
	h.check(str(info.get("kind", "")) == "enum", "user enum json kind")
	var got := {}
	for v in info.get("values", []):
		if v is Dictionary:
			got[str((v as Dictionary).get("name", ""))] = (v as Dictionary).get("value", null)
	h.check(got == {"A": 0.0, "B": 5.0, "C": 6.0, "D": -1.0, "E": 16.0}, "user enum values compute")


func _e_dumper(h) -> void:
	var d = Dumper.new()
	h.check(not Dumper._is_enum_file("CanvasItem.json"), "plain file not enum")
	h.check(Dumper._is_enum_file("CanvasItem.TextureFilter.json"), "dotted file is enum")
	h.check(Dumper._is_enum_file("A.B.C.json"), "nested dotted is enum")
	var before := _user_files()
	d.output_base = "res://.godot/0GnumarusGodotProjectAnalyzerSuiteData/user/tmp_enum_dump"
	var infos := {"DumpCls": {"name": "DumpCls", "kind": "class", "enums": [{"name": "Mode", "is_bitfield": false, "values": [{"name": "OFF", "value": 0}, {"name": "ON", "value": 2.0}]}]}}
	d.write_infos(infos)
	var back: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://.godot/0GnumarusGodotProjectAnalyzerSuiteData/user/tmp_enum_dump/classes/DumpCls.Mode.json"))
	h.check(back is Dictionary and str((back as Dictionary).get("kind", "")) == "enum", "dumper emits enum file")
	h.check(str((back as Dictionary).get("name", "")) == "DumpCls.Mode", "dumper names dotted")
	var vals: Array = (back as Dictionary).get("values", [])
	h.check(vals.size() == 2 and int((vals[1] as Dictionary).get("value", -1)) == 2, "dumper coerces values to int")
	_rmdir("res://.godot/0GnumarusGodotProjectAnalyzerSuiteData/user/tmp_enum_dump")
	_clean_user_jsons(before)


func _e_narrow(h) -> void:
	h.check(_clean(h.analyze_text("extends Node\nenum MyEnum { A, B }\n# @var x MyEnum\nvar x: int\n", "res://tests/tmp_en_n1.gd")), "enum narrows int")
	h.check(_clean(h.analyze_text("extends Node\nenum MyEnum { A, B }\n# @var x int\nvar x: MyEnum\n", "res://tests/tmp_en_n2.gd")), "int narrows enum")
	h.check(_clean(h.analyze_text("extends Node\nclass Outer:\n\tenum E { X }\n# @var x Outer.E\nvar x: int\n", "res://tests/tmp_en_n3.gd")), "dotted enum narrows int")
	h.check(_clean(h.analyze_text("extends Node\nfunc f() -> void:\n\tvar x: CanvasItem.TextureFilter = 1\n", "res://tests/tmp_en_n4.gd")), "native enum vartype clean")


func _e_values(h) -> void:
	var decl := "extends Node\nenum MyEnum { A, B }\nfunc f() -> void:\n\tvar x: MyEnum = 1\n"
	h.check(_clean(h.analyze_text(decl, "res://tests/tmp_en_v01.gd")), "int literal clean")
	h.check(_clean(h.analyze_text("extends Node\nenum MyEnum { A, B }\nfunc f() -> void:\n\tvar x: MyEnum = MyEnum.A\n", "res://tests/tmp_en_v02.gd")), "enum value clean")
	h.check(_clean(h.analyze_text("extends Node\nenum MyEnum { A, B }\nfunc f() -> void:\n\tvar y := 1\n\tvar x: MyEnum = y\n", "res://tests/tmp_en_v03.gd")), "unprovable silent")
	h.check(_clean(h.analyze_text("extends Node\nenum MyEnum { A, B }\nfunc f() -> void:\n\tvar x: MyEnum = null\n", "res://tests/tmp_en_v04.gd")), "null silent")
	h.check(_has_err(h.analyze_text("extends Node\nenum MyEnum { A, B }\nfunc f() -> void:\n\tvar x: MyEnum = \"s\"\n", "res://tests/tmp_en_v05.gd"), "enum_mismatch", "cannot assign 'String'"), "string literal errors")
	h.check(_has_err(h.analyze_text("extends Node\nenum MyEnum { A, B }\nfunc f() -> void:\n\tvar x: MyEnum = 3.14\n", "res://tests/tmp_en_v06.gd"), "enum_mismatch", "cannot assign 'float'"), "float literal errors")
	h.check(_has_err(h.analyze_text("extends Node\nenum MyEnum { A, B }\nfunc f() -> void:\n\tvar x: MyEnum = true\n", "res://tests/tmp_en_v07.gd"), "enum_mismatch", "cannot assign 'bool'"), "bool literal errors")
	h.check(_has_err(h.analyze_text(decl + "\tx = \"s\"\n", "res://tests/tmp_en_v08.gd"), "enum_mismatch", "cannot assign 'String'"), "reassign string errors")
	h.check(_clean(h.analyze_text(decl + "\tx = 2\n", "res://tests/tmp_en_v09.gd")), "reassign int clean")
	h.check(_has_err(h.analyze_text("extends Node\nenum MyEnum { A, B }\n# @return MyEnum\nfunc g() -> Variant:\n\treturn \"s\"\n", "res://tests/tmp_en_v10.gd"), "enum_mismatch", "cannot assign 'String'"), "return string errors")
	h.check(_clean(h.analyze_text("extends Node\nenum MyEnum { A, B }\n# @return MyEnum\nfunc g() -> Variant:\n\treturn MyEnum.B\n", "res://tests/tmp_en_v11.gd")), "return value clean")
	h.check(_has_err(h.analyze_text("extends Node\nfunc f() -> void:\n\tvar x: CanvasItem.TextureFilter = \"s\"\n", "res://tests/tmp_en_v12.gd"), "enum_mismatch", "CanvasItem.TextureFilter"), "native slot errors")


func _e_members(h) -> void:
	h.check(_clean(h.analyze_text("extends Node\nenum MyEnum { A, B }\nfunc f() -> void:\n\tvar x := MyEnum.A\n", "res://tests/tmp_en_m1.gd")), "value read clean")
	h.check(_has_err(h.analyze_text("extends Node\nenum MyEnum { A, B }\nfunc f() -> void:\n\tvar x := MyEnum.NOPE\n", "res://tests/tmp_en_m2.gd"), "missing_member", "has no member 'NOPE'"), "unknown value errors")
	h.check(_has_err(h.analyze_text("extends Node\nfunc f() -> void:\n\tvar x := CanvasItem.TextureFilter.BOGUS\n", "res://tests/tmp_en_m3.gd"), "missing_member", "has no member 'BOGUS'"), "native unknown value errors")


func _e_misuse(h) -> void:
	h.check(_has_err(h.analyze_text("extends Node\nenum MyEnum { A, B }\nfunc f() -> void:\n\tvar x := MyEnum.new()\n", "res://tests/tmp_en_u1.gd"), "enum_mismatch", "cannot instantiate enum"), "user enum new errors")
	h.check(_has_err(h.analyze_text("extends Node\nfunc f() -> void:\n\tvar x := CanvasItem.TextureFilter.new()\n", "res://tests/tmp_en_u2.gd"), "enum_mismatch", "cannot instantiate enum"), "native enum new errors")
	h.check(_has_err(h.analyze_text("extends Node\nenum MyEnum { A, B }\nclass C extends MyEnum:\n\tpass\n", "res://tests/tmp_en_u3.gd"), "enum_mismatch", "cannot use enum"), "extends user enum errors")
	h.check(_has_err(h.analyze_text("extends CanvasItem.TextureFilter\n", "res://tests/tmp_en_u4.gd"), "enum_mismatch", "cannot use enum"), "extends native enum errors")


func _user_files() -> Array:
	var dir := ProjectSettings.globalize_path("res://.godot/0GnumarusGodotProjectAnalyzerSuiteData/user")
	if not DirAccess.dir_exists_absolute(dir):
		return []
	return DirAccess.get_files_at(dir)


func _clean_user_jsons(before: Array) -> void:
	var base := ProjectSettings.globalize_path("res://.godot/0GnumarusGodotProjectAnalyzerSuiteData/user") + "/"
	for f in _user_files():
		if not before.has(f):
			DirAccess.remove_absolute(base + str(f))


func _rmdir(path: String) -> void:
	var abs := ProjectSettings.globalize_path(path)
	if not DirAccess.dir_exists_absolute(abs):
		return
	for f in DirAccess.get_files_at(abs):
		DirAccess.remove_absolute(abs + "/" + str(f))
	for d in DirAccess.get_directories_at(abs):
		_rmdir(path + "/" + str(d))
	DirAccess.remove_absolute(abs)
