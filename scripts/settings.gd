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
## ProjectSettings.[br]
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

enum HintEnum {
	PROPERTY_HINT_NONE = 0,
	PROPERTY_HINT_RANGE = 1,
	PROPERTY_HINT_ENUM = 2,
	PROPERTY_HINT_ENUM_SUGGESTION = 3,
	PROPERTY_HINT_EXP_EASING = 4,
	PROPERTY_HINT_LINK = 5,
	PROPERTY_HINT_FLAGS = 6,
	PROPERTY_HINT_LAYERS_2D_RENDER = 7,
	PROPERTY_HINT_LAYERS_2D_PHYSICS = 8,
	PROPERTY_HINT_LAYERS_2D_NAVIGATION = 9,
	PROPERTY_HINT_LAYERS_3D_RENDER = 10,
	PROPERTY_HINT_LAYERS_3D_PHYSICS = 11,
	PROPERTY_HINT_LAYERS_3D_NAVIGATION = 12,
	PROPERTY_HINT_LAYERS_AVOIDANCE = 37,
	PROPERTY_HINT_FILE = 13,
	PROPERTY_HINT_DIR = 14,
	PROPERTY_HINT_GLOBAL_FILE = 15,
	PROPERTY_HINT_GLOBAL_DIR = 16,
	PROPERTY_HINT_RESOURCE_TYPE = 17,
	PROPERTY_HINT_MULTILINE_TEXT = 18,
	PROPERTY_HINT_EXPRESSION = 19,
	PROPERTY_HINT_PLACEHOLDER_TEXT = 20,
	PROPERTY_HINT_COLOR_NO_ALPHA = 21,
	PROPERTY_HINT_OBJECT_ID = 22,
	PROPERTY_HINT_TYPE_STRING = 23,
	PROPERTY_HINT_NODE_PATH_TO_EDITED_NODE = 24,
	PROPERTY_HINT_OBJECT_TOO_BIG = 25,
	PROPERTY_HINT_NODE_PATH_VALID_TYPES = 26,
	PROPERTY_HINT_SAVE_FILE = 27,
	PROPERTY_HINT_GLOBAL_SAVE_FILE = 28,
	PROPERTY_HINT_INT_IS_OBJECTID = 29,
	PROPERTY_HINT_INT_IS_POINTER = 30,
	PROPERTY_HINT_ARRAY_TYPE = 31,
	PROPERTY_HINT_DICTIONARY_TYPE = 38,
	PROPERTY_HINT_LOCALE_ID = 32,
	PROPERTY_HINT_LOCALIZABLE_STRING = 33,
	PROPERTY_HINT_NODE_TYPE = 34,
	PROPERTY_HINT_HIDE_QUATERNION_EDIT = 35,
	PROPERTY_HINT_PASSWORD = 36,
	PROPERTY_HINT_TOOL_BUTTON = 39,
	PROPERTY_HINT_ONESHOT = 40,
	PROPERTY_HINT_GROUP_ENABLE = 42,
	PROPERTY_HINT_INPUT_NAME = 43,
	PROPERTY_HINT_FILE_PATH = 44,
	PROPERTY_HINT_MAX = 45
}

