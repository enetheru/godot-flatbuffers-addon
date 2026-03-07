#  ██████  ██████   █████  ███    ███ ███    ███  █████  ██████
# ██       ██   ██ ██   ██ ████  ████ ████  ████ ██   ██ ██   ██
# ██   ███ ██████  ███████ ██ ████ ██ ██ ████ ██ ███████ ██████
# ██    ██ ██   ██ ██   ██ ██  ██  ██ ██  ██  ██ ██   ██ ██   ██
#  ██████  ██   ██ ██   ██ ██      ██ ██      ██ ██   ██ ██   ██

const StackFrame = preload("uid://c0ub8clj4bhhv")

enum Type {
	NONE, # so that SCHEMA isnt at zero which is conflated with bool
	# schema grammer:https://flatbuffers.dev/flatbuffers_grammar.html
	SCHEMA, # = include ( namespace_decl
	#					| type_decl
	#					| enum_decl
	#					| root_decl
	#					| file_extension_decl
	#					| file_identifier_decl
	#					| attribute_decl
	#					| rpc_decl
	#					| object )*
	INCLUDE,# = include string_constant ;
	NAMESPACE_DECL, # = namespace ident ( . ident )* ;
	ATTRIBUTE_DECL, # = attribute ident | "</tt>ident<tt>" ;
	TYPE_DECL, # = ( table | struct ) ident metadata { field_decl+ }
	ENUM_DECL, # = enum ident:type metadata { commasep( enumval_decl ) }
	UNION_DECL, # = union ident metadata { commasep( enumval_decl ) }
	ROOT_DECL, # = root_type ident ;
	FIELD_DECL, # = ident:type [ = scalar ] metadata ;
	RPC_DECL, # = rpc_service ident { rpc_method+ }
	RPC_METHOD, # = ident ( ident ):ident metadata ;
	TYPE, # = bool | byte | ubyte | short | ushort | int | uint | float | long | ulong | double | int8 | uint8 | int16 | uint16 | int32 | uint32| int64 | uint64 | float32 | float64 | string | [ type ] | ident
	ENUMVAL_DECL, # = ident [ = integer_constant ]
	UNIONVAL_DECL, # = ident [ : ident ]
	METADATA, # = [ ( commasep( ident [:single_value ] ) ) ]
	SCALAR, # = boolean_constant | integer_constant | float_constant
	OBJECT, # = { commasep( ident:value ) }
	SINGLE_VALUE, # = scalar | string_constant
	VALUE, # = single_value | object | [ commasep( value ) ]
	COMMASEP, #(x) = [ x ( , x )* ]
	FILE_EXTENSION_DECL, # = file_extension string_constant ;
	FILE_IDENTIFIER_DECL, # = file_identifier string_constant ;
	STRING_CONSTANT, # = \".*?\\"
	IDENT, # = [a-zA-Z_][a-zA-Z0-9_]*
	#DIGIT, # [:digit:] = [0-9]
	#XDIGIT, # [:xdigit:] = [0-9a-fA-F]
	#DEC_INTEGER_CONSTANT, # = [-+]?[:digit:]+
	#HEX_INTEGER_CONSTANT, # = [-+]?0[xX][:xdigit:]+
	INTEGER_CONSTANT, # = dec_integer_constant | hex_integer_constant
	#DEC_FLOAT_CONSTANT, # = [-+]?(([.][:digit:]+)|([:digit:]+[.][:digit:]*)|([:digit:]+))([eE][-+]?[:digit:]+)?
	#HEX_FLOAT_CONSTANT, # = [-+]?0[xX](([.][:xdigit:]+)|([:xdigit:]+[.][:xdigit:]*)|([:xdigit:]+))([pP][-+]?[:digit:]+)
	#SPECIAL_FLOAT_CONSTANT, # = [-+]?(nan|inf|infinity)
	#FLOAT_CONSTANT, # = dec_float_constant | hex_float_constant | special_float_constant
	#BOOLEAN_CONSTANT, # = true | false
}

func _init( t:Type, b:Dictionary = {} ) -> void:
	type = t
	for key:Variant in b.keys():
		bindings[key] = b[key]


var type:Type

var bindings:Dictionary

var data:Dictionary


func _to_string() -> String:
	var parts:Array = [ '/',
		Type.find_key(type),
		JSON.stringify( bindings ),
		JSON.stringify( data ) ]
	return "".join(parts).replace(',',', ').replace('{','{ ').replace('}',' }')


func duplicate() -> Object:
	var new_frame:StackFrame = new( type )
	# NOTE: For some reason duplicate wasnt working for my dictionaries.
	# https://github.com/godotengine/godot/issues/96627
	for key:Variant in bindings.keys():
		new_frame.bindings[key] = bindings[key]
	for key:Variant in data.keys():
		new_frame.data[key] = data[key]
	return new_frame


func bind( dict:Dictionary ) -> void:
	bindings = dict
