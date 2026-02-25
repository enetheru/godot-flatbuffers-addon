@tool
class_name FlatBuffersPlugin
extends EditorPlugin

func                        _________IMPORTS_________              ()->void:pass

const Common = preload("uid://dyt7vhpvpirgf")
const LogLevel = Common.LogLevel

const SettingsHelper = preload('uid://bqe6tk0yrwq8u')
var settings_mgr:SettingsHelper

# Supporting Scripts
const GeneratorOpts = preload("uid://bf5ukybn2h3kd")
const SchemaHighlighter = preload("uid://ddcfjoxe7i5jo")
const Token = preload("uid://cvcd6kyaa4f1a")

# Supporting Assets
const ICON_BW_TINY = preload("uid://d32jh3dw5nypp")

const author:String = "enetheru"
const PluginName:String = "FlatBuffers"
const plugin_name:String = "flatbuffers"
#const plugin_path:String = "res://addons/" + author + "." + plugin_name + '-addon'
# we can get the plugin path using its resource_path.get_base_dir() anytime.

# ██████  ██████   ██████  ██████  ███████ ██████  ████████ ██ ███████ ███████ #
# ██   ██ ██   ██ ██    ██ ██   ██ ██      ██   ██    ██    ██ ██      ██      #
# ██████  ██████  ██    ██ ██████  █████   ██████     ██    ██ █████   ███████ #
# ██      ██   ██ ██    ██ ██      ██      ██   ██    ██    ██ ██           ██ #
# ██      ██   ██  ██████  ██      ███████ ██   ██    ██    ██ ███████ ███████ #
func                        ________PROPERTIES_______              ()->void:pass

var editor_settings := EditorInterface.get_editor_settings()

# Reference to self so we can do things since we are already instantiated.
static var _prime:FlatBuffersPlugin

@export_custom( PROPERTY_HINT_RESOURCE_TYPE, "FlatBuffersOpts", 
	SettingsHelper.SETTING_BASIC )
var opts := FlatBuffersOpts.new()

@export_custom( PROPERTY_HINT_NONE, "", 
	SettingsHelper.SETTING_BASIC )
var flatc_opts := GeneratorOpts.new()

var highlighter:SchemaHighlighter

var context_menus:Dictionary[EditorContextMenuPlugin.ContextMenuSlot,EditorContextMenuPlugin]


#      ██████  ██    ██ ███████ ██████  ██████  ██ ██████  ███████ ███████     #
#     ██    ██ ██    ██ ██      ██   ██ ██   ██ ██ ██   ██ ██      ██          #
#     ██    ██ ██    ██ █████   ██████  ██████  ██ ██   ██ █████   ███████     #
#     ██    ██  ██  ██  ██      ██   ██ ██   ██ ██ ██   ██ ██           ██     #
#      ██████    ████   ███████ ██   ██ ██   ██ ██ ██████  ███████ ███████     #
func                        ________OVERRIDES________              ()->void:pass

func _init() -> void:
	_prime = self
	name = PluginName
	settings_mgr = SettingsHelper.new(self, 'flatbuffers')

	# FIXME update editor property docks/filesystem/textfile_extensions to include fbs

	context_menus = {
		EditorContextMenuPlugin.ContextMenuSlot.CONTEXT_SLOT_FILESYSTEM: MyFileMenu.new(),
		EditorContextMenuPlugin.ContextMenuSlot.CONTEXT_SLOT_FILESYSTEM_CREATE:MyFileCreateMenu.new(),
		EditorContextMenuPlugin.ContextMenuSlot.CONTEXT_SLOT_SCRIPT_EDITOR:MyScriptTabMenu.new(),
		EditorContextMenuPlugin.ContextMenuSlot.CONTEXT_SLOT_SCRIPT_EDITOR_CODE:MyCodeEditMenu.new(),
	}
	print_log( LogLevel.TRACE, "%s._init() - Completed" % name )