# flag_name = bit position
enum UsageFlags {
	INVALID = 1,
	PROPERTY_USAGE_STORAGE = 2,
	PROPERTY_USAGE_EDITOR = 3,
	PROPERTY_USAGE_INTERNAL = 4,
	PROPERTY_USAGE_CHECKABLE = 5,
	PROPERTY_USAGE_CHECKED = 6,
	PROPERTY_USAGE_GROUP = 7,
	PROPERTY_USAGE_CATEGORY = 8,
	PROPERTY_USAGE_SUBGROUP = 9,
	PROPERTY_USAGE_CLASS_IS_BITFIELD = 10,
	PROPERTY_USAGE_NO_INSTANCE_STATE = 11,
	PROPERTY_USAGE_RESTART_IF_CHANGED = 12,
	PROPERTY_USAGE_SCRIPT_VARIABLE = 13,
	PROPERTY_USAGE_STORE_IF_NULL = 14,
	PROPERTY_USAGE_UPDATE_ALL_IF_MODIFIED = 15,
	PROPERTY_USAGE_SCRIPT_DEFAULT_VALUE = 16,
	PROPERTY_USAGE_CLASS_IS_ENUM = 17,
	PROPERTY_USAGE_NIL_IS_VARIANT = 18,
	PROPERTY_USAGE_ARRAY = 19,
	PROPERTY_USAGE_ALWAYS_DUPLICATE = 20,
	PROPERTY_USAGE_NEVER_DUPLICATE = 21,
	PROPERTY_USAGE_HIGH_END_GFX = 22,
	PROPERTY_USAGE_NODE_PATH_FROM_SCENE_ROOT = 23,
	PROPERTY_USAGE_RESOURCE_NOT_PERSISTENT = 24,
	PROPERTY_USAGE_KEYING_INCREMENTS = 25,
	PROPERTY_USAGE_DEFERRED_SET_RESOURCE = 26,
	PROPERTY_USAGE_EDITOR_INSTANTIATE_OBJECT = 27,
	PROPERTY_USAGE_EDITOR_BASIC_SETTING = 28,
	PROPERTY_USAGE_READ_ONLY = 28,
	PROPERTY_USAGE_SECRET = 30,
}

# ██████  ██████   ██████  ██████  ███████ ██████  ████████ ██ ███████ ███████ #
# ██   ██ ██   ██ ██    ██ ██   ██ ██      ██   ██    ██    ██ ██      ██      #
# ██████  ██████  ██    ██ ██████  █████   ██████     ██    ██ █████   ███████ #
# ██      ██   ██ ██    ██ ██      ██      ██   ██    ██    ██ ██           ██ #
# ██      ██   ██  ██████  ██      ███████ ██   ██    ██    ██ ███████ ███████ #
func                        ________PROPERTIES_______              ()->void:pass

var _prefix:String
var _target:Object
var _target_file:String # from what I can tell, the category for the script settings is the filename
var _helper_group:StringName = &"settings-helper"

## I need to keep a map of setting to prop.name in order to respect the grouping prefixes
var setting_prop_map:Dictionary = {}

signal settings_changed( setting_name:StringName, value:Variant )

#             ███████ ██    ██ ███████ ███    ██ ████████ ███████              #
#             ██      ██    ██ ██      ████   ██    ██    ██                   #
#             █████   ██    ██ █████   ██ ██  ██    ██    ███████              #
#             ██       ██  ██  ██      ██  ██ ██    ██         ██              #
#             ███████   ████   ███████ ██   ████    ██    ███████              #
func                        __________EVENTS_________              ()->void:pass

func _on_editor_settings_changed() -> void:
	print("_on_editor_settings_changed")
	update_target.call_deferred()


#      ██████  ██    ██ ███████ ██████  ██████  ██ ██████  ███████ ███████     #
#     ██    ██ ██    ██ ██      ██   ██ ██   ██ ██ ██   ██ ██      ██          #
#     ██    ██ ██    ██ █████   ██████  ██████  ██ ██   ██ █████   ███████     #
#     ██    ██  ██  ██  ██      ██   ██ ██   ██ ██ ██   ██ ██           ██     #
#      ██████    ████   ███████ ██   ██ ██   ██ ██ ██████  ███████ ███████     #
func                        ________OVERRIDES________              ()->void:pass

func _init( target:Object, prefix:String = "plugin/un-named" )-> void:
	print("_init")
	_prefix = prefix
	_target = target
	
	var test_path:String = _target.get_script().resource_path
	_target_file = test_path.get_file()
	
	add_target_properties()
	#add_helper_properties()

	# when plugins are disabled, they are deleted.
	@warning_ignore_start('return_value_discarded')
	ProjectSettings.settings_changed.connect( _on_editor_settings_changed )
	@warning_ignore_restore('return_value_discarded')


