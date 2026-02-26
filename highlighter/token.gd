##  _____    _              [br]
## |_   _|__| |_____ _ _    [br]
##   | |/ _ \ / / -_) ' \   [br]
##   |_|\___/_\_\___|_||_|  [br]
## ------------------------ [br]
## 
## 
## Token class helps with static typing to catch and fix bugs.

## Types of token that the reader knows about
enum Type {
	NULL = 100,
	COMMENT,
	KEYWORD,
	TYPE,
	STRING,
	PUNCT,
	IDENT,
	SCALAR,
	META,
	EOL,
	EOF,
	UNKNOWN,
}

## Default Values
static var defs:Dictionary = {
	&"line":0, &"col":0, &"type":Type.NULL, &"t":"String"
}

# --- Properties ---------

var line:int ## Line Number
var col:int ## Column Number
var type:Type = Type.UNKNOWN ## Token Type
var t:String ## Token String

## returns [code]true[/code] of the toke type EOF?
func eof() -> bool: return type == Type.EOF

## returns [code]true[/code] if the toke type EOL?
func eol() -> bool: return type == Type.EOL


## Constructor
func _init( line_or_dict:Variant = 0, _col:int = 0, _type:Type = Type.NULL, _t:String = "" ) -> void:
	if line_or_dict is int:
		line = line_or_dict; col = _col; type = _type; t = _t
	elif line_or_dict is Dictionary:
		var dict:Dictionary = line_or_dict
		from_dict( dict )
	else:
		var typename:String = type_string(typeof(line_or_dict))
		assert(false, "Token._init( '%s', ... ) is not an int or dict" % typename )


## assignment from dictionary
func from_dict( value:Dictionary ) -> void:
	# Validate and Assign
	for key:StringName in defs.keys():
		# Missing keys are not an error, assigning default
		if not key in value: set(key, defs[key])
		# different types is an error.
		if typeof(defs[key]) != typeof(value[key]):
			var typename:String = type_string(typeof(defs[key]))
			assert( false, "Invalid type '%s:%s' " % [key, typename ])
			set(key, defs[key])
		# value[key] passed validation.
		set(key, value[key])


## conversion to string
func _to_string() -> String:
	# Line numbers in the editor gutter start at 1
	return "Token{ line:%d, col:%d, type:%s, t:'%s' }" % [line+1, col+1, Type.find_key(type), t.c_escape()]
