@tool
class_name FlatBuffersPlugin
extends EditorPlugin

const Log = preload("uid://biv0hwe68jj3s")

const SettingsHelper = preload('uid://bqe6tk0yrwq8u')
var settings_mgr:SettingsHelper

# Supporting Scripts
const SchemaHighlighter = preload("uid://ddcfjoxe7i5jo")
const Token = preload("uid://cvcd6kyaa4f1a")

# Supporting Assets
const ICON_BW_TINY = preload("uid://d32jh3dw5nypp")

const ExportPlugin = preload("export_plugin.gd")

const author:String = "enetheru"
const PluginName:String = "FlatBuffers"
const plugin_name:String = "flatbuffers"
const CS_OWNER:String = "enetheru.flatbuffers-addon"
# plugin_path is derived from get_script().resource_path at runtime — never hard-code.
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

var _cs_plugin:EditorPlugin
var _cs_reloaded_cb:Callable = Callable()
var export_plugin:EditorExportPlugin


#             ███████ ██    ██ ███████ ███    ██ ████████ ███████              #
#             ██      ██    ██ ██      ████   ██    ██    ██                   #
#             █████   ██    ██ █████   ██ ██  ██    ██    ███████              #
#             ██       ██  ██  ██      ██  ██ ██    ██         ██              #
#             ███████   ████   ███████ ██   ████    ██    ███████              #

## Use [param verbosity] as the logger ceiling. It is an inclusive [enum Log.Level].
func _apply_log_verbosity( verbosity:int ) -> void:
	Log._session().default_lvl = verbosity


func                        __________EVENTS_________              ()->void:pass

func _on_project_settings_changed( setting_name:String, setting_value:Variant ) -> void:
	Log.trace({setting_name: setting_value}, self)
	if setting_name == "editorlog_verbosity" and setting_value is int:
		var verbosity:int = setting_value
		_apply_log_verbosity( verbosity )
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

	_apply_log_verbosity( opts.editorlog_verbosity )

	Log.lvl( Log.Level.DEBUG, "%s._init() - Completed" % name)


func _enter_tree() -> void:
	Log.trace( {}, self )

	highlighter = SchemaHighlighter.new(self)
	EditorInterface.get_script_editor().register_syntax_highlighter( highlighter )

	## FileSystem Dock Context Menu
	var cm_slot := EditorContextMenuPlugin.ContextMenuSlot.CONTEXT_SLOT_FILESYSTEM
	var cm_plugin:EditorContextMenuPlugin = FSDockCM.new()
	add_context_menu_plugin( cm_slot, cm_plugin )
	context_menus[cm_slot] = cm_plugin

	# Read EditorSettings. Leave the values alone. A write here hangs editor
	# open. The lock order is Notes/EditorSettings.md in the extension repo.
	# Add fbs by hand under docks/filesystem/textfile_extensions.

	if opts.experimental:
		enable_experimental_features()

	export_plugin = ExportPlugin.new()
	add_export_plugin(export_plugin)

	_schedule_command_server_register()


func _exit_tree() -> void:
	Log.trace( {}, self )
	var efs:EditorFileSystem = EditorInterface.get_resource_filesystem()
	var register_cb:Callable = _register_with_command_server
	if efs.filesystem_changed.is_connected( register_cb ):
		efs.filesystem_changed.disconnect( register_cb )
	if export_plugin:
		remove_export_plugin(export_plugin)
		export_plugin = null
	_unregister_from_command_server()

	if opts.experimental:
		disable_experimental_features()

	# Right Click Context Menu's
	for menu:EditorContextMenuPlugin in context_menus.values():
		remove_context_menu_plugin( menu )

	EditorInterface.get_script_editor().unregister_syntax_highlighter( highlighter )


func _get_plugin_name() -> String:
	Log.trace( {}, self )
	return plugin_name


func _get_plugin_icon() -> Texture2D:
	Log.trace( {}, self )
	return ICON_BW_TINY


func _enable_plugin() -> void:
	Log.trace( {}, self )


func _disable_plugin() -> void:
	Log.trace( {}, self )


#         ███    ███ ███████ ████████ ██   ██  ██████  ██████  ███████         #
#         ████  ████ ██         ██    ██   ██ ██    ██ ██   ██ ██              #
#         ██ ████ ██ █████      ██    ███████ ██    ██ ██   ██ ███████         #
#         ██  ██  ██ ██         ██    ██   ██ ██    ██ ██   ██      ██         #
#         ██      ██ ███████    ██    ██   ██  ██████  ██████  ███████         #
func                        _________METHODS_________              ()->void:pass

# The first scan clears ResourceUID, then rebuilds it. Command scripts preload
# by uid, so a reload in that window cannot resolve them.
func _schedule_command_server_register() -> void:
	var efs:EditorFileSystem = EditorInterface.get_resource_filesystem()
	if efs.is_scanning():
		var register_cb:Callable = _register_with_command_server
		if not efs.filesystem_changed.is_connected( register_cb ):
			var err:Error = efs.filesystem_changed.connect( register_cb, CONNECT_ONE_SHOT )
			if err != OK:
				Log.lvl( Log.Level.NOTICE, "FlatBuffers: connect filesystem_changed failed: %d" % err )
		return
	_register_with_command_server.call_deferred()


