import three.AnimationObjectGroup;
import three.AnimationObjectGroupBase;

// Characters [].:/ are reserved for track binding syntax.
var _RESERVED_CHARS_RE = "\\[\\]\\.:\\/";
var _reservedRe = RegExp.create("[\\" + _RESERVED_CHARS_RE + "\\]", "g");

// Attempts to allow node names from any language. ES5's `\w` regexp matches
// only latin characters, and the unicode \p{L} is not yet supported. So
// instead, we exclude reserved characters and match everything else.
var _wordChar = "[^\\" + _RESERVED_CHARS_RE + "\\]";
var _wordCharOrDot = "[^\\" + _RESERVED_CHARS_RE.replace("\\.", "") + "\\]";

// Parent directories, delimited by '/' or ':'. Currently unused, but must
// be matched to parse the rest of the track name.
var _directoryRe = RegExp.create("((?:WC+[\/:])*)/".replace("WC", _wordChar));

// Target node. May contain word characters (a-zA-Z0-9_) and '.' or '-'.
var _nodeRe = RegExp.create("(WCOD+)?/".replace("WCOD", _wordCharOrDot));

// Object on target node, and accessor. May not contain reserved
// characters. Accessor may contain any character except closing bracket.
var _objectRe = RegExp.create("(?:\\.(WC+)(?:\[(.+)\])?)?/".replace("WC", _wordChar));

// Property and accessor. May not contain reserved characters. Accessor may
// contain any non-bracket characters.
var _propertyRe = RegExp.create("\\.(WC+)(?:\[(.+)\])?/".replace("WC", _wordChar));

var _trackRe = RegExp.create(
	"^"
	+ _directoryRe.source
	+ _nodeRe.source
	+ _objectRe.source
	+ _propertyRe.source
	+ "$"
);

var _supportedObjectNames = ["material", "materials", "bones", "map"];

class Composite {
	private _targetGroup:AnimationObjectGroup;
	private _bindings:Array<PropertyBinding>;

	public function new(targetGroup:AnimationObjectGroup, path:String, optionalParsedPath:Dynamic = null) {
		var parsedPath = optionalParsedPath != null ? optionalParsedPath : PropertyBinding.parseTrackName(path);

		this._targetGroup = targetGroup;
		this._bindings = targetGroup.subscribe_(path, parsedPath);
	}

	public function getValue(array:Array<Float>, offset:Int) {
		this.bind(); // bind all binding

		var firstValidIndex = this._targetGroup.nCachedObjects_;
		var binding = this._bindings[firstValidIndex];

		// and only call .getValue on the first
		if (binding != null) binding.getValue(array, offset);
	}

	public function setValue(array:Array<Float>, offset:Int) {
		var bindings = this._bindings;

		for (var i = this._targetGroup.nCachedObjects_, n = bindings.length; i != n; ++i) {
			bindings[i].setValue(array, offset);
		}
	}

	public function bind() {
		var bindings = this._bindings;

		for (var i = this._targetGroup.nCachedObjects_, n = bindings.length; i != n; ++i) {
			bindings[i].bind();
		}
	}

	public function unbind() {
		var bindings = this._bindings;

		for (var i = this._targetGroup.nCachedObjects_, n = bindings.length; i != n; ++i) {
			bindings[i].unbind();
		}
	}
}

// Note: This class uses a State pattern on a per-method basis:
// 'bind' sets 'this.getValue' / 'setValue' and shadows the
// prototype version of these methods with one that represents
// the bound state. When the property is not found, the methods
// become no-ops.
class PropertyBinding {
	private path:String;
	private parsedPath:Dynamic;
	private node:Dynamic;
	private rootNode:Dynamic;
	private targetObject:Dynamic;
	private propertyName:String;
	private propertyIndex:Int;
	private resolvedProperty:Dynamic;

	public function new(rootNode:Dynamic, path:String, parsedPath:Dynamic = null) {
		this.path = path;
		this.parsedPath = parsedPath != null ? parsedPath : PropertyBinding.parseTrackName(path);

		this.node = PropertyBinding.findNode(rootNode, this.parsedPath.nodeName);

		this.rootNode = rootNode;

		// initial state of these methods that calls 'bind'
		this.getValue = this._getValue_unbound;
		this.setValue = this._setValue_unbound;
	}

	public static function create(root:Dynamic, path:String, parsedPath:Dynamic = null):PropertyBinding {
		if (! (root != null && root.isAnimationObjectGroup)) {
			return new PropertyBinding(root, path, parsedPath);
		} else {
			return new PropertyBinding.Composite(root, path, parsedPath);
		}
	}

