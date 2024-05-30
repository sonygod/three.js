import sys.regex.Regex;

// Characters [].:/ are reserved for track binding syntax.
final _RESERVED_CHARS_RE = "\\[\\]\\.:\\/";
final _reservedRe = new Regex("[" + _RESERVED_CHARS_RE + "]", "g");

// Attempts to allow node names from any language. ES5's \\w regexp matches
// only latin characters, and the unicode \\p{L} is not yet supported. So
// instead, we exclude reserved characters and match everything else.
final _wordChar = "[^" + _RESERVED_CHARS_RE + "]";
final _wordCharOrDot = "[^" + _RESERVED_CHARS_RE.replace("\\.", "") + "]";

// Parent directories, delimited by '/' or ':'. Currently unused, but must
// be matched to parse the rest of the track name.
final _directoryRe = Regex.create("(?:(?:WC+)*)".replace("WC", _wordChar)).source;

// Target node. May contain word characters (a-zA-Z0-9_) and '.' or '-'.
final _nodeRe = Regex.create("(WCOD+)?".replace("WCOD", _wordCharOrDot)).source;

// Object on target node, and accessor. May not contain reserved
// characters. Accessor may contain any character except closing bracket.
final _objectRe = Regex.create("(?:\\.(WC+)(?:\\[(.+)\\])?)?".replace("WC", _wordChar)).source;

// Property and accessor. May not contain reserved characters. Accessor may
// contain any non-bracket characters.
final _propertyRe = Regex.create("\\.(WC+)(?:\\[(.+)\\])?".replace("WC", _wordChar)).source;

final _trackRe = new Regex(
	"^" +
	_directoryRe +
	_nodeRe +
	_objectRe +
	_propertyRe +
	"\$"
);

final _supportedObjectNames = ["material", "materials", "bones", "map"];

class Composite {

	var _targetGroup: Dynamic;
	var _bindings: Array<Dynamic>;

	public function new(targetGroup: Dynamic, path: String, optionalParsedPath: Dynamic) {
		this._targetGroup = targetGroup;
		this._bindings = targetGroup.subscribe_(path, optionalParsedPath);
	}

	public function getValue(array: Array<Float>, offset: Int): Void {
		this.bind(); // bind all binding

		var firstValidIndex = this._targetGroup.nCachedObjects_;
		var binding = this._bindings[firstValidIndex];

		// and only call .getValue on the first
		if (binding != null) {
			binding.getValue(array, offset);
		}
	}

	public function setValue(array: Array<Float>, offset: Int): Void {
		var bindings = this._bindings;

		for (i in this._targetGroup.nCachedObjects_...bindings.length) {
			bindings[i].setValue(array, offset);
		}
	}

	public function bind(): Void {
		var bindings = this._bindings;

		for (i in this._targetGroup.nCachedObjects_...bindings.length) {
			bindings[i].bind();
		}
	}

	public function unbind(): Void {
		var bindings = this._bindings;

		for (i in this._targetGroup.nCachedObjects_...bindings.length) {
			bindings[i].unbind();
		}
	}
}

class PropertyBinding {

	var path: String;
	var parsedPath: Dynamic;
	var node: Dynamic;
	var rootNode: Dynamic;
	var getValue: Array<Float> -> Int -> Void;
	var setValue: Array<Float> -> Int -> Void;

	public function new(rootNode: Dynamic, path: String, parsedPath: Dynamic) {
		this.path = path;
		this.parsedPath = parsedPath != null ? parsedPath : PropertyBinding.parseTrackName(path);
		this.node = PropertyBinding.findNode(rootNode, this.parsedPath.nodeName);
		this.rootNode = rootNode;
		this.getValue = this._getValue_unbound;
		this.setValue = this._setValue_unbound;
	}