func _enter_tree() -> void:
	print_log( LogLevel.TRACE, "%s._enter_tree()" % name )
	
	highlighter = SchemaHighlighter.new(self)
	EditorInterface.get_script_editor().register_syntax_highlighter( highlighter )

	# Right Click Context Menu's
	for key in context_menus.keys():
		add_context_menu_plugin( key, context_menus[key] )
		
	# Fix up the text file extensions list.	
	var setting_string:String = "docks/filesystem/textfile_extensions"
	var textfile_extensions:String = editor_settings.get_setting(setting_string)
	var ext_list:Array = textfile_extensions.split(",")
	if not 'fbs' in ext_list:
		ext_list.append('fbs')
		editor_settings.set_setting(setting_string, ','.join(ext_list))


func _exit_tree() -> void:
	print_log( LogLevel.TRACE, "%s._exit_tree()" % name )
	
	# Right Click Context Menu's
	for menu in context_menus.values():
		remove_context_menu_plugin( menu )
	
	EditorInterface.get_script_editor().unregister_syntax_highlighter( highlighter )
	
	# Fix up the text file extensions list.	
	var setting_string:String = "docks/filesystem/textfile_extensions"
	var textfile_extensions:String = editor_settings.get_setting(setting_string)
	var ext_list:Array = textfile_extensions.split(",")
	if 'fbs' in ext_list:
		ext_list.erase('fbs')
		editor_settings.set_setting(setting_string, ','.join(ext_list))


func _get_plugin_name() -> String:
	print_log( LogLevel.TRACE, "%s._get_plugin_name()" % name )
	return plugin_name


func _get_plugin_icon() -> Texture2D:
	print_log( LogLevel.TRACE, "%s._get_plugin_icon()" % name )
	return ICON_BW_TINY


func _enable_plugin() -> void:
	print_log( LogLevel.TRACE, "%s._enable_plugin()" % name )


func _disable_plugin() -> void:
	print_log( LogLevel.TRACE, "%s._disable_plugin()" % name )


#         ███    ███ ███████ ████████ ██   ██  ██████  ██████  ███████         #
#         ████  ████ ██         ██    ██   ██ ██    ██ ██   ██ ██              #
#         ██ ████ ██ █████      ██    ███████ ██    ██ ██   ██ ███████         #
#         ██  ██  ██ ██         ██    ██   ██ ██    ██ ██   ██      ██         #
#         ██      ██ ███████    ██    ██   ██  ██████  ██████  ███████         #
func                        _________METHODS_________              ()->void:pass



#     ███████ ██       █████  ████████  ██████    ███████ ██   ██ ███████      #
#     ██      ██      ██   ██    ██    ██         ██       ██ ██  ██           #
#     █████   ██      ███████    ██    ██         █████     ███   █████        #
#     ██      ██      ██   ██    ██    ██         ██       ██ ██  ██           #
#     ██      ███████ ██   ██    ██     ██████ ██ ███████ ██   ██ ███████      #
func                        ________FLATC_EXE________              ()->void:pass

func flatc_multi( paths:Array, args:Array ) -> Array:
	print_log( LogLevel.TRACE, "%s.flatc_multi(%s, %s)" % [name, paths, args] )
	var results:Array
	for path:String in paths:
		if path.get_extension() == 'fbs':
			results.append( flatc_generate( path, args ) )
	return results


func flatc_generate( schema_path:String, args:Array ) -> Dictionary:
	print_log( LogLevel.TRACE, "%s.flatc_generate(%s, %s)" % [name, schema_path, args] )
	var flatc_exe:String = flatc_opts.flatc_exe
	# Make sure we have the flac compiler
	if not FileAccess.file_exists(flatc_exe):
		var msg = "flatc compiler is not found at '%s'" % flatc_exe
		push_error(msg)
		return {'retcode':ERR_FILE_BAD_PATH, 'output': [msg]}

	if not FileAccess.file_exists(schema_path):
		var msg = "Missing Schema File: '%s'" % schema_path
		push_error(msg)
		return {'retcode':ERR_FILE_BAD_PATH, 'output': [msg] }

	args.append_array(flatc_opts.get_opts())

	# -o <path>
	if not '-o' in args:
		args.append_array([ "-o", schema_path.get_base_dir().replace('res://', './')])

	# Lastly add the schema path
	args.append( schema_path.replace('res://', './') )

	var report:Dictionary = {
		'schema': schema_path,
		'flatc_path':flatc_exe,
		'args':args,
	}

	if opts.debug or opts.editorlog_verbosity >= LogLevel.NOTICE:
		print( JSON.stringify(report, "  ", false) )

	var output:Array = []
	var retcode = OS.execute( flatc_exe, args, output, true )

	report['retcode'] = retcode
	report['output'] = '\n'.join(output).split('\n', false)

	if opts.debug or opts.editorlog_verbosity >= LogLevel.NOTICE:
		print( JSON.stringify({
			'retcode': retcode,
			'output': '\n'.join(output).split('\n', false),
		}, "  ", false) )

	if retcode:
		print_rich('\n'.join(["[color=salmon][b]",
		"ERROR: flatc failed with code '%s'[/b]" % [retcode],
		"\toutput: " + '\n'.join(output) + "[/color]"
		]))

	#TODO Figure out a way to get the script in the editor to reload.
	#  the only reliable way I have found to refresh the script in the editor
	#  is to change the focus away from Godot and back again.

	# This line refreshes the filesystem dock.
	if not retcode: EditorInterface.get_resource_filesystem().scan()
	return report