	/**
	 * Replaces spaces with underscores and removes unsupported characters from
	 * node names, to ensure compatibility with parseTrackName().
	 *
	 * @param {string} name Node name to be sanitized.
	 * @return {string}
	 */
	public static function sanitizeNodeName(name:String):String {
		return name.replace(RegExp.create("\\s", "g"), "_").replace(_reservedRe, "");
	}

	public static function parseTrackName(trackName:String):Dynamic {
		var matches = _trackRe.exec(trackName);

		if (matches == null) {
			throw new Error("PropertyBinding: Cannot parse trackName: " + trackName);
		}

		var results = {
			// directoryName: matches[ 1 ], // (tschw) currently unused
			nodeName: matches[2],
			objectName: matches[3],
			objectIndex: matches[4],
			propertyName: matches[5], // required
			propertyIndex: matches[6]
		};

		var lastDot = results.nodeName != null && results.nodeName.lastIndexOf(".");

		if (lastDot != null && lastDot != -1) {
			var objectName = results.nodeName.substring(lastDot + 1);

			// Object names must be checked against an allowlist. Otherwise, there
			// is no way to parse 'foo.bar.baz': 'baz' must be a property, but
			// 'bar' could be the objectName, or part of a nodeName (which can
			// include '.' characters).
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

	public static function findNode(root:Dynamic, nodeName:String):Dynamic {
		if (nodeName == null || nodeName == "" || nodeName == "." || nodeName == -1 || nodeName == root.name || nodeName == root.uuid) {
			return root;
		}

		// search into skeleton bones.
		if (root.skeleton != null) {
			var bone = root.skeleton.getBoneByName(nodeName);

			if (bone != null) {
				return bone;
			}
		}

		// search into node subtree.
		if (root.children != null) {
			var searchNodeSubtree = function(children:Array<Dynamic>):Dynamic {
				for (var i = 0; i < children.length; i++) {
					var childNode = children[i];

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
	private function _getValue_unavailable(targetArray:Array<Float>, offset:Int):Void {}
	private function _setValue_unavailable(sourceArray:Array<Float>, offset:Int):Void {}

	// Getters

	private function _getValue_direct(buffer:Array<Float>, offset:Int):Void {
		buffer[offset] = this.targetObject[this.propertyName];
	}

	private function _getValue_array(buffer:Array<Float>, offset:Int):Void {
		var source = this.resolvedProperty;

		for (var i = 0, n = source.length; i != n; ++i) {
			buffer[offset++] = source[i];
		}
	}

	private function _getValue_arrayElement(buffer:Array<Float>, offset:Int):Void {
		buffer[offset] = this.resolvedProperty[this.propertyIndex];
	}

	private function _getValue_toArray(buffer:Array<Float>, offset:Int):Void {
		this.resolvedProperty.toArray(buffer, offset);
	}

	// Direct

	private function _setValue_direct(buffer:Array<Float>, offset:Int):Void {
		this.targetObject[this.propertyName] = buffer[offset];
	}

	private function _setValue_direct_setNeedsUpdate(buffer:Array<Float>, offset:Int):Void {
		this.targetObject[this.propertyName] = buffer[offset];
		this.targetObject.needsUpdate = true;
	}

	private function _setValue_direct_setMatrixWorldNeedsUpdate(buffer:Array<Float>, offset:Int):Void {
		this.targetObject[this.propertyName] = buffer[offset];
		this.targetObject.matrixWorldNeedsUpdate = true;
	}

	// EntireArray

	private function _setValue_array(buffer:Array<Float>, offset:Int):Void {
		var dest = this.resolvedProperty;

		for (var i = 0, n = dest.length; i != n; ++i) {
			dest[i] = buffer[offset++];
		}
	}

	private function _setValue_array_setNeedsUpdate(buffer:Array<Float>, offset:Int):Void {
		var dest = this.resolvedProperty;

		for (var i = 0, n = dest.length; i != n; ++i) {
			dest[i] = buffer[offset++];
		}

		this.targetObject.needsUpdate = true;
	}

	private function _setValue_array_setMatrixWorldNeedsUpdate(buffer:Array<Float>, offset:Int):Void {
		var dest = this.resolvedProperty;

		for (var i = 0, n = dest.length; i != n; ++i) {
			dest[i] = buffer[offset++];
		}

		this.targetObject.matrixWorldNeedsUpdate = true;
	}

	// ArrayElement

	private function _setValue_arrayElement(buffer:Array<Float>, offset:Int):Void {
		this.resolvedProperty[this.propertyIndex] = buffer[offset];
	}

	private function _setValue_arrayElement_setNeedsUpdate(buffer:Array<Float>, offset:Int):Void {
		this.resolvedProperty[this.propertyIndex] = buffer[offset];
		this.targetObject.needsUpdate = true;
	}

	private function _setValue_arrayElement_setMatrixWorldNeedsUpdate(buffer:Array<Float>, offset:Int):Void {
		this.resolvedProperty[this.propertyIndex] = buffer[offset];
		this.targetObject.matrixWorldNeedsUpdate = true;
	}

	// HasToFromArray

	private function _setValue_fromArray(buffer:Array<Float>, offset:Int):Void {
		this.resolvedProperty.fromArray(buffer, offset);
	}

	private function _setValue_fromArray_setNeedsUpdate(buffer:Array<Float>, offset:Int):Void {
		this.resolvedProperty.fromArray(buffer, offset);
		this.targetObject.needsUpdate = true;
	}

	private function _setValue_fromArray_setMatrixWorldNeedsUpdate(buffer:Array<Float>, offset:Int):Void {
		this.resolvedProperty.fromArray(buffer, offset);
		this.targetObject.matrixWorldNeedsUpdate = true;
	}

	private function _getValue_unbound(targetArray:Array<Float>, offset:Int):Void {
		this.bind();
		this.getValue(targetArray, offset);
	}

	private function _setValue_unbound(sourceArray:Array<Float>, offset:Int):Void {
		this.bind();
		this.setValue(sourceArray, offset);
	}

	// create getter / setter pair for a property in the scene graph
	public function bind():Void {
		var targetObject = this.node;
		var parsedPath = this.parsedPath;

		var objectName = parsedPath.objectName;
		var propertyName = parsedPath.propertyName;
		var propertyIndex = parsedPath.propertyIndex;

		if (targetObject == null) {
			targetObject = PropertyBinding.findNode(this.rootNode, parsedPath.nodeName);

			this.node = targetObject;
		}

		// set fail state so we can just 'return' on error
		this.getValue = this._getValue_unavailable;
		this.setValue = this._setValue_unavailable;

		// ensure there is a value node
		if (targetObject == null) {
			console.warn("THREE.PropertyBinding: No target node found for track: " + this.path + ".");
			return;
		}

		if (objectName != null) {
			var objectIndex = parsedPath.objectIndex;

			// special cases were we need to reach deeper into the hierarchy to get the face materials....
			switch (objectName) {
				case "materials":
					if (targetObject.material == null) {
						console.error("THREE.PropertyBinding: Can not bind to material as node does not have a material.", this);
						return;
					}

					if (targetObject.material.materials == null) {
						console.error("THREE.PropertyBinding: Can not bind to material.materials as node.material does not have a materials array.", this);
						return;
					}

					targetObject = targetObject.material.materials;

					break;
				case "bones":
					if (targetObject.skeleton == null) {
						console.error("THREE.PropertyBinding: Can not bind to bones as node does not have a skeleton.", this);
						return;
					}

					// potential future optimization: skip this if propertyIndex is already an integer
					// and convert the integer string to a true integer.

					targetObject = targetObject.skeleton.bones;

					// support resolving morphTarget names into indices.
					for (var i = 0; i < targetObject.length; i++) {
						if (targetObject[i].name == objectIndex) {
							objectIndex = i;
							break;
						}
					}

					break;
				case "map":
					if ("map" in targetObject) {
						targetObject = targetObject.map;
						break;
					}

					if (targetObject.material == null) {
						console.error("THREE.PropertyBinding: Can not bind to material as node does not have a material.", this);
						return;
					}

					if (targetObject.material.map == null) {
						console.error("THREE.PropertyBinding: Can not bind to material.map as node.material does not have a map.", this);
						return;
					}

					targetObject = targetObject.material.map;
					break;
				default:
					if (targetObject[objectName] == null) {
						console.error("THREE.PropertyBinding: Can not bind to objectName of node undefined.", this);
						return;
					}

					targetObject = targetObject[objectName];
			}

			if (objectIndex != null) {
				if (targetObject[objectIndex] == null) {
					console.error("THREE.PropertyBinding: Trying to bind to objectIndex of objectName, but is undefined.", this, targetObject);
					return;
				}

				targetObject = targetObject[objectIndex];
			}
		}

		// resolve property
		var nodeProperty = targetObject[propertyName];

		if (nodeProperty == null) {
			var nodeName = parsedPath.nodeName;

			console.error("THREE.PropertyBinding: Trying to update property for track: " + nodeName + "." + propertyName + " but it wasn't found.", targetObject);
			return;
		}

		// determine versioning scheme
		var versioning = this.Versioning.None;

		this.targetObject = targetObject;

		if (targetObject.needsUpdate != null) { // material
			versioning = this.Versioning.NeedsUpdate;
		} else if (targetObject.matrixWorldNeedsUpdate != null) { // node transform
			versioning = this.Versioning.MatrixWorldNeedsUpdate;
		}

		// determine how the property gets bound
		var bindingType = this.BindingType.Direct;

		if (propertyIndex != null) {
			// access a sub element of the property array (only primitives are supported right now)

			if (propertyName == "morphTargetInfluences") {
				// potential optimization, skip this if propertyIndex is already an integer, and convert the integer string to a true integer.

				// support resolving morphTarget names into indices.
				if (targetObject.geometry == null) {
					console.error("THREE.PropertyBinding: Can not bind to morphTargetInfluences because node does not have a geometry.", this);
					return;
				}

				if (targetObject.geometry.morphAttributes == null) {
					console.error("THREE.PropertyBinding: Can not bind to morphTargetInfluences because node does not have a geometry.morphAttributes.", this);
					return;
				}

				if (targetObject.morphTargetDictionary[propertyIndex] != null) {
					propertyIndex = targetObject.morphTargetDictionary[propertyIndex];
				}
			}

			bindingType = this.BindingType.ArrayElement;

			this.resolvedProperty = nodeProperty;
			this.propertyIndex = propertyIndex;
		} else if (nodeProperty.fromArray != null && nodeProperty.toArray != null) {
			// must use copy for Object3D.Euler/Quaternion

			bindingType = this.BindingType.HasFromToArray;

			this.resolvedProperty = nodeProperty;
		} else if (Type.typeof(nodeProperty) == TClass(Array)) {
			bindingType = this.BindingType.EntireArray;

			this.resolvedProperty = nodeProperty;
		} else {
			this.propertyName = propertyName;
		}

		// select getter / setter
		this.getValue = this.GetterByBindingType[bindingType];
		this.setValue = this.SetterByBindingTypeAndVersioning[bindingType][versioning];
	}

	public function unbind():Void {
		this.node = null;

		// back to the prototype version of getValue / setValue
		// note: avoiding to mutate the shape of 'this' via 'delete'
		this.getValue = this._getValue_unbound;
		this.setValue = this._setValue_unbound;
	}
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
	PropertyBinding.prototype._getValue_toArray,
];

PropertyBinding.prototype.SetterByBindingTypeAndVersioning = [
	[
		// Direct
		PropertyBinding.prototype._setValue_direct,
		PropertyBinding.prototype._setValue_direct_setNeedsUpdate,
		PropertyBinding.prototype._setValue_direct_setMatrixWorldNeedsUpdate,
	], [
		// EntireArray
		PropertyBinding.prototype._setValue_array,
		PropertyBinding.prototype._setValue_array_setNeedsUpdate,
		PropertyBinding.prototype._setValue_array_setMatrixWorldNeedsUpdate,
	], [
		// ArrayElement
		PropertyBinding.prototype._setValue_arrayElement,
		PropertyBinding.prototype._setValue_arrayElement_setNeedsUpdate,
		PropertyBinding.prototype._setValue_arrayElement_setMatrixWorldNeedsUpdate,
	], [
		// HasToFromArray
		PropertyBinding.prototype._setValue_fromArray,
		PropertyBinding.prototype._setValue_fromArray_setNeedsUpdate,
		PropertyBinding.prototype._setValue_fromArray_setMatrixWorldNeedsUpdate,
	]
];

class PropertyBinding_ {
	public static var Composite:Class<Composite> = Composite;
}

class PropertyBinding_ {
	public static var create:Dynamic = PropertyBinding.create;
}

class PropertyBinding_ {
	public static var sanitizeNodeName:Dynamic = PropertyBinding.sanitizeNodeName;
}

class PropertyBinding_ {
	public static var parseTrackName:Dynamic = PropertyBinding.parseTrackName;
}

class PropertyBinding_ {
	public static var findNode:Dynamic = PropertyBinding.findNode;
}

class PropertyBinding_ {
	public static var BindingType:Dynamic = PropertyBinding.prototype.BindingType;
}

class PropertyBinding_ {
	public static var Versioning:Dynamic = PropertyBinding.prototype.Versioning;
}

class PropertyBinding_ {
	public static var GetterByBindingType:Dynamic = PropertyBinding.prototype.GetterByBindingType;
}

class PropertyBinding_ {
	public static var SetterByBindingTypeAndVersioning:Dynamic = PropertyBinding.prototype.SetterByBindingTypeAndVersioning;
}

class PropertyBinding_ {
	public static var getValue:Dynamic = PropertyBinding.prototype.getValue;
	public static var setValue:Dynamic = PropertyBinding.prototype.setValue;
	public static var bind:Dynamic = PropertyBinding.prototype.bind;
	public static var unbind:Dynamic = PropertyBinding.prototype.unbind;
}