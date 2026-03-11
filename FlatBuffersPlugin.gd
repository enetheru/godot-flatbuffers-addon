@tool
class_name FlatBuffersPlugin
extends EditorPlugin

func                        _________IMPORTS_________              ()->void:pass

const Print = preload("uid://cbluyr4ifn8g3")
const LogLevel = Print.LogLevel

const SettingsHelper = preload('uid://bqe6tk0yrwq8u')
var settings_mgr:SettingsHelper

# Supporting Scripts
const SchemaHighlighter = preload("uid://ddcfjoxe7i5jo")
const Token = preload("uid://cvcd6kyaa4f1a")

# Supporting Assets
const ICON_BW_TINY = preload("uid://d32jh3dw5nypp")

const author:String = "enetheru"
const PluginName:String = "FlatBuffers"
const plugin_name:String = "flatbuffers"
#const plugin_path:String = "res://addons/" + author + "." + plugin_name + '-addon'
# we can get the plugin path using its resource_path.get_base_dir() anytime.

# Tired of a miss-spelling Maybe using Constants will reduce the off by one errors
# of using dictionaries.
const REPORT_SCHEMA  :StringName = &'schema'
const REPORT_CONFIG  :StringName = &'config'
const REPORT_FLATC   :StringName = &'flatc_path'
const REPORT_ARGS    :StringName = &'args'
const REPORT_STDOUT  :StringName = &'stdout'
const REPORT_RETCODE :StringName = &'retcode'
const REPORT_MSG     :StringName = &'msg'

# ██████  ██████   ██████  ██████  ███████ ██████  ████████ ██ ███████ ███████ #
# ██   ██ ██   ██ ██    ██ ██   ██ ██      ██   ██    ██    ██ ██      ██      #
# ██████  ██████  ██    ██ ██████  █████   ██████     ██    ██ █████   ███████ #
# ██      ██   ██ ██    ██ ██      ██      ██   ██    ██    ██ ██           ██ #
# ██      ██   ██  ██████  ██      ███████ ██   ██    ██    ██ ███████ ███████ #
func                        ________PROPERTIES_______              ()->void:pass

# Reference to self so we can do things since we are already instantiated.
static var _prime:FlatBuffersPlugin
static var plugin_dir:String
static var plugin_path:String

var opts:FlatBuffersOpts

var highlighter:SchemaHighlighter

var context_menus:Dictionary[EditorContextMenuPlugin.ContextMenuSlot,EditorContextMenuPlugin]


#             ███████ ██    ██ ███████ ███    ██ ████████ ███████              #
#             ██      ██    ██ ██      ████   ██    ██    ██                   #
#             █████   ██    ██ █████   ██ ██  ██    ██    ███████              #
#             ██       ██  ██  ██      ██  ██ ██    ██         ██              #
#             ███████   ████   ███████ ██   ████    ██    ███████              #
func                        __________EVENTS_________              ()->void:pass

func _on_project_settings_changed(
			setting_name:String, setting_value:Variant ) -> void:
	Print.plog(LogLevel.TRACE, ''.join([setting_name, ':', setting_value]))
	match setting_name:
		"experimental" when setting_value == true: enable_experimental_features()
		"experimental": disable_experimental_features()


#      ██████  ██    ██ ███████ ██████  ██████  ██ ██████  ███████ ███████     #
#     ██    ██ ██    ██ ██      ██   ██ ██   ██ ██ ██   ██ ██      ██          #
#     ██    ██ ██    ██ █████   ██████  ██████  ██ ██   ██ █████   ███████     #
#     ██    ██  ██  ██  ██      ██   ██ ██   ██ ██ ██   ██ ██           ██     #
#      ██████    ████   ███████ ██   ██ ██   ██ ██ ██████  ███████ ███████     #
func                        ________OVERRIDES________              ()->void:pass

func _init() -> void:
	_prime = self
	name = PluginName
	plugin_path = get_script().resource_path
	plugin_dir = plugin_path.get_base_dir()

	opts = FlatBuffersOpts.new()
	settings_mgr = SettingsHelper.new(opts, plugin_name)

	@warning_ignore("return_value_discarded")
	settings_mgr.settings_changed.connect(_on_project_settings_changed)

	Print.plog( LogLevel.DEBUG, "%s._init() - Completed" % name )