	static public function create(root: Dynamic, path: String, parsedPath: Dynamic): PropertyBinding {
		if (root != null && Reflect.field(root, "isAnimationObjectGroup")) {
			return new PropertyBinding.Composite(root, path, parsedPath);
		} else {
			return new PropertyBinding(root, path, parsedPath);
		}
	}

	static public function sanitizeNodeName(name: String): String {
		return name.split(" ").join("_").replace(_reservedRe, "");
	}

	static public function parseTrackName(trackName: String): Dynamic {
		var matches = _trackRe.match(trackName);

		if (matches == null) {
			throw new Error("PropertyBinding: Cannot parse trackName: " + trackName);
		}

		var results = {
			nodeName: matches[2],
			objectName: matches[3],
			objectIndex: matches[4],
			propertyName: matches[5], // required
			propertyIndex: matches[6]
		};

		var lastDot = results.nodeName.lastIndexOf(".");
		if (lastDot != null && lastDot != -1) {
			var objectName = results.nodeName.substring(lastDot + 1);

			if (_supportedObjectNames.indexOf(objectName) != -1) {
				results.nodeName = results.nodeName.substring(0, lastDot);
				results.objectName = objectName;
			}
		}

		if (results.propertyName == null || results.propertyName.length == 0) {
			throw new Error("PropertyBinding: can not parse propertyName from trackName: " + trackName);
		}

		return results;
	}

	static public function findNode(root: Dynamic, nodeName: String): Dynamic {
		if (nodeName == null || nodeName == "" || nodeName == "." || nodeName == -1 || nodeName == root.name || nodeName == root.uuid) {
			return root;
		}

		if (root.skeleton != null) {
			var bone = root.skeleton.getBoneByName(nodeName);
			if (bone != null) {
				return bone;
			}
		}

		if (root.children != null) {
			function searchNodeSubtree(children: Array<Dynamic>): Dynamic {
				for (childNode in children) {
					if (childNode.name == nodeName || childNode.uuid == nodeName) {
						return childNode;
					}
					var result = searchNodeSubtree(childNode.children);
					if (result != null) return result;
				}
				return null;
			}

			var subTreeNode = searchNodeSubtree(root.children);
			if (subTreeNode != null) {
				return subTreeNode;
			}
		}

		return null;
	}

	// implementation for getters/setters...

	// implementation for bind() and unbind()...

}

PropertyBinding.Composite = Composite;

PropertyBinding.prototype.BindingType = {
	Direct: 0,
	EntireArray: 1,
	ArrayElement: 2,
	HasFromToArray: 3
};

PropertyBinding.prototype.Versioning = {
	None: 0,
	NeedsUpdate: 1,
	MatrixWorldNeedsUpdate: 2
};

PropertyBinding.prototype.GetterByBindingType = [
	PropertyBinding.prototype._getValue_direct,
	PropertyBinding.prototype._getValue_array,
	PropertyBinding.prototype._getValue_arrayElement,
	PropertyBinding.prototype._getValue_toArray
];

PropertyBinding.prototype.SetterByBindingTypeAndVersioning = [
	[
		PropertyBinding.prototype._setValue_direct,
		PropertyBinding.prototype._setValue_direct_setNeedsUpdate,
		PropertyBinding.prototype._setValue_direct_setMatrixWorldNeedsUpdate
	], [
		PropertyBinding.prototype._setValue_array,
		PropertyBinding.prototype._setValue_array_setNeedsUpdate,
		PropertyBinding.prototype._setValue_array_setMatrixWorldNeedsUpdate
	], [
		PropertyBinding.prototype._setValue_arrayElement,
		PropertyBinding.prototype._setValue_arrayElement_setNeedsUpdate,
		PropertyBinding.prototype._setValue_arrayElement_setMatrixWorldNeedsUpdate
	], [
		PropertyBinding.prototype._setValue_fromArray,
		PropertyBinding.prototype._setValue_fromArray_setNeedsUpdate,
		PropertyBinding.prototype._setValue_fromArray_setMatrixWorldNeedsUpdate
	]
];