@tool

const Parser = preload("uid://dsj2eh2lfm2sg")
const Token = preload('uid://cvcd6kyaa4f1a')
const RegExList = preload('uid://btk3lhtry00ct')


static var regex_list:RegExList :
	get():
		if not is_instance_valid(regex_list):
			regex_list = RegExList.new()
		return regex_list


# Highlight for debugging.
func print_bright( _value:String ) -> void:
	print_rich( "[b][color=yellow]%s[/color][/b]" % [_value] )

func print_token( _value:Token ) -> void:
	print_rich( "[color=yellow]%s[/color]" % [_value] )

# ██████  ███████  █████  ██████  ███████ ██████
# ██   ██ ██      ██   ██ ██   ██ ██      ██   ██
# ██████  █████   ███████ ██   ██ █████   ██████
# ██   ██ ██      ██   ██ ██   ██ ██      ██   ██
# ██   ██ ███████ ██   ██ ██████  ███████ ██   ██

## The reader class steps through a string, pulling out tokens as it goes.


# MARK: Signals
#   ___ _                _
#  / __(_)__ _ _ _  __ _| |___
#  \__ \ / _` | ' \/ _` | (_-<
#  |___/_\__, |_||_\__,_|_/__/
# -------|___/-----------------

signal new_token( token:Token )
signal newline( ln:int, p:int )
signal endfile( ln:int, p:int )

# MARK: Properties
#   ___                       _   _
#  | _ \_ _ ___ _ __  ___ _ _| |_(_)___ ___
#  |  _/ '_/ _ \ '_ \/ -_) '_|  _| / -_|_-<
#  |_| |_| \___/ .__/\___|_|  \__|_\___/__/
# -------------|_|--------------------------

## The parent object is where the reader draws some information from
## If I can I should move as much out of the reader into the "parent" as possible
var parser:Parser

## A list of word separation characters
var word_separation:Array = [' ', '\t', '\n', '{','}', ':', ';', ',','=',
'(', ')', '[', ']' ]

## A list of whitespace characters
var whitespace:Array = [' ', '\t', '\n']

## A list of punctuation characters
var punc:Array = [',', '.', ':', ';', '[', ']', '{', '}', '(', ')', '=']

## The text to parse
var text:String

## cursor position for each line start
var line_index:Array[int] = [0]

## Cursor position in file
var cursor_p:int = 0

## Cursor position in line
var cursor_lp:int = 0

## Current line number
var line_n:int = 0

## When updating chunks of a larger source file, what line does this chunk start on.
var line_start:int

## Flag to tell if we are parsing a portion of a document or the whole text.
## determines if the end of the ext block is an EOL or an EOF
var whole_file:bool = false

func _init( parser_ref:Parser ) -> void:
	if parser_ref: parser = parser_ref


func _to_string() -> String:
	return JSON.stringify({
		'text': text,
		'text_length': text.length(),
		'line_index':line_index,
		'cursor_p': cursor_p,
		'cursor_lp': cursor_lp,
		'line_n': line_n,
		'line_start': line_start,
		'token': str(peek_token()),
	},'\t', false)


func reset( text_:String, line_i:int = 0, is_whole_file:bool = false ) -> void:
	text = text_
	line_index = [0]
	cursor_p = 0
	cursor_lp = 0
	line_start = line_i
	line_n = line_i
	whole_file = is_whole_file


# MARK: adv_
#           _
#   __ _ __| |_ __
#  / _` / _` \ V /
#  \__,_\__,_|\_/ ___
# ---------------|___|-

func adv( dist:int = 1 ) -> void:
	if cursor_p >= text.length(): return # dont advance further than length
	for i in dist:
		cursor_p += 1
		cursor_lp += 1
		if not cursor_p < text.length():
			endfile.emit( line_n + 1, cursor_p )
			return;
		if peek_char( ) != '\n': continue
		line_index.append( cursor_p )
		cursor_lp = 0
		line_n = line_index.size() -1
		newline.emit( line_n, cursor_p )
		break


## Advance the the reader until we reach a line break.
func adv_line() -> void:
	adv( text.length() ) # adv automatically stops on a line break.


## Advance the the reader while we are detecting whitespace
func adv_whitespace() -> void:
	while peek_char() in whitespace and not at_end():
		adv()

## Advance the the reader the length of the given token
func adv_token( token:Token ) -> void:
	adv( token.t.length() )

# MARK: peek_
#                 _
#   _ __  ___ ___| |__
#  | '_ \/ -_) -_) / /
#  | .__/\___\___|_\_\ ___
# -|_|----------------|___|-

func peek_char( offset:int = 0 ) -> String:
	if cursor_p + offset < text.length():
		return text[cursor_p + offset]
	else:
		return '\n'


func peek_word() -> String:
	adv_whitespace()
	# include . if not starting with a number
	var separators:Array = word_separation.duplicate(true)
	if not is_integer(peek_char()): separators = separators + ['.']

	var length:int = 0
	while not peek_char(length) in separators:
		length += 1
	return text.substr( cursor_p, length )