static func generate( schema_path:String, args:Array ) -> Dictionary:
	return _prime.flatc_import( schema_path, args  )


func flatc_import( schema_path:String, args:Array ) -> Dictionary:
	print_log( LogLevel.TRACE, "%s.flatc_import(%s, %s)" % [name, schema_path, args] )
	var flatc_exe:String = flatc_opts.flatc_exe
	# Make sure we have the flac compiler
	if not FileAccess.file_exists(flatc_exe):
		var msg = "flatc compiler is not found at '%s'" % flatc_exe
		push_error(msg)
		return {'retcode':ERR_FILE_BAD_PATH, 'output': [msg]}

	if not FileAccess.file_exists(schema_path):
		var msg = "Missing Schema File: '%s'" % schema_path
		push_error(msg)
		return {'retcode':ERR_FILE_BAD_PATH, 'output': [msg] }

	# Lastly add the schema path
	args.append( schema_path.replace('res://', './') )

	var report:Dictionary = {
		'schema': schema_path,
		'flatc_path':flatc_exe,
		'args':args,
	}

	if opts.debug or opts.editorlog_verbosity >= LogLevel.NOTICE:
		print( JSON.stringify(report, "  ", false) )

	var output:Array = []
	var retcode = OS.execute( flatc_exe, args, output, true )

	report['retcode'] = retcode
	report['output'] = '\n'.join(output).split('\n', false)

	if opts.debug or opts.editorlog_verbosity >= LogLevel.NOTICE:
		print( JSON.stringify({
			'retcode': retcode,
			'output': '\n'.join(output).split('\n', false),
		}, "  ", false) )

	if retcode:
		print_rich('\n'.join(["[color=salmon][b]",
		"ERROR: flatc failed with code '%x'[/b]" % [retcode],
		"\toutput: " + '\n'.join(output) + "[/color]"
		]))

	#TODO Figure out a way to get the script in the editor to reload.
	#  the only reliable way I have found to refresh the script in the editor
	#  is to change the focus away from Godot and back again.

	# This line refreshes the filesystem dock.
	#if not retcode: EditorInterface.get_resource_filesystem().scan()
	return report


# ██████  ██  ██████  ██   ██ ████████      ██████ ██      ██  ██████ ██   ██  #
# ██   ██ ██ ██       ██   ██    ██        ██      ██      ██ ██      ██  ██   #
# ██████  ██ ██   ███ ███████    ██        ██      ██      ██ ██      █████    #
# ██   ██ ██ ██    ██ ██   ██    ██        ██      ██      ██ ██      ██  ██   #
# ██   ██ ██  ██████  ██   ██    ██         ██████ ███████ ██  ██████ ██   ██  #
func                        _______RIGHT_CLICK_______              ()->void:pass

#  NOTE A plugin instance can belong only to a single context menu slot.

# filesystem context menu
# EditorContextMenuPlugin.ContextMenuSlot.CONTEXT_SLOT_FILESYSTEM
class MyFileMenu extends EditorContextMenuPlugin:
	# _popup_menu() and option callback will be called with list of paths of the
	# currently selected files.
	func _popup_menu(paths):
		var fbp := FlatBuffersPlugin._prime
		for path in paths:
			if path.get_extension() == 'fbs':
				add_context_menu_item("flatc --gdscript", fbp.flatc_multi.bind(['--gdscript']), ICON_BW_TINY  )
				return