func _register_with_command_server() -> void:
	if not is_inside_tree():
		return
	var efs:EditorFileSystem = EditorInterface.get_resource_filesystem()
	if efs.is_scanning():
		_schedule_command_server_register()
		return
	_unregister_from_command_server()
	var cs:EditorPlugin = _find_command_server()
	if not is_instance_valid( cs ):
		Log.lvl( Log.Level.NOTICE, "FlatBuffers: Command Server not found; FBS_DIAGNOSE is not registered")
		return
	if not cs.has_method( &"register_commands_from_path" ):
		Log.lvl( Log.Level.NOTICE, "FlatBuffers: Command Server missing register_commands_from_path")
		return

	var plugin_script:GDScript = get_script()
	var cmd_dir:String = plugin_script.resource_path.get_base_dir().path_join( "command_server" )
	var added:int = cs.call( &"register_commands_from_path", cmd_dir, CS_OWNER )
	_cs_plugin = cs
	if cs.has_signal( &"commands_reloaded" ):
		_cs_reloaded_cb = _on_command_server_reloaded
		if not cs.is_connected( &"commands_reloaded", _cs_reloaded_cb ):
			var err:Error = cs.connect( &"commands_reloaded", _cs_reloaded_cb )
			if err != OK:
				Log.lvl( Log.Level.NOTICE, "FlatBuffers: connect commands_reloaded failed: %d" % err)
	Log.lvl( Log.Level.DEBUG, "FlatBuffers: registered %d command(s) with Command Server" % added)


func _on_command_server_reloaded() -> void:
	_schedule_command_server_register()


func _unregister_from_command_server() -> void:
	if is_instance_valid( _cs_plugin ):
		if _cs_reloaded_cb.is_valid() \
				and _cs_plugin.is_connected( &"commands_reloaded", _cs_reloaded_cb ):
			_cs_plugin.disconnect( &"commands_reloaded", _cs_reloaded_cb )
		if _cs_plugin.has_method( &"unregister_owner" ):
			_cs_plugin.call( &"unregister_owner", CS_OWNER )
	_cs_plugin = null
	_cs_reloaded_cb = Callable()


func _find_command_server() -> EditorPlugin:
	var helper:Script = load(
			"res://addons/enetheru.command-server/command_server.gd"
	) as Script
	if is_instance_valid( helper ) \
			and helper.has_method( &"get_command_server_plugin" ):
		var found:Variant = helper.call( &"get_command_server_plugin" )
		if found is EditorPlugin:
			return found
	var base:Control = EditorInterface.get_base_control()
	if not is_instance_valid( base ):
		return null
	return _find_cs_in_tree( base.get_tree().root )


func _find_cs_in_tree( n:Node ) -> EditorPlugin:
	if not is_instance_valid( n ):
		return null
	if n is EditorPlugin:
		var plugin:EditorPlugin = n
		var scr:Script = plugin.get_script()
		if is_instance_valid( scr ):
			var path:String = scr.resource_path
			if path.ends_with( "command_server.gd" ) \
					or path.contains( "enetheru.command-server/command_server.gd" ):
				return plugin
	for child:Node in n.get_children():
		var found:EditorPlugin = _find_cs_in_tree( child )
		if is_instance_valid( found ):
			return found
	return null


func enable_experimental_features() -> void:
	Log.trace( {}, self )

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
	Log.trace( {}, self )

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
	Log.trace({&'paths': paths, &'config': config}, self)
	var results:Array
	for path:String in paths:
		if path.get_extension() == 'fbs':
			results.append( await flatc_generate( path, config ) )
	return results


func flatc_generate( schema_path:String, config:FlatBuffersGeneratorOpts ) -> Dictionary:
	Log.trace({&'schema_path': schema_path, &'config': config}, self)
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
		Log.err( report[REPORT_MSG])
		return report

	# Make sure we have the schema file
	if not FileAccess.file_exists(schema_path):
		report[REPORT_MSG] = "Missing Schema File: '%s'" % schema_path
		report[REPORT_RETCODE] = ERR_FILE_BAD_PATH
		Log.err( report[REPORT_MSG])
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

	Log.lvl( Log.Level.DEBUG, [report[REPORT_FLATC] + '\n', '\t'+ ' '.join(args) + '\n', '\t'+ report[REPORT_SCHEMA]])

	var stdout:Array = []
	var retcode:int = OS.execute( flatc_exe, args, stdout, true )
	report[REPORT_RETCODE] = retcode

	# process output
	var output:Array
	for chunk:String in stdout:
		output.append_array(chunk.split('\r\n', false))

	report[REPORT_STDOUT] = '\n'.join(output)

	Log.lvl( Log.Level.ERROR if retcode else Log.Level.DEBUG, ["retcode: '", report[REPORT_RETCODE], "'\n", "output : '", report[REPORT_STDOUT], "'"])

	Log.lvl( Log.Level.NOTICE, ["[b]FlatBuffersPlugin.Note[/b]: scripts", "that are being regenerated will not update in the editor until the", "window focus has changed. I have no idea why, or how to fix it, so", "change to another window away from Godot, and back again to", "refresh the scripts in the editor"])

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
		Log.trace( {}, self )

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
		Log.trace( {}, self )

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
		Log.trace( {}, self )

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
