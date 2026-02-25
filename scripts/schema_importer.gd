@tool
extends EditorImportPlugin

var verbose:bool = false
var default_suffix:String = "_generated"

func printy( ...args:Array ) -> void:
	if verbose: print(' '.join(args))

func                        __Boiler___Plate_________              ()->void:pass
#region Boiler - Plate
#MARK: Boiler - Plate
## │ ___      _ _                 ___ _      _          [br]
## │| _ ) ___(_) |___ _ _   ___  | _ \ |__ _| |_ ___    [br]
## │| _ \/ _ \ | / -_) '_| |___| |  _/ / _` |  _/ -_)   [br]
## │|___/\___/_|_\___|_|         |_| |_\__,_|\__\___|   [br]
## ╰─────────────────────────────────────────────────── [br]

func _can_import_threaded() -> bool: return true
func _get_importer_name(): return "flatbuffers.fbs"
func _get_visible_name(): return "FlatBuffers Schema"
func _get_recognized_extensions(): return ["fbs"]
func _get_save_extension(): return "tres"
func _get_resource_type(): return "FlatBuffersSchema"

# I'm frustrated with my attempts at using the preset and visibility features,
# it appears that visibility is not-recalculated when a setting is changed, 
# so these methods appears to have no meaningful impact
func _get_preset_count(): return 1
func _get_preset_name(preset_index): return "Default"
func _get_option_visibility(path, option_name, options): return true

#endregion Boiler - Plate

func _get_import_options(source_file:String, preset_index:int) -> Array:
	# I can put placeholder text into properties in some circumstances
	return [{
			"name": "verbose_output", 
			"default_value": true,
			"usage":PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_RESOURCE_NOT_PERSISTENT 
		},{
			"name": "do_not_generate", 
			"default_value": true,
		},{
			"name": "file_names_only", 
			"default_value": false,
		},{
			"name": "no_warnings", 
			"default_value": false,
		},{
			"name": "warnings_as_errors", 
			"default_value": false,
		},{
			"name": "include", 
			"default_value": ""
		},{
			"name": "output/language", 
			"default_value": "gdscript",
			"property_hint": PROPERTY_HINT_ENUM_SUGGESTION,
			"hint_string":"gdscript", # I think I might be able to support more languages later.
		},{
			"name": "output/file/path_prefix", 
			"default_value": "",
			"property_hint": PROPERTY_HINT_DIR,
		},{
			"name": "output/file/name_suffix", 
			"default_value": "",
			"property_hint": PROPERTY_HINT_PLACEHOLDER_TEXT ,
			"hint_string":"_generated",
		},{
			"name": "output/file/name_ext", 
			"default_value": "",
		},{
			# TODO it is quite possible to parse and detect the root type
			"name": "output/code_gen/root_type", 
			"default_value": "",
		},{
			"name": "output/code_gen/gen_all", 
			"default_value": false,
		},{
			"name": "output/code_gen/no_includes", 
			"default_value": false,
		},{
			"name": "output/code_gen/gen_mutable", 
			"default_value": false,
		},{
			"name": "output/code_gen/gen_one_file", 
			"default_value": false,
		},{
			"name": "output/code_gen/no_emit_min_max_enum_values", 
			"default_value": false,
		},{
			"name": "output/code_gen/object_api/gen_object_api", 
			"default_value": false,
		},{
			"name": "output/code_gen/object_api/object_prefix", 
			"default_value": "",
		},{
			"name": "output/code_gen/object_api/object_suffix", 
			"default_value": "",
		},{
			"name": "output/code_gen/object_api/gen_compare", 
			"default_value": false,
		},{
			"name": "output/code_gen/gdscript/debug", 
			"default_value": false,
		}]

#MARK: Import
##                                  [br]
## │ ___                     _      [br]
## │|_ _|_ __  _ __  ___ _ _| |_    [br]
## │ | || '  \| '_ \/ _ \ '_|  _|   [br]
## │|___|_|_|_| .__/\___/_|  \__|   [br]
## ╰──────────|_|────────────────── [br]
func                        __________IMPORT_________              ()->void:pass

