@tool
class_name FlatBuffersOpts
extends Resource

const Print = preload("uid://cbluyr4ifn8g3")
const LogLevel = Print.LogLevel
const Token = preload("uid://cvcd6kyaa4f1a")

var editor_settings := EditorInterface.get_editor_settings()

@export
## A variable to help me turn on and off debug features and tests.
var debug:bool = true

#@export_group("GeneratorConfigs", 'config_')

#@export_custom(PROPERTY_HINT_ARRAY_TYPE, "FlatBuffersGeneratorOpts")
var config_main:FlatBuffersGeneratorOpts = preload("uid://b8vn3e2cuhqy3")

#@export_custom(PROPERTY_HINT_ARRAY_TYPE, "FlatBuffersGeneratorOpts")
var config_list:Array[FlatBuffersGeneratorOpts] = [preload("uid://b8vn3e2cuhqy3")]


# │ ___    _ _ _           _
# │| __|__| (_) |_ ___ _ _| |   ___  __ _
# │| _|/ _` | |  _/ _ \ '_| |__/ _ \/ _` |
# │|___\__,_|_|\__\___/_| |____\___/\__, |
# ╰─────────────────────────────────|___/──
@export_group("EditorLog", "editorlog_")
@export_custom( PROPERTY_HINT_ENUM_SUGGESTION,
	"SILENT:0,CRITICAL:1,ERROR:2,WARNING:3,NOTICE:4,DEBUG:5,TRACE:6")
var editorlog_verbosity:int = 0


# │ _  _ _      _   _   _ _      _   _
# │| || (_)__ _| |_| |_| (_)__ _| |_| |_
# │| __ | / _` | ' \  _| | / _` | ' \  _|
# │|_||_|_\__, |_||_\__|_|_\__, |_||_\__|
# ╰───────|___/────────────|___/──────────
@export
var highlight_error:bool = true
@export
var highlight_warning:bool = true

@export_group("Colours")
# │  ___     _
# │ / __|___| |___ _  _ _ _ ___
# │| (__/ _ \ / _ \ || | '_(_-<
# │ \___\___/_\___/\_,_|_| /__/
# ╰──────────────────────────────
@export_subgroup("Syntax", "color_syntax_")
# Tokens
@export
var color_syntax_unknown:Color = editor_settings.get_setting("text_editor/theme/highlighting/text_color")
@export
var color_syntax_comment:Color = editor_settings.get_setting("text_editor/theme/highlighting/comment_color")
@export
var color_syntax_keyword:Color = editor_settings.get_setting("text_editor/theme/highlighting/keyword_color")
@export
var color_syntax_type:Color = editor_settings.get_setting("text_editor/theme/highlighting/base_type_color")
@export
var color_syntax_string:Color = editor_settings.get_setting("text_editor/theme/highlighting/string_color")
@export
var color_syntax_punct:Color = editor_settings.get_setting("text_editor/theme/highlighting/text_color")
@export
var color_syntax_ident:Color = editor_settings.get_setting("text_editor/theme/highlighting/symbol_color")
@export
var color_syntax_scalar:Color = editor_settings.get_setting("text_editor/theme/highlighting/number_color")
@export
var color_syntax_meta:Color = editor_settings.get_setting("text_editor/theme/highlighting/text_color")

# log levels
@export_subgroup("Notice", "color_notice_")
@export
var color_notice_critical:Color = editor_settings.get_setting("text_editor/theme/highlighting/comment_markers/critical_color")
@export
var color_notice_error:Color = editor_settings.get_setting("text_editor/theme/highlighting/comment_markers/critical_color")
@export
var color_notice_warning:Color = editor_settings.get_setting("text_editor/theme/highlighting/comment_markers/warning_color")
@export
var color_notice_notice:Color = editor_settings.get_setting("text_editor/theme/highlighting/text_color")
@export
var color_notice_debug:Color = editor_settings.get_setting("text_editor/theme/highlighting/comment_color")
@export
var color_notice_trace:Color = editor_settings.get_setting("text_editor/theme/highlighting/comment_color")


func get_colour(type:int) -> Color:
	match type:
		LogLevel.CRITICAL:return color_notice_critical
		LogLevel.ERROR:return color_notice_error
		LogLevel.WARNING:return color_notice_warning
		LogLevel.NOTICE:return color_notice_notice
		LogLevel.DEBUG:return color_notice_debug
		LogLevel.TRACE:return color_notice_trace
		# Token.Type starts at color_10
		Token.Type.NULL:return color_syntax_unknown
		Token.Type.COMMENT:return color_syntax_comment
		Token.Type.KEYWORD:return color_syntax_keyword
		Token.Type.TYPE:return color_syntax_type
		Token.Type.STRING:return color_syntax_string
		Token.Type.PUNCT:return color_syntax_punct
		Token.Type.IDENT:return color_syntax_ident
		Token.Type.SCALAR:return color_syntax_scalar
		Token.Type.META:return color_syntax_meta
		Token.Type.UNKNOWN:return color_syntax_unknown
		Token.Type.EOL:return color_syntax_unknown
		Token.Type.EOF:return color_syntax_unknown
	return Color.DEEP_PINK
