@tool

## │ ___      _   _   _                _  _     _                  [br]
## │/ __| ___| |_| |_(_)_ _  __ _ ___ | || |___| |_ __  ___ _ _    [br]
## │\__ \/ -_)  _|  _| | ' \/ _` (_-< | __ / -_) | '_ \/ -_) '_|   [br]
## │|___/\___|\__|\__|_|_||_\__, /__/ |_||_\___|_| .__/\___|_|     [br]
## ╰────────────────────────|___/────────────────|_|────────────── [br]
## This class saves me from writing so much boilerplate for creating editor
## settings for the editor plugins I wish to write.
##
## The class looks for custom exported properties with
## [code]PROPERTY_USAGE_EDITOR_BASIC_SETTING[/code] and exposes them as
## editor_settings.[br]
## [br]
## It is intended to be used in [EditorPlugin] singletons to transform exported
## properties into editor settings.[br]
## [br]
## [b]== Usage ==[/b][br]
## drop it into your plugin's folder and initialise it like so:
## [codeblock]
## func _enter_tree() -> void:
##     settings_mgr = SettingsHelper.new(self, "plugin/my_plugin_name")
## [/codeblock]
## [br]
## [b]== Examples ==[/b][br]
## [codeblock]
## @export_custom( PROPERTY_HINT_NONE, "", PROPERTY_USAGE_EDITOR_BASIC_SETTING)
## var example:bool
## [/codeblock]
## [br]
## To facilitate grouping of settings, add the [code]PROPERTY_USAGE_GROUP[/code]
## and [code]PROPERTY_USAGE_SUBGROUP[/code] bitflags to the export.[br]
## Underscores will be replaced with forward slashes.[br]
## Only two layers deep are supported.
## [codeblock]
## @export_custom( PROPERTY_HINT_NONE, "",
##	PROPERTY_USAGE_EDITOR_BASIC_SETTING | PROPERTY_USAGE_SUBGROUP)
## var group_subgroup_example:bool
## [/codeblock]
## [br]
## Not all property hints work, as there is not a 1:1 relationship between the
## editor settings and the inspector.[br]
## [br]
## [b]== More ==[/b][br]
## The goal of this script is to provided a friendly way to define editor or project properties based on an object.
## Is used primarily for singletons like editor plugins, but if i finish it, it can be extended to project singletons too.
## Rather than manually setting them up one by one, it also provides a mechanism such that selecting the node shows the properties.
## [br]
## The idea is that we walk the property list of an object, and translate its properties into editor settings.
## [br]
## Object Property Dictionary.[br]
## Returns the object's property list as an Array of dictionaries. Each [Dictionary] contains the following entries:[br]
## - name is the property's name, as a [String];[br]
## - class_name is an empty [StringName], unless the property is [enum Variant.Type].[code]TYPE_OBJECT[/code] and it inherits from a class;[br]
## - type is the property's type, as an int (see [enum Variant.Type]);[br]
## - hint is how the property is meant to be edited (see [enum PropertyHint]);[br]
## - hint_string depends on the hint (see [enum PropertyHint]);[br]
## - usage is a combination of [enum PropertyUsageFlags].[br]
## [b]Note:[/b] In GDScript, all class members are treated as properties.
## In C# and GDExtension, it may be necessary to explicitly mark class members
## as Godot properties using decorators or attributes.
## [br]
## EditorSettings property.[br]
## [codeblock]
## settings.set("category/property_name", 0)
## var property_info = {
##	# - "name": "category/property_name",
##	# - "type": TYPE_INT,
##	# - "hint": PROPERTY_HINT_ENUM,
##	# - "hint_string": "one,two,three"
## }
## settings.add_property_info(property_info)
## [/codeblock]
## [br]
## 11/11/2025 10:41am ACT+930 - I guess Created[br]
## [br]
## 09/02/2026 12:58am ACT+930 - re-added the signal for when a
## setting changes and updated documentation[br]
## 24/02/2026 2:45am ACT+930 - added consts for property usage, clarification
## for the abuse of PROPERTY_USAGE flags, and the link below which might come
## in handy[br]
## removed the erase on exit, seemed buggy and prone to wipe my editor-settings
## entirely[br]
## Compared this script to the similar one from editor-tweaks, and merged some
## differences, button code, enabled_plugins,

## Link for adding documentation tooltips to settings.
## very brute force.
## https://github.com/PiCode9560/Godot-Editor-Settings-Description/blob/main/editor_settings_description.gd

const SETTING_BASIC = (PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_EDITOR_BASIC_SETTING)
const SETTING_BASIC_SUB = (SETTING_BASIC | PROPERTY_USAGE_GROUP)
const SETTING_BASIC_SUB2 = (SETTING_BASIC | PROPERTY_USAGE_SUBGROUP)