func _import(
			source_file:String, 
			save_path:String, 
			options:Dictionary, 
			platform_variants:Array[String], 
			gen_files:Array[String]) -> Error:
	verbose = options.verbose_output
	printy(JSON.stringify(options, '  ', false))
	var args:PackedStringArray
	
	# do all the gathering of into, but do not run flatc.
	var do_not_generate:bool = options.get('do_not_generate', true)
	
	args.append_array(configure_flatc(
		source_file, save_path, options, platform_variants, gen_files))
	
	# Generator Language
	var lang:String
	match options.get('output/language'):
		'gdscript': lang = '--gdscript'
		_: do_not_generate = true
	
	args.append_array(configure_output_file(
		source_file, save_path, options, platform_variants, gen_files))
	
	if not lang.is_empty(): args.append(lang)
	
	args.append_array(configure_code_gen(
		source_file, save_path, options, platform_variants, gen_files))
	
	args.append_array(configure_object_api(
		source_file, save_path, options, platform_variants, gen_files))
	
	args.append_array(configure_gdscript(
		source_file, save_path, options, platform_variants, gen_files))
	
	printy( "args: ", args )
	if do_not_generate:
		printy( 'resource options specified "do not generate"' )
		return OK
	
	var results:Dictionary = FlatBuffersPlugin.generate(source_file, args)
	# reults dictionary has the following fields:
	# {
	# 	'schema': the path to the schema 
	# 	'flatc_path': the path to the flatc executable
	# 	'args':args used to run the program
	# 	'retcode': integer result of calling the flatc compiler.
	# 	'output': stdout + stderr
	# }
	var empty_res := Resource.new()
	var filename = save_path + "." + _get_save_extension()
	ResourceSaver.save(empty_res, filename)
	
	printy("save_path: ", save_path)
	printy( JSON.stringify( results.output, '  ', false) )
	if results.retcode > 0: return FAILED
	return OK


#region flatc process
#MARK: flatc process
##                                                     [br]
## │  __ _      _                                      [br]
## │ / _| |__ _| |_ __   _ __ _ _ ___  __ ___ ______   [br]
## │|  _| / _` |  _/ _| | '_ \ '_/ _ \/ _/ -_|_-<_-<   [br]
## │|_| |_\__,_|\__\__| | .__/_| \___/\__\___/__/__/   [br]
## ╰────────────────────|_|─────────────────────────── [br]
func configure_flatc(source_file:String, 
			save_path:String, 
			options:Dictionary, 
			platform_variants:Array[String], 
			gen_files:Array[String]) -> PackedStringArray:
	var args:PackedStringArray
	
	# File Names Only
	if options.get('output/file_names_only', false):
		args.append('--file-names-only')
	
	# No Warnings
	if options.get('output/no_warnings', false):
		args.append('--no-warnings')
	
	# Warnings As Errors
	if options.get('output/warnings_as_errors', false):
		args.append('--warnings-as-errors')
	
	return args
#endregion flatc process


#region Output File
#MARK: Output File
##                                                 [br]
## │  ___       _             _     ___ _ _        [br]
## │ / _ \ _  _| |_ _ __ _  _| |_  | __(_) |___    [br]
## │| (_) | || |  _| '_ \ || |  _| | _|| | / -_)   [br]
## │ \___/ \_,_|\__| .__/\_,_|\__| |_| |_|_\___|   [br]
## ╰───────────────|_|──────────────────────────── [br]
func configure_output_file(source_file:String, 
			save_path:String, 
			options:Dictionary, 
			platform_variants:Array[String], 
			gen_files:Array[String]) -> PackedStringArray:
	var args:PackedStringArray
	
	# Generator Language
	var default_ext:String
	match options.get('output/language'):
		'gdscript': default_ext = '.gd'

	# Output Path Prefix
	var output_path_prefix:String = options.get('output/file/path_prefix')
	if output_path_prefix.is_empty():
		printy("Using default output_path_prefix: ", source_file.get_base_dir())
	else:
		args.append_array(['-o', output_path_prefix])
		
	# Output File Name
	var output_filename:String = source_file.get_basename().get_file()
	
	# Output Name Suffix
	var output_name_suffix:String = options.get('output/file/name_suffix')
	if output_name_suffix.is_empty():
		printy("Using default output_file_suffix: ", '_generated')
	else:
		args.append_array(['--filename-suffix', output_name_suffix])
	
	# Output Name Extension
	var output_name_ext:String = options.get('output/file/name_ext')
	if output_name_ext.is_empty():
		printy("Using default output_file_ext: ", default_ext)
	else:
		args.append_array(['--filename-ext', output_name_ext])
		
	return args
