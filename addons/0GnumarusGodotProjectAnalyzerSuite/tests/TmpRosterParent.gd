class_name TmpRosterParent
extends RefCounted

## Parent fixture for cross-file inheritance tests: members resolve
## through TmpRosterChild via the JSON extends chain.


# @param m Node not_null
func take(m: Node) -> void:
	pass


func plain(m: Node) -> void:
	pass


# @private
func hid() -> void:
	pass
