
const FrameStack = preload("uid://d3cyn1bbenwmo")
const StackFrame = preload('uid://c0ub8clj4bhhv')

var _capacity:int
var _top:int = -1
var _data:Array[StackFrame]

func _init( capacity:int ) -> void:
	_capacity = capacity
	var err:int = _data.resize(capacity)
	if err: print(error_string(err))

##  to insert an element into the stack
func push( element:StackFrame ) -> void:
	assert( not is_full(), "stack overflow" )
	_top += 1
	_data[_top] = element


##  to remove an element from the stack
func pop() -> StackFrame:
	var element:StackFrame = _data[_top]
	_data[_top] = null
	_top -= 1
	return element


##  Returns the top element of the stack.
func top() -> StackFrame:
	return _data[_top]


##  returns true if stack is empty else false.
func is_empty() -> bool:
	return _top == -1


##  returns true if the stack is full else false.
func is_full() -> bool:
	return _top == _capacity -1


func duplicate() -> FrameStack:
	var new_stack:FrameStack = new(_capacity)
	new_stack._top = _top
	for i in range(_top+1):
		var frame:StackFrame = _data[i]
		new_stack._data[i] = frame.duplicate()
	return new_stack

func clear() -> void:
	_top = -1
	for i in range(_capacity):
		_data[i] = null

func size() -> int:
	return _top + 1

func _to_string() -> String:
	var strings:Array = ["(%d/%d)" % [_top+1, _capacity]]
	for i in range( _top + 1 ):
		strings.append( "\t" + str(_data[i]))
	return "\n".join( strings )