#         ███    ███ ███████ ████████ ██   ██  ██████  ██████  ███████         #
#         ████  ████ ██         ██    ██   ██ ██    ██ ██   ██ ██              #
#         ██ ████ ██ █████      ██    ███████ ██    ██ ██   ██ ███████         #
#         ██  ██  ██ ██         ██    ██   ██ ██    ██ ██   ██      ██         #
#         ██      ██ ███████    ██    ██   ██  ██████  ██████  ███████         #
func                        _________METHODS_________              ()->void:pass

func bitmask_array( value:int, max_width:int ) -> PackedByteArray:
	var result:PackedByteArray
	result.resize(max_width)
	for i:int in max_width:
		result[i] = (value >> i) & 1
	#result.reverse()
	return result


func get_usage_flags( bits:PackedByteArray ) -> PackedStringArray:
	var result:PackedStringArray
	for i:int in bits.size():
		if bits[i]: result.push_back(UsageFlags.find_key(i+1))
	return result


## Add all the properties as settings
func add_target_properties() -> void:
	print("add_target_properties")
	
	var output_string:String
	var category:String
	var group:String
	var group_prefix:String
	var subgroup:String
	var subgroup_prefix:String
	
	var is_inside_script:bool = false
	
	# From observations of how the existing grouping works in the inspector.
	# If a group or subgroup prefix exists, and is not used in a property name
	# then the flow is broken, and the grouping and grouping prefix tags are reset.
	
	for property:Dictionary in _target.get_property_list():
		var property_name:String = property.name
		print("\nproperty.name: ", property.name)
		var property_type:int = property.type
		print("property.type: ", type_string(property.type))
		var property_hint:int = property.hint
		print("property.hint: ", HintEnum.find_key(property_hint))
		var hint_string:String = property.hint_string
		print("property.hint_string: ", property.hint_string)
		
		var usage:int = property.usage
		var usage_bits := bitmask_array(usage, 30)
		var usage_flags := get_usage_flags(usage_bits)
		print("property.usage: ",  usage_flags )
		
		var property_value:Variant = _target.get(property_name)
		print("value: ",  property_value )
		
		
		if property.usage & PROPERTY_USAGE_CATEGORY:
			# When the category that matches the script name shows up, then we
			# are looking at our exported variables.
			if property_name == _target_file:
				is_inside_script = true
				category = "" # We dont want to keep the main category
				continue
			if not is_inside_script: continue
			
			category = property_name
			group = ""
			group_prefix = ""
			subgroup = ""
			subgroup_prefix = ""
			continue
		
		if not is_inside_script: continue
			
		if property.usage & PROPERTY_USAGE_GROUP:
			group = property_name
			group_prefix = hint_string
			subgroup = ""
			subgroup_prefix = ""
			continue
		
		if property.usage & PROPERTY_USAGE_SUBGROUP:
			subgroup = property_name
			subgroup_prefix = hint_string
			continue
		
		# Skip any setting that doesnt have the store flag.
		if not (usage & PROPERTY_USAGE_STORAGE):
			continue
		
		var group_level:int = 0 # top level
		var trimmed:bool = false
		var setting_name:String
		
		# failure to match a prefix reset's the prefix for that level.
		if subgroup and subgroup_prefix:
			if property_name.begins_with(subgroup_prefix):
				print("matched subgroup_prefix")
				setting_name = property_name.trim_prefix(subgroup_prefix)
				trimmed = true
				group_level = 2
			else:
				subgroup_prefix = ""
		elif subgroup:
			group_level = 2
				
		if group_level == 0:
			if group_prefix:
				if property_name.begins_with(group_prefix):
					print("match group_prefix")
					setting_name = property_name.trim_prefix(group_prefix)
					trimmed = true
					group_level = 1
				else:
					group_prefix = ""
			elif group:
				group_level = 1
		
		if group_level == 0:
			setting_name = property_name
		
		var parts:Array = [_prefix]
		if category: parts.append(category)
		if group_level > 0:
			parts.append(group)
			if group_level > 1: parts.append(subgroup)
			
		var setting_path:String = '/'.join(parts)
		var setting_full:String = setting_path.path_join(setting_name)
		
		print("Category: ", category)
		print("Group: ", [group, group_prefix])
		print("SubGroup: ", [subgroup, subgroup_prefix])
		print("group_level: ", group_level)
		print("Trimmed: ", trimmed)
		print("Setting Path: ", setting_path)
		print("Setting Name: ", setting_name)
		print("Setting_full: ", setting_full)
		
		# Handle TOOL_BUTTON hint
		if property_value \
		and property_type == TYPE_CALLABLE \
		and property_hint & PROPERTY_HINT_TOOL_BUTTON:
			print("is button")
			var button_func:Callable = property_value
			add_callable_as_button(setting_name, button_func, hint_string )
			continue
		
		# NOTE: if the name has been trimmed due to grouping prefixes, then we cant
		# derive the name from the settings path without additional info.
		# so we keep the original in a map
		# NOTE: because there is no help in determining what has changed, we'll
		# chuck all the settings in here and refer to it later.
		#if trimmed:
		setting_prop_map[setting_full] = property_name

		# Construct setting info.
		var setting_info:Dictionary = {
			&'name': setting_full,
			&'type': property_type,
			&'hint': property_hint,
			&'hint_string': hint_string
		}

		if ProjectSettings.has_setting(setting_full):
			# apply the saved value
			var setting_value:Variant = ProjectSettings.get_setting( setting_full )
			ProjectSettings.add_property_info(setting_info)
			if setting_value == property_value: continue
			else: _target.set(property_name, setting_value)
		else:
			# add the settings.
			ProjectSettings.set_setting( setting_full, property_value )
			ProjectSettings.add_property_info(setting_info)