func peek_string() -> String:
	if peek_char() != '"': return '' # fail if not start with quotes.
	var length:int = 0
	while true:
		length += 1
		if peek_char(length) == '\n': return '"' # fail on eol or eof
		if (peek_char(length) == '"'
			and peek_char(length-1) != '\\'):
				length += 1
				break
	return text.substr( cursor_p, length )


func peek_line( offset:int = 0 ) -> String:
	var eol:int = text.find('\n', cursor_p + offset)
	if eol < 0: eol = text.length()
	return text.substr(cursor_p, eol - cursor_p)


func peek_token() -> Token:
	var p_token:Token
	while true:
		adv_whitespace()
		# end of file

		p_token = Token.new(line_n, cursor_lp, Token.Type.EOF if whole_file else Token.Type.EOL, peek_char() )
		if at_end(): break

		p_token.type = Token.Type.UNKNOWN

		# char based tokens
		if p_token.t == '/' and peek_char(1) == '/':
			if peek_char(2) == '/':
				p_token.type = Token.Type.COMMENT_DOC
			else:
				p_token.type = Token.Type.COMMENT
			p_token.t = peek_line()
		elif p_token.t == '\n':
			p_token.type = Token.Type.EOL
		elif p_token.t in punc:
			p_token.type = Token.Type.PUNCT
		elif p_token.t == '"':
			p_token.t = peek_string()
			if p_token.t.length() > 2:
				p_token.type = Token.Type.STRING


		if p_token.type != Token.Type.UNKNOWN:
			break

		# word based token
		p_token.t = peek_word()
		if is_keyword(p_token.t): p_token.type = Token.Type.KEYWORD
		elif is_scalar( p_token.t ): p_token.type = Token.Type.SCALAR
		elif is_type( p_token.t ): p_token.type = Token.Type.TYPE
		elif is_ident(p_token.t): p_token.type = Token.Type.IDENT

		break

	return p_token

# MARK: get_
#            _
#   __ _ ___| |_
#  / _` / -_)  _|
#  \__, \___|\__| ___
# -|___/---------|___|-

# the set of get functions grabs the next item and moves the cursor forward.

func get_char() -> String:
	adv(); return text[cursor_p - 1]


func get_word() -> String:
	adv_whitespace()
	var word:String = peek_word()
	adv( word.length() )
	return word


func get_line( _offset:int = 0 ) -> String:
	var start:int = cursor_p
	adv_line()
	return text.substr( start, cursor_p - start )


func get_token() -> Token:
	var token:Token = peek_token()
	adv_token(token)
	new_token.emit( token )
	return token


func get_string() -> String:
	var string:String = peek_string()
	adv( string.length() )
	return string


func get_integer_constant() -> Token:
	# Verify Starting position.
	var p_token:Token = peek_token()
	if p_token.type != Token.Type.UNKNOWN:
		return p_token

	#INTEGER_CONSTANT, # = dec_integer_constant | hex_integer_constant

	#DEC_INTEGER_CONSTANT, # = [-+]?[:digit:]+
	#DIGIT, # [:digit:] = [0-9]

	#HEX_INTEGER_CONSTANT, # = [-+]?0[xX][:xdigit:]+
	#XDIGIT, # [:xdigit:] = [0-9a-fA-F]

	var first_char:String = "-+0123456789abcdefABCDEF"
	var valid_chars:String = "xX0123456789abcdefABCDEF"
	if peek_char() not in first_char: return p_token
	p_token.type = Token.Type.SCALAR
	# seek to the end and return our valid integer constant
	var start:int = cursor_p
	while not at_end():
		adv()
		if peek_char() in valid_chars: continue
		break

	p_token.t = text.substr( start, cursor_p - start )
	new_token.emit( p_token )
	return p_token


# MARK: query
#   __ _ _  _ ___ _ _ _  _
#  / _` | || / -_) '_| || |
#  \__, |\_,_\___|_|  \_, |
# ----|_|-------------|__/--

func at_end() -> bool:
	if cursor_p >= text.length(): return true
	return false


func is_type( word:String )-> bool:
	return word in parser.scalar_types


func is_keyword( word:String ) -> bool:
	return word in parser.keywords


func is_ident( word:String ) -> bool:
	if regex_list.ident.search(word):
		return true
	return false


##scalar = boolean_constant | integer_constant | float_constant
func is_scalar( word:String ) -> bool:
	return is_boolean( word ) or is_integer( word ) or is_float( word )


func is_boolean( word:String ) -> bool:
	return word in ['true', 'false']


## integer_constant = dec_integer_constant | hex_integer_constant
func is_integer( word:String ) -> bool:
	return (regex_list.dec_integer_constant.search(word)
		or regex_list.hex_integer_constant.search(word))


## float_constant = dec_float_constant | hex_float_constant | special_float_constant
func is_float( word:String ) -> bool:
	return (regex_list.dec_float_constant.search( word )
		or regex_list.hex_float_constant.search( word )
		or regex_list.special_float_constant.search( word ))