# ██████  ██████   ██████  ██████  ███████ ██████  ████████ ██ ███████ ███████ #
# ██   ██ ██   ██ ██    ██ ██   ██ ██      ██   ██    ██    ██ ██      ██      #
# ██████  ██████  ██    ██ ██████  █████   ██████     ██    ██ █████   ███████ #
# ██      ██   ██ ██    ██ ██      ██      ██   ██    ██    ██ ██           ██ #
# ██      ██   ██  ██████  ██      ███████ ██   ██    ██    ██ ███████ ███████ #
func                        ________PROPERTIES_______              ()->void:pass

static var editor_settings:EditorSettings :
	get(): return EditorInterface.get_editor_settings()

var _prefix:String
var _target:EditorPlugin

var helper_group:StringName = &"settings-helper"

signal settings_changed( setting_name:StringName, value:Variant )

#             ███████ ██    ██ ███████ ███    ██ ████████ ███████              #
#             ██      ██    ██ ██      ████   ██    ██    ██                   #
#             █████   ██    ██ █████   ██ ██  ██    ██    ███████              #
#             ██       ██  ██  ██      ██  ██ ██    ██         ██              #
#             ███████   ████   ███████ ██   ████    ██    ███████              #
func                        __________EVENTS_________              ()->void:pass

func _on_editor_settings_changed() -> void:
	for setting_name in editor_settings.get_changed_settings():
		if not setting_name.begins_with(_prefix): continue
		if setting_name.begins_with(_prefix.path_join(&"built-in")): continue
		var prop_val:Variant = editor_settings.get(setting_name)
		var prop_name:StringName = setting_name.trim_prefix(_prefix+ "/").replace('/', '_')
		# try to set the target object property value.
		if prop_name in _target.get_property_list().reduce(
			func( prop_names:Array, prop_dict:Dictionary ) -> Array:
				prop_names.append(prop_dict.name); return prop_names, [] ):
					_target.set( prop_name, prop_val )
		else:
			printerr("property(%s) invalid for target(%s)" % [
				prop_name, _target.name])
		settings_changed.emit( prop_name, prop_val )


func _on_target_tree_exiting() -> void:
	editor_settings.settings_changed.disconnect( _on_editor_settings_changed )


func _on_rebuild_pressed() -> void:
	print( "Rebuilding Settings in '%s'" % _prefix )
	erase_prefix( _prefix )
	add_target_properties()
	#add_helper_properties()


func _on_erase_pressed() -> void:
	print( "Erasing Settings in '%s'" % _prefix )
	erase_prefix( _prefix )


func _on_unload_pressed() -> void:
	print("TODO implement plugin unload button.")


#      ██████  ██    ██ ███████ ██████  ██████  ██ ██████  ███████ ███████     #
#     ██    ██ ██    ██ ██      ██   ██ ██   ██ ██ ██   ██ ██      ██          #
#     ██    ██ ██    ██ █████   ██████  ██████  ██ ██   ██ █████   ███████     #
#     ██    ██  ██  ██  ██      ██   ██ ██   ██ ██ ██   ██ ██           ██     #
#      ██████    ████   ███████ ██   ██ ██   ██ ██ ██████  ███████ ███████     #
func                        ________OVERRIDES________              ()->void:pass

func _init( target:EditorPlugin, prefix:String = "plugin/un-named" )-> void:
	_prefix = prefix
	_target = target

	@warning_ignore_start('return_value_discarded')
	_target.tree_exiting.connect( _on_target_tree_exiting, CONNECT_ONE_SHOT )
	editor_settings.settings_changed.connect( _on_editor_settings_changed )
	@warning_ignore_restore('return_value_discarded')

	add_target_properties()
	#add_helper_properties()


#         ███    ███ ███████ ████████ ██   ██  ██████  ██████  ███████         #
#         ████  ████ ██         ██    ██   ██ ██    ██ ██   ██ ██              #
#         ██ ████ ██ █████      ██    ███████ ██    ██ ██   ██ ███████         #
#         ██  ██  ██ ██         ██    ██   ██ ██    ██ ██   ██      ██         #
#         ██      ██ ███████    ██    ██   ██  ██████  ██████  ███████         #
func                        _________METHODS_________              ()->void:pass

## Scan addons folder for plugins [br]
## Each dict:
## [codeblock]{
##   "path"[/code]:   "res://addons/my_plugin/",
##   "config"[/code]: {"name": "...", "script": "...", ...}
## }[/codeblock]
func get_all_plugins_info( only_loaded:bool = false) -> Array[Dictionary]:
	var enabled_plugins:PackedStringArray = ProjectSettings.get_setting("editor_plugins/enabled")
	var plugins_info: Array[Dictionary] = []

	# Open the addons directory
	var addons_path:String = "res://addons/"
	var dir: DirAccess = DirAccess.open(addons_path)
	if dir == null:
		push_error("Failed to open res://addons/ directory")
		return plugins_info

	# Get list of subdirectories (plugin folders)
	dir.list_dir_begin()
	var folder_name: String = dir.get_next()
	while folder_name != "":
		if dir.current_is_dir():
			var plugin_path: String = addons_path.path_join(folder_name)
			var cfg_path: String = plugin_path.path_join("plugin.cfg")

			if only_loaded and cfg_path not in enabled_plugins:
				folder_name = dir.get_next()
				continue

			if FileAccess.file_exists(cfg_path):
				var config: ConfigFile = ConfigFile.new()
				var err: int = config.load(cfg_path)
				if err == OK:
					var config_props: Dictionary = {}

					var keys: PackedStringArray = config.get_section_keys("plugin")
					for key in keys:
						config_props[key] = config.get_value("plugin", key)

					plugins_info.append({
						"path": plugin_path,
						"config": config_props,
						"enabled": plugin_path in enabled_plugins
					})
				else:
					push_warning("Failed to load " + cfg_path + " (error: " + str(err) + ")")

		folder_name = dir.get_next()
	dir.list_dir_end()
	return plugins_info