func _enter_tree() -> void:
	Print.plog( LogLevel.TRACE, "%s._enter_tree()" % name )

	highlighter = SchemaHighlighter.new(self)
	EditorInterface.get_script_editor().register_syntax_highlighter( highlighter )

	## FileSystem Dock Context Menu
	var cm_slot := EditorContextMenuPlugin.ContextMenuSlot.CONTEXT_SLOT_FILESYSTEM
	var cm_plugin:EditorContextMenuPlugin = FSDockCM.new()
	add_context_menu_plugin( cm_slot, cm_plugin )
	context_menus[cm_slot] = cm_plugin

	# Fix up the text file extensions list.
	var editor_settings := EditorInterface.get_editor_settings()
	var setting_string:String = "docks/filesystem/textfile_extensions"
	var textfile_extensions:String = editor_settings.get_setting(setting_string)
	var ext_list:Array = textfile_extensions.split(",")
	if not 'fbs' in ext_list:
		Print.plog( LogLevel.TRACE, "Adding fbs to EditorSetting: docks/filesystem/textfile_extensions" )
		ext_list.append('fbs')
		editor_settings.set_setting(setting_string, ','.join(ext_list))
		# Force filesystem scan to refresh the dock
		EditorInterface.get_resource_filesystem().scan()
		Print.plog( LogLevel.NOTICE, ' '.join(["[b]FlatBuffersAddon.Note[/b]:",
			"the 'fbs' extension has been added to EditorSettings:",
			"`docks/filesystem/textfile_extensions`",
			"I have noticed that while the",
			"fbs files do show up after this change, editing them brings up a",
			"resource error rather than opening the editor. The only way I've",
			"Found so far to resolve this is to manually change the EditorSetting",
			"to trigger the editor to perform whatever it needs."]) )

	if opts.experimental:
		enable_experimental_features()


func _exit_tree() -> void:
	Print.plog( LogLevel.TRACE, "%s._exit_tree()" % name )

	if opts.experimental:
		disable_experimental_features()

	# Right Click Context Menu's
	for menu:EditorContextMenuPlugin in context_menus.values():
		remove_context_menu_plugin( menu )

	EditorInterface.get_script_editor().unregister_syntax_highlighter( highlighter )

	# Fix up the text file extensions list.
	var editor_settings := EditorInterface.get_editor_settings()
	var setting_string:String = "docks/filesystem/textfile_extensions"
	var textfile_extensions:String = editor_settings.get_setting(setting_string)
	var ext_list:Array = textfile_extensions.split(",")
	if 'fbs' in ext_list:
		Print.plog( LogLevel.TRACE, "Removing fbs from EditorSetting: docks/filesystem/textfile_extensions" )
		ext_list.erase('fbs')
		editor_settings.set_setting(setting_string, ','.join(ext_list))
		# Force filesystem scan to refresh the dock
		EditorInterface.get_resource_filesystem().scan()


func _get_plugin_name() -> String:
	Print.plog( LogLevel.TRACE, "%s._get_plugin_name()" % name )
	return plugin_name


func _get_plugin_icon() -> Texture2D:
	Print.plog( LogLevel.TRACE, "%s._get_plugin_icon()" % name )
	return ICON_BW_TINY


func _enable_plugin() -> void:
	Print.plog( LogLevel.TRACE, "%s._enable_plugin()" % name )


func _disable_plugin() -> void:
	Print.plog( LogLevel.TRACE, "%s._disable_plugin()" % name )


#         ███    ███ ███████ ████████ ██   ██  ██████  ██████  ███████         #
#         ████  ████ ██         ██    ██   ██ ██    ██ ██   ██ ██              #
#         ██ ████ ██ █████      ██    ███████ ██    ██ ██   ██ ███████         #
#         ██  ██  ██ ██         ██    ██   ██ ██    ██ ██   ██      ██         #
#         ██      ██ ███████    ██    ██   ██  ██████  ██████  ███████         #
func                        _________METHODS_________              ()->void:pass

func enable_experimental_features() -> void:
	Print.plog( LogLevel.DEBUG, "enable_experimental_features" )

	## FileSystem Dock Create Menu and Main Context Menu when empty space is clicked?
	var cm_slot := EditorContextMenuPlugin.ContextMenuSlot.CONTEXT_SLOT_FILESYSTEM_CREATE
	var cm_plugin:EditorContextMenuPlugin = FSCreateCM.new()
	add_context_menu_plugin( cm_slot, cm_plugin )
	context_menus[cm_slot] = cm_plugin

	## ScriptEditor script tabs
	cm_slot = EditorContextMenuPlugin.ContextMenuSlot.CONTEXT_SLOT_SCRIPT_EDITOR
	cm_plugin = ScriptEditTabCM.new()
	add_context_menu_plugin( cm_slot, cm_plugin )
	context_menus[cm_slot] = cm_plugin


func disable_experimental_features() -> void:
	Print.plog( LogLevel.DEBUG, "disable_experimental_features" )

	# Right Click Context Menu's
	for cm_slot:EditorContextMenuPlugin.ContextMenuSlot in [
		EditorContextMenuPlugin.ContextMenuSlot.CONTEXT_SLOT_FILESYSTEM_CREATE,
		EditorContextMenuPlugin.ContextMenuSlot.CONTEXT_SLOT_SCRIPT_EDITOR]:
			var cm_plugin:EditorContextMenuPlugin = context_menus.get(cm_slot)
			if not context_menus.erase(cm_slot): continue
			if is_instance_valid(cm_plugin):
				remove_context_menu_plugin( cm_plugin )