# CONTEXT_SLOT_FILESYSTEM_CREATE
# The "Create..." submenu of FileSystem dock's context menu.
class MyFileCreateMenu extends EditorContextMenuPlugin:
	# _popup_menu() and option callback will be called with list of paths of the
	# currently selected files.
	# TODO, use this menu to enable generating a flatbuffer schema by loading
	# and analysing a gdscript class for exported values.
	func _popup_menu(paths):
		var fbp := FlatBuffersPlugin._prime
		if fbp.opts.debug:
			add_context_menu_item("create_flatbuffer_schema_from_object", func(thing): print( thing ), ICON_BW_TINY )

# CONTEXT_SLOT_SCRIPT_EDITOR
# Context menu of Script editor's script tabs.
class MyScriptTabMenu extends EditorContextMenuPlugin:
	# _popup_menu() will be called with the path to the currently edited script,
	# while option callback will receive reference to that script.
	func _popup_menu(paths:PackedStringArray):
		var fbp := FlatBuffersPlugin._prime
		if paths[0].get_extension() == 'fbs':
			add_context_menu_item("flatc --gdscript", call_flatc_on_path.bind(
					paths[0], ['--gdscript'] ), ICON_BW_TINY )
			if fbp.opts.debug:
				add_context_menu_item("flatc --cpp", call_flatc_on_path.bind(
						paths[0], ['--cpp'] ), ICON_BW_TINY )
				add_context_menu_item("flatc --help", call_flatc_on_path.bind(
						paths[0], ['--help'] ), ICON_BW_TINY )
				add_context_menu_item("flatc --version", call_flatc_on_path.bind(
						paths[0], ['--version'] ), ICON_BW_TINY )

	func call_flatc_on_path( _ignore, path:String, args:Array ) -> void:
		var fbp := FlatBuffersPlugin._prime
		fbp.flatc_generate( path, args )


# CONTEXT_SLOT_SCRIPT_EDITOR_CODE
# Context menu of Script editor's code editor.
class MyCodeEditMenu extends EditorContextMenuPlugin:
	# _popup_menu() will be called with the path to the CodeEdit node.
	# The option callback will receive reference to that node.
	func _popup_menu( paths:PackedStringArray ):
		var fbp := FlatBuffersPlugin._prime
		if not fbp.opts.debug: return
		print("paths.size: ", paths.size() )
		print("paths:\n\t", '\n\t'.join(paths) )
		var code_edit:CodeEdit = Engine.get_main_loop().root.get_node(paths[0]);
		print("selected_text: '%s'" % code_edit.get_selected_text() )
		add_context_menu_item("flatbuffers testing", func(thing): print( thing ), ICON_BW_TINY )


#     ██████  ██████  ██ ███    ██ ████████     ██       ██████   ██████       #
#     ██   ██ ██   ██ ██ ████   ██    ██        ██      ██    ██ ██            #
#     ██████  ██████  ██ ██ ██  ██    ██        ██      ██    ██ ██   ███      #
#     ██      ██   ██ ██ ██  ██ ██    ██        ██      ██    ██ ██    ██      #
#     ██      ██   ██ ██ ██   ████    ██        ███████  ██████   ██████       #
func                        ________PRINT_LOG________              ()->void:pass

func print_trace( message:String ):
	if opts.editorlog_verbosity < LogLevel.TRACE: return
	var colour = opts.get_colour(LogLevel.TRACE).to_html()
	print_rich( "[color=%s]%s[/color]" % [colour, message] )


func print_log(level:LogLevel, message:String ) -> bool:
	if opts.editorlog_verbosity < level: return false
	var colour = opts.get_colour(level).to_html()
	var padding = "".lpad(get_stack().size()-1, '\t') if level == LogLevel.TRACE else ""
	print_rich( padding + "[color=%s]%s[/color]" % [colour, message] )
	return true


func log_level( level:LogLevel ) -> bool:
	return opts.editorlog_verbosity >= level