#endregion Output File


#region Code Generator
#MARK: Code Generator
## │  ___         _        ___                       _              [br]
## │ / __|___  __| |___   / __|___ _ _  ___ _ _ __ _| |_ ___ _ _    [br]
## │| (__/ _ \/ _` / -_) | (_ / -_) ' \/ -_) '_/ _` |  _/ _ \ '_|   [br]
## │ \___\___/\__,_\___|  \___\___|_||_\___|_| \__,_|\__\___/_|     [br]
## ╰─────────────────────────────────────────────────────────────── [br]
func configure_code_gen(source_file:String, 
			save_path:String, 
			options:Dictionary, 
			platform_variants:Array[String], 
			gen_files:Array[String]) -> PackedStringArray:
	var args:PackedStringArray
	
	# root_type
	var root_type:String = options.get('output/code_gen/root_type')
	if root_type.is_empty():
		# TODO it is quite possible to parse and detect the root type
		printy("Using default root_type") 
	else:
		args.append_array(['--root-type', root_type])
	
	# gen-all
	if options.get('output/code_gen/gen_all', false):
		args.append('--gen-all')
	
	# no-includes
	if options.get('output/code_gen/no_includes', false):
		args.append('--no-includes')
	
	# Generate Mutable Accessors
	if options.get('output/code_gen/gen_mutable', false):
		args.append('--gen-mutable')
	
	# Generate One File
	if options.get('output/code_gen/gen_one_file', false):
		args.append('--gen-onefile')
	
	# Generate One File
	if options.get('output/code_gen/no_emit_min_max_enum_values', false):
		args.append('--no-emit-min-max-enum-values')
	
	return args
#endregion Code Generator


#region Object API
#MARK: Object API
##                                               [br]
## │  ___  _     _        _       _   ___ ___    [br]
## │ / _ \| |__ (_)___ __| |_    /_\ | _ \_ _|   [br]
## │| (_) | '_ \| / -_) _|  _|  / _ \|  _/| |    [br]
## │ \___/|_.__// \___\__|\__| /_/ \_\_| |___|   [br]
## ╰──────────|__/────────────────────────────── [br]
func configure_object_api(source_file:String, 
			save_path:String, 
			options:Dictionary, 
			platform_variants:Array[String], 
			gen_files:Array[String]) -> PackedStringArray:
	var args:PackedStringArray
	
	# Generate Object API
	if options.get('output/code_gen/object_api/gen_object_api', false):
		args.append('--gen-object-api')

	# Object Prefix
	var object_prefix:String = options.get('output/code_gen/object_api/object_prefix')
	if not object_prefix.is_empty():
		args.append_array(['--object-prefix', object_prefix])
		
	# Object Suffix
	var object_suffix:String = options.get('output/code_gen/object_api/object_suffix')
	if not object_suffix.is_empty():
		args.append_array(['--object-suffix', object_suffix])

	# Generate Comparitors
	if options.get('output/code_gen/object_api/gen_compare', false):
		args.append('--gen-compare')

	return args
#endregion Object API

#region GDScript
#MARK: GDScript
##                                       [br]
## │  ___ ___  ___         _      _      [br]
## │ / __|   \/ __| __ _ _(_)_ __| |_    [br]
## │| (_ | |) \__ \/ _| '_| | '_ \  _|   [br]
## │ \___|___/|___/\__|_| |_| .__/\__|   [br]
## ╰────────────────────────|_|───────── [br]
func configure_gdscript(source_file:String, 
			save_path:String, 
			options:Dictionary, 
			platform_variants:Array[String], 
			gen_files:Array[String]) -> PackedStringArray:
	var args:PackedStringArray
	
	# Add gdscript debugging code
	if options.get('output/code_gen/gdscript/debug', false):
		args.append('--gdscript-debug')
		
	return args

#endregion GDScript
