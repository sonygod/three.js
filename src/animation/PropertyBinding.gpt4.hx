// Characters [].:/ are reserved for track binding syntax.
private static var _RESERVED_CHARS_RE:String = "\\[\\]\\.:\\/";
private static var _reservedRe:EReg = ~/[\\[\\]\\.:\\/]/g;

// Attempts to allow node names from any language. ES5's `\w` regexp matches
// only latin characters, and the unicode \p{L} is not yet supported. So
// instead, we exclude reserved characters and match everything else.
private static var _wordChar:String = '[^' + _RESERVED_CHARS_RE + ']';
private static var _wordCharOrDot:String = '[^' + _RESERVED_CHARS_RE.replace("\\.", "") + ']';

// Parent directories, delimited by '/' or ':'. Currently unused, but must
// be matched to parse the rest of the track name.
private static var _directoryRe:String = new EReg('((?:' + _wordChar + '+[\\/:])*)', '');

// Target node. May contain word characters (a-zA-Z0-9_) and '.' or '-'.
private static var _nodeRe:String = new EReg('(' + _wordCharOrDot + '+)?', '');

// Object on target node, and accessor. May not contain reserved
// characters. Accessor may contain any character except closing bracket.
private static var _objectRe:String = new EReg('(?:\\.' + _wordChar + '+(?:\\[(.+)\\])?)?', '');

// Property and accessor. May not contain reserved characters. Accessor may
// contain any non-bracket characters.
private static var _propertyRe:String = new EReg('\\.' + _wordChar + '+(?:\\[(.+)\\])?', '');

// Combined regex for track binding
private static var _trackRe:EReg = new EReg(
	'^' + _directoryRe + _nodeRe + _objectRe + _propertyRe + '$', ''
);

private static var _supportedObjectNames:Array<String> = ['material', 'materials', 'bones', 'map'];

class Composite {
	private var _targetGroup:Dynamic;
	private var _bindings:Array<Dynamic>;

	public function new(targetGroup:Dynamic, path:String, optionalParsedPath:Dynamic = null) {
		var parsedPath = optionalParsedPath != null ? optionalParsedPath : PropertyBinding.parseTrackName(path);
		this._targetGroup = targetGroup;
		this._bindings = targetGroup.subscribe_(path, parsedPath);
	}

	public function getValue(array:Array<Float>, offset:Int):Void {
		this.bind(); // bind all binding
		var firstValidIndex = this._targetGroup.nCachedObjects_;
		var binding = this._bindings[firstValidIndex];
		// and only call .getValue on the first
		if (binding != null) binding.getValue(array, offset);
	}

	public function setValue(array:Array<Float>, offset:Int):Void {
		var bindings = this._bindings;
		for (i in this._targetGroup.nCachedObjects_...bindings.length) {
			bindings[i].setValue(array, offset);
		}
	}

	public function bind():Void {
		var bindings = this._bindings;
		for (i in this._targetGroup.nCachedObjects_...bindings.length) {
			bindings[i].bind();
		}
	}

	public function unbind():Void {
		var bindings = this._bindings;
		for (i in this._targetGroup.nCachedObjects_...bindings.length) {
			bindings[i].unbind();
		}
	}
}

class PropertyBinding {
	public var path:String;
	public var parsedPath:Dynamic;
	public var node:Dynamic;
	public var rootNode:Dynamic;
	public var targetObject:Dynamic;
	public var resolvedProperty:Dynamic;
	public var propertyName:String;
	public var propertyIndex:Int;

	public static var Composite = Composite;

	private static var BindingType = {
		Direct: 0,
		EntireArray: 1,
		ArrayElement: 2,
		HasFromToArray: 3
	};

	private static var Versioning = {
		None: 0,
		NeedsUpdate: 1,
		MatrixWorldNeedsUpdate: 2
	};

	private static var GetterByBindingType = [
		_getValue_direct,
		_getValue_array,
		_getValue_arrayElement,
		_getValue_toArray
	];

	private static var SetterByBindingTypeAndVersioning = [
		[_setValue_direct, _setValue_direct_setNeedsUpdate, _setValue_direct_setMatrixWorldNeedsUpdate],
		[_setValue_array, _setValue_array_setNeedsUpdate, _setValue_array_setMatrixWorldNeedsUpdate],
		[_setValue_arrayElement, _setValue_arrayElement_setNeedsUpdate, _setValue_arrayElement_setMatrixWorldNeedsUpdate],
		[_setValue_fromArray, _setValue_fromArray_setNeedsUpdate, _setValue_fromArray_setMatrixWorldNeedsUpdate]
	];

	public function new(rootNode:Dynamic, path:String, parsedPath:Dynamic = null) {
		this.path = path;
		this.parsedPath = parsedPath != null ? parsedPath : PropertyBinding.parseTrackName(path);
		this.node = PropertyBinding.findNode(rootNode, this.parsedPath.nodeName);
		this.rootNode = rootNode;
		this.getValue = this._getValue_unbound;
		this.setValue = this._setValue_unbound;
	}

	public static function create(root:Dynamic, path:String, parsedPath:Dynamic = null):Dynamic {
		if (root == null || !Reflect.hasField(root, 'isAnimationObjectGroup')) {
			return new PropertyBinding(root, path, parsedPath);
		} else {
			return new Composite(root, path, parsedPath);
		}
	}

	public static function sanitizeNodeName(name:String):String {
		return name.replace(" ", "_").replace(_reservedRe, "");
	}