#     ███████ ██       █████  ████████  ██████    ███████ ██   ██ ███████      #
#     ██      ██      ██   ██    ██    ██         ██       ██ ██  ██           #
#     █████   ██      ███████    ██    ██         █████     ███   █████        #
#     ██      ██      ██   ██    ██    ██         ██       ██ ██  ██           #
#     ██      ███████ ██   ██    ██     ██████ ██ ███████ ██   ██ ███████      #
func                        ________FLATC_EXE________              ()->void:pass

func flatc_multi( paths:Array, config:FlatBuffersGeneratorOpts ) -> Array:
	Print.plog( LogLevel.TRACE, "%s.flatc_multi(%s, %s)" % [name, paths, config.name] )
	var results:Array
	for path:String in paths:
		if path.get_extension() == 'fbs':
			results.append( await flatc_generate( path, config ) )
	return results


func flatc_generate( schema_path:String, config:FlatBuffersGeneratorOpts ) -> Dictionary:
	Print.plog( LogLevel.TRACE, "%s.flatc_generate(%s, %s)" % [name, schema_path, config.name] )
	var report:Dictionary = {
		REPORT_SCHEMA  : schema_path,
		REPORT_CONFIG  : config.name,
		REPORT_FLATC   : config.flatc_exe,
		REPORT_ARGS    : '',
		REPORT_STDOUT  : '',
		REPORT_RETCODE : 0,
		REPORT_MSG     : ''
	}

	# Make sure we have the flac compiler
	var flatc_exe:String = config.flatc_exe
	if not FileAccess.file_exists(flatc_exe):
		report[REPORT_MSG] = "flatc compiler is not found at '%s'" % flatc_exe
		report[REPORT_RETCODE] = ERR_FILE_BAD_PATH
		printerr(Print.get_call_site(), ":\n\t| ", report[REPORT_MSG])
		return report

	# Make sure we have the schema file
	if not FileAccess.file_exists(schema_path):
		report[REPORT_MSG] = "Missing Schema File: '%s'" % schema_path
		report[REPORT_RETCODE] = ERR_FILE_BAD_PATH
		printerr(Print.get_call_site(), ":\n\t| ", report[REPORT_MSG])
		return report

	# Get the set of options from the config
	var args:Array = config.get_opts()

	# if -o is un-specified the generated file will be placed at res:// which
	# is the current working directory when executing flatc with OS.execute.
	# so we specify it if its missing, so the files are generated next to the
	# schema.
	if not '-o' in args:
		args.append_array(['-o', schema_path.get_base_dir().replace('res://', './')])

	# Lastly add the schema file path
	args.append( schema_path.replace('res://', './') )

	Print.plog(LogLevel.DEBUG,
		report[REPORT_FLATC] + '\n',
		'\t'+ ' '.join(args) + '\n',
		'\t'+ report[REPORT_SCHEMA])

	var stdout:Array = []
	var retcode:int = OS.execute( flatc_exe, args, stdout, true )
	report[REPORT_RETCODE] = retcode

	# process output
	var output:Array
	for chunk:String in stdout:
		output.append_array(chunk.split('\r\n', false))

	report[REPORT_STDOUT] = '\n'.join(output)

	Print.plog(LogLevel.ERROR if retcode else LogLevel.DEBUG,
		"retcode: '", report[REPORT_RETCODE],"'\n",
		"output : '", report[REPORT_STDOUT], "'")

	Print.plog(LogLevel.NOTICE, "[b]FlatBuffersPlugin.Note[/b]: scripts",
		"that are being regenerated will not update in the editor until the",
		"window focus has changed. I have no idea why, or how to fix it, so",
		"change to another window away from Godot, and back again to",
		"refresh the scripts in the editor")

	if retcode: return report

	# TODO Maybe I can put this behind a generator options. Makes me think I
	# I should separate out the checking from the actions.
	# This line refreshes the filesystem dock.
	var efs:EditorFileSystem = EditorInterface.get_resource_filesystem()
	efs.scan()
	efs.scan_sources()
	if efs.is_scanning():
		await efs.filesystem_changed

	#efs.reimport_files() # TODO add the generated filename to this command to
	# see if it fixes the regeneration issue.

	return report


## Generate calls the flatc executable to generate the GDScript code for the
## serialiser. it returns a [Dictionary].
## [codeblock]{
##		'flatc_path':"C:/.../flatc.exe",
##		'args':["--gdscript", ...],
##		'schema': "schema_path.fbs",
##		'retcode': 0 # (int)
##		'output': [""] # stdout + stderr
## }[/codeblock]
static func generate(
			schema_path:String,
			config:FlatBuffersGeneratorOpts = load("uid://b8vn3e2cuhqy3")
			) -> Dictionary:
	return await _prime.flatc_generate( schema_path, config  )


# ██████  ██  ██████  ██   ██ ████████      ██████ ██      ██  ██████ ██   ██  #
# ██   ██ ██ ██       ██   ██    ██        ██      ██      ██ ██      ██  ██   #
# ██████  ██ ██   ███ ███████    ██        ██      ██      ██ ██      █████    #
# ██   ██ ██ ██    ██ ██   ██    ██        ██      ██      ██ ██      ██  ██   #
# ██   ██ ██  ██████  ██   ██    ██         ██████ ███████ ██  ██████ ██   ██  #
func                        _______RIGHT_CLICK_______              ()->void:pass

#  NOTE A plugin instance can belong only to a single context menu slot.

static func is_fbs_in_path_list(path_list:PackedStringArray) -> bool:
	for path:String in path_list:
			if path.get_extension() == 'fbs':
				return true
	return false


## FileSystem Dock Context Menu.
## EditorContextMenuPlugin.ContextMenuSlot.CONTEXT_SLOT_FILESYSTEM
class FSDockCM extends EditorContextMenuPlugin:

	func _init() -> void:
		Print.plog( LogLevel.TRACE, "FSDockCM._init()" )

	# _popup_menu() and option callback will be called with list of paths of the
	# currently selected files.
	func _popup_menu(paths:PackedStringArray) -> void:
		# Verify we have a fbs to call the menu on.
		if not FlatBuffersPlugin.is_fbs_in_path_list(paths): return

		# Get the list of flatc configs

		var fbp := FlatBuffersPlugin._prime
		var config_list:Array[FlatBuffersGeneratorOpts] = fbp.opts.config_list
		var from_settings:Variant = ProjectSettings.get_setting('flatbuffers/GeneratorConfigs/config_list')
		if from_settings: config_list = from_settings
		if config_list.is_empty(): config_list.append(load("uid://b8vn3e2cuhqy3"))

		for config in config_list:
			var item_name:String = "FlatBuffers Generate: %s" % [config.name]
			add_context_menu_item(item_name, fbp.flatc_multi.bind(config), ICON_BW_TINY  )
		# TODO when configs grow past three, add a submenu.



## The "Create..." submenu of FileSystem dock's context menu.
## CONTEXT_SLOT_FILESYSTEM_CREATE
class FSCreateCM extends EditorContextMenuPlugin:

	func _init() -> void:
		Print.plog( LogLevel.TRACE, "FSCreateCM._init()" )

	# _popup_menu() and option callback will be called with list of paths of the
	# currently selected files.
	# TODO, use this menu to enable generating a flatbuffer schema by loading
	# and analysing a gdscript class for exported values.
	func _popup_menu(_paths:PackedStringArray) -> void:
		var fbp := FlatBuffersPlugin._prime
		if fbp.opts.experimental:
			add_context_menu_item("create_flatbuffer_schema_from_object",
				func(thing:Array) -> void: print( thing ),
				ICON_BW_TINY )



## Context menu of Script editor's script tabs.
## CONTEXT_SLOT_SCRIPT_EDITOR
class ScriptEditTabCM extends EditorContextMenuPlugin:

	func _init() -> void:
		Print.plog( LogLevel.TRACE, "ScriptEditTabCM._init()" )

	# _popup_menu() will be called with the path to the currently edited script,
	# while option callback will receive reference to that script.
	func _popup_menu(paths:PackedStringArray) -> void:
		# Verify we have a fbs to call the menu on.
		if not FlatBuffersPlugin.is_fbs_in_path_list(paths): return

		var _fbp := FlatBuffersPlugin._prime
		#if paths[0].get_extension() == 'fbs':
			#add_context_menu_item("flatc --gdscript", call_flatc_on_path.bind(
					#paths[0], ['--gdscript'] ), ICON_BW_TINY )
			#if fbp.opts.debug:
				#add_context_menu_item("flatc --cpp", call_flatc_on_path.bind(
						#paths[0], ['--cpp'] ), ICON_BW_TINY )
				#add_context_menu_item("flatc --help", call_flatc_on_path.bind(
						#paths[0], ['--help'] ), ICON_BW_TINY )
				#add_context_menu_item("flatc --version", call_flatc_on_path.bind(
						#paths[0], ['--version'] ), ICON_BW_TINY )

	#func call_flatc_on_path( _ignore, path:String, args:Array ) -> void:
		#var fbp := FlatBuffersPlugin._prime
		#fbp.flatc_generate( path, args )