# Buttons for callables that point to scripts
# I dont think are serialisable as a setting properly.
# so they always set. I should check the settings resource.
static func add_callable_as_button(
			path:String,
			callable:Callable,
			label:String = callable.get_method().capitalize(),
			) -> void:
	editor_settings.set( path, callable )
	editor_settings.add_property_info({
		&'name': path,
		&'type': TYPE_CALLABLE,
		&'hint': PROPERTY_HINT_TOOL_BUTTON,
		&'hint_string': label,
	})


## Add all the properties as settings
func add_target_properties() -> void:
	print("Adding exported properties of '%s' to prefix: '%s'" % [_target, _prefix])
	for property:Dictionary in _target.get_property_list():
		# We're abusing the property usage here, but custom settings are always
		# considered advanced so this flag isnt necessarily used for any other
		# purpose at this time.
		if not (property.usage & PROPERTY_USAGE_EDITOR_BASIC_SETTING):
			continue

		var prop_name:String = property.get(&'name')
		print("\tProperty: '%s'" % prop_name)
		
		var current_value:Variant = _target.get( prop_name )
		print("\t\tCurrent_value '%s'" % current_value)
		
		# Optionally split on '_' and join with '/' for grouping.
		var setting_name:StringName = property.get(&'name')
		if property.usage & (PROPERTY_USAGE_GROUP | PROPERTY_USAGE_SUBGROUP):
			setting_name = '/'.join(setting_name.split('_', false,
				2 if property.usage & PROPERTY_USAGE_SUBGROUP else 1))
		
		setting_name = _prefix.path_join( setting_name )
		
		# Handle TOOL_BUTTON hint
		if current_value \
		and property.type == TYPE_CALLABLE \
		and property.hint & PROPERTY_HINT_TOOL_BUTTON:
			print("Assigning Tool Button")
			var button_func:Callable = current_value
			var hint_string:String = property.hint_string
			add_callable_as_button(setting_name, button_func, hint_string )
			continue
		
		# Construct setting info.
		var setting_info:Dictionary = {
			&'name': setting_name,
			&'type': property.type,
			&'hint': property.hint,
			&'hint_string': property.hint_string
		}
		
		# update the settings.
		print("\t\tSetting: '%s' = %s" % [setting_name, str(current_value)] )
		if not editor_settings.has_setting(setting_name):
			editor_settings.set_setting( setting_name, current_value )
			editor_settings.set_initial_value(setting_name, current_value, true)
		
		# Incase our plugin has changed, update the setting
		editor_settings.set_initial_value(setting_name, current_value, false)
		editor_settings.add_property_info(setting_info)

		continue
		var prop_val:Variant = editor_settings.get(setting_name)
		_target.set( prop_name, prop_val )


## Add some boilerplate settings.
func add_helper_properties() -> void:
	add_callable_as_button(
		_prefix.path_join(helper_group).path_join(&"inspect"),
		EditorInterface.inspect_object.bind(_target),
		"Inspect EditorPlugin Instance" )

	add_callable_as_button(
		_prefix.path_join(helper_group).path_join(&"rebuild"),
		_on_rebuild_pressed,
		"Rebuild Settings" )
		
	add_callable_as_button(
		_prefix.path_join(helper_group).path_join(&"erase"),
		_on_erase_pressed,
		"Erase Extension Prefix" )
	
	add_callable_as_button(
		_prefix.path_join(helper_group).path_join(&"unload"),
		_on_unload_pressed,
		"Unload Extension" )


## Erase all editor settings from a prefix
static func erase_prefix( prefix:String ) -> void:
	print("Scrubbing '%s/*' from editor configuration." % prefix )
	for property in editor_settings.get_property_list():
		# ignore properties outside of our prefix.
		var setting_name:String = property.get(&'name')
		if not setting_name.begins_with(prefix): continue
		
		# CALLABLES aren't serialisable, but we are unable to change the usage flags.
		# if we try to erase it here we get following error
		# ERROR: property(settings-helper_rebuild) invalid for target(FlatBuffers)
		if property.type == TYPE_CALLABLE: continue
		# the dictionary provided here, while mutable, is a copy.
		# there appears to be no way to change the property usage flags.
		# this set's up a situation where once set, a callable cannot be unset.
		
		print( "Erasing: %s" % setting_name)
		editor_settings.erase(setting_name)