func update_target() -> void:
	print("update_target")
	for setting_name:String in setting_prop_map.keys():
		var setting_val:Variant = ProjectSettings.get(setting_name)
		var prop_name:StringName = setting_prop_map[setting_name]
		var prop_val:Variant = _target.get(prop_name)
		if setting_val == prop_val: continue
		_target.set(prop_name, setting_val)
		settings_changed.emit( prop_name, prop_val )


func inspect_target() -> void:
	print("inspect_target")
	EditorInterface.inspect_object.bind(_target)

#                 ███████ ████████  █████  ████████ ██  ██████                 #
#                 ██         ██    ██   ██    ██    ██ ██                      #
#                 ███████    ██    ███████    ██    ██ ██                      #
#                      ██    ██    ██   ██    ██    ██ ██                      #
#                 ███████    ██    ██   ██    ██    ██  ██████                 #
func                        __________STATIC_________              ()->void:pass

## Scan addons folder for plugins [br]
## Each dict:
## [codeblock]{
##   "path"[/code]:   "res://addons/my_plugin/",
##   "config"[/code]: {"name": "...", "script": "...", ...}
## }[/codeblock]
static func get_all_plugins_info( only_loaded:bool = false) -> Array[Dictionary]:
	print("get_all_plugins_info")
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
# FIXME These dont serialise to editor-settings properly, and once set cannot be unset
static func add_callable_as_button(
			path:String,
			callable:Callable,
			label:String = callable.get_method().capitalize(),
			) -> void:
	print("add_callable_as_button")
	ProjectSettings.set( path, callable )
	ProjectSettings.add_property_info({
		&'name': path,
		&'type': TYPE_CALLABLE,
		&'hint': PROPERTY_HINT_TOOL_BUTTON,
		&'hint_string': label,
	})


## Erase all editor settings from a prefix
static func erase_prefix( prefix:String ) -> void:
	print("erase_prefix")
	for property in ProjectSettings.get_property_list():
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
		ProjectSettings.set_setting(setting_name, null)