	public static function parseTrackName(trackName:String):Dynamic {
		var matches = _trackRe.match(trackName);
		if (matches == null) {
			throw "PropertyBinding: Cannot parse trackName: " + trackName;
		}

		var results = {
			nodeName: matches[2],
			objectName: matches[3],
			objectIndex: matches[4],
			propertyName: matches[5],
			propertyIndex: matches[6]
		};

		var lastDot = results.nodeName != null ? results.nodeName.lastIndexOf('.') : -1;

		if (lastDot != -1) {
			var objectName = results.nodeName.substring(lastDot + 1);
			if (_supportedObjectNames.indexOf(objectName) != -1) {
				results.nodeName = results.nodeName.substring(0, lastDot);
				results.objectName = objectName;
			}
		}

		if (results.propertyName == null || results.propertyName.length == 0) {
			throw "PropertyBinding: can not parse propertyName from trackName: " + trackName;
		}

		return results;
	}

	public static function findNode(root:Dynamic, nodeName:String):Dynamic {
		if (nodeName == null || nodeName == '' || nodeName == '.' || nodeName == -1 || nodeName == root.name || nodeName == root.uuid) {
			return root;
		}

		if (root.skeleton != null) {
			var bone = root.skeleton.getBoneByName(nodeName);
			if (bone != null) {
				return bone;
			}
		}

		if (root.children != null) {
			var searchNodeSubtree = function(children:Array<Dynamic>):Dynamic {
				for (childNode in children) {
					if (childNode.name == nodeName || childNode.uuid == nodeName) {
						return childNode;
					}
					var result = searchNodeSubtree(childNode.children);
					if (result != null) return result;
				}
				return null;
			};

			var subTreeNode = searchNodeSubtree(root.children);
			if (subTreeNode != null) {
				return subTreeNode;
			}
		}

		return null;
	}

	// these are used to "bind" a nonexistent property
	private function _getValue_unavailable():Void {}
	private function _setValue_unavailable():Void {}

	// Getters
	private function _getValue_direct(buffer:Array<Float>, offset:Int):Void {
		buffer[offset] = Reflect.field(this.targetObject, this.propertyName);
	}

	private function _getValue_array(buffer:Array<Float>, offset:Int):Void {
		var source = this.resolvedProperty;
		for (i in 0...source.length) {
			buffer[offset++] = source[i];
		}
	}

	private function _getValue_arrayElement(buffer:Array<Float>, offset:Int):Void {
		buffer[offset] = this.resolvedProperty[this.propertyIndex];
	}

	private function _getValue_toArray(buffer:Array<Float>, offset:Int):Void {
		this.resolvedProperty.toArray(buffer, offset);
	}

	// Direct setters
	private function _setValue_direct(buffer:Array<Float>, offset:Int):Void {
		Reflect.setField(this.targetObject, this.propertyName, buffer[offset]);
	}

	private function _setValue_direct_setNeedsUpdate(buffer:Array<Float>, offset:Int):Void {
		Reflect.setField(this.targetObject, this.propertyName, buffer[offset]);
		Reflect.setField(this.targetObject, "needsUpdate", true);
	}

	private function _setValue_direct_setMatrixWorldNeedsUpdate(buffer:Array<Float>, offset:Int):Void {
		Reflect.setField(this.targetObject, this.propertyName, buffer[offset]);
		Reflect.setField(this.targetObject, "matrixWorldNeedsUpdate", true);
	}

	// Array setters
	private function _setValue_array(buffer:Array<Float>, offset:Int):Void {
		var dest = this.resolvedProperty;
		for (i in 0...dest.length) {
			dest[i] = buffer[offset++];
		}
	}

	private function _setValue_array_setNeedsUpdate(buffer:Array<Float>, offset:Int):Void {
		var dest = this.resolvedProperty;
		for (i in 0...dest.length) {
			dest[i] = buffer[offset++];
		}
		Reflect.setField(this.targetObject, "needsUpdate", true);
	}

	private function _setValue_array_setMatrixWorldNeedsUpdate(buffer:Array<Float>, offset:Int):Void {
		var dest = this.resolvedProperty;
		for (i in 0...dest.length) {
			dest[i] = buffer[offset++];
		}
		Reflect.setField(this.targetObject, "matrixWorldNeedsUpdate", true);
	}

	// Array element setters
	private function _setValue_arrayElement(buffer:Array<Float>, offset:Int):Void {
		this.resolvedProperty[this.propertyIndex] = buffer[offset];
	}

	private function _setValue_arrayElement_setNeedsUpdate(buffer:Array<Float>, offset:Int):Void {
		this.resolvedProperty[this.propertyIndex] = buffer[offset];
		Reflect.setField(this.targetObject, "needsUpdate", true);
	}

	private function _setValue_arrayElement_setMatrixWorldNeedsUpdate(buffer:Array<Float>, offset:Int):Void {
		this.resolvedProperty[this.propertyIndex] = buffer[offset];
		Reflect.setField(this.targetObject, "matrixWorldNeedsUpdate", true);
	}

	// From array setters
	private function _setValue_fromArray(buffer:Array<Float>, offset:Int):Void {
		this.resolvedProperty.fromArray(buffer, offset);
	}

	private function _setValue_fromArray_setNeedsUpdate(buffer:Array<Float>, offset:Int):Void {
		this.resolvedProperty.fromArray(buffer, offset);
		Reflect.setField(this.targetObject, "needsUpdate", true);
	}

	private function _setValue_fromArray_setMatrixWorldNeedsUpdate(buffer:Array<Float>, offset:Int):Void {
		this.resolvedProperty.fromArray(buffer, offset);
		Reflect.setField(this.targetObject, "matrixWorldNeedsUpdate", true);
	}

	private function _getValue_unbound():Void {}
	private function _setValue_unbound():Void {}
	private function bind():Void {}
	private function unbind():Void {}
}