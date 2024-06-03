import haxe.regexp.Regex;
import haxe.ds.StringMap;

// Characters [].:/ are reserved for track binding syntax.
var _RESERVED_CHARS_RE:String = "\\[\\\\\\]\\.:\\/";
var _reservedRe:Regex = new Regex("[\\" + _RESERVED_CHARS_RE + "]", "g");

// Attempts to allow node names from any language. ES5's `\w` regexp matches
// only latin characters, and the unicode \p{L} is not yet supported. So
// instead, we exclude reserved characters and match everything else.
var _wordChar:String = "[^\\" + _RESERVED_CHARS_RE + "]";
var _wordCharOrDot:String = "[^\\" + _RESERVED_CHARS_RE.replace("\\.", "") + "]";

// Parent directories, delimited by '/' or ':'. Currently unused, but must
// be matched to parse the rest of the track name.
var _directoryRe:Regex = new Regex((new Regex("((?:WC+[\/:])*)/")).source.replace("WC", _wordChar), "g");

// Target node. May contain word characters (a-zA-Z0-9_) and '.' or '-'.
var _nodeRe:Regex = new Regex((new Regex("(WCOD+)?").source).replace("WCOD", _wordCharOrDot), "g");

// Object on target node, and accessor. May not contain reserved
// characters. Accessor may contain any character except closing bracket.
var _objectRe:Regex = new Regex((new Regex("(?:\\.(WC+)(?:\[(.+)\])?)?").source).replace("WC", _wordChar), "g");

// Property and accessor. May not contain reserved characters. Accessor may
// contain any non-bracket characters.
var _propertyRe:Regex = new Regex((new Regex("\\.(WC+)(?:\[(.+)\])?").source).replace("WC", _wordChar), "g");

var _trackRe:Regex = new Regex(""
	+ "^"
	+ _directoryRe.source
	+ _nodeRe.source
	+ _objectRe.source
	+ _propertyRe.source
	+ "$"
);

var _supportedObjectNames:Array<String> = ["material", "materials", "bones", "map"];

class Composite {

	public _targetGroup:Dynamic;
	public _bindings:Array<Dynamic>;

	public function new(targetGroup:Dynamic, path:String, optionalParsedPath:Dynamic) {
		var parsedPath:Dynamic = optionalParsedPath != null ? optionalParsedPath : PropertyBinding.parseTrackName(path);

		this._targetGroup = targetGroup;
		this._bindings = targetGroup.subscribe_(path, parsedPath);
	}

	public function getValue(array:Array<Float>, offset:Int):Void {
		this.bind(); // bind all binding

		var firstValidIndex:Int = this._targetGroup.nCachedObjects_;
		var binding:Dynamic = this._bindings[firstValidIndex];

		// and only call .getValue on the first
		if (binding != null) binding.getValue(array, offset);
	}

	public function setValue(array:Array<Float>, offset:Int):Void {
		var bindings:Array<Dynamic> = this._bindings;

		for (var i:Int = this._targetGroup.nCachedObjects_, n:Int = bindings.length; i != n; ++i) {
			bindings[i].setValue(array, offset);
		}
	}

	public function bind():Void {
		var bindings:Array<Dynamic> = this._bindings;

		for (var i:Int = this._targetGroup.nCachedObjects_, n:Int = bindings.length; i != n; ++i) {
			bindings[i].bind();
		}
	}

	public function unbind():Void {
		var bindings:Array<Dynamic> = this._bindings;

		for (var i:Int = this._targetGroup.nCachedObjects_, n:Int = bindings.length; i != n; ++i) {
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

	public path:String;
	public parsedPath:Dynamic;
	public node:Dynamic;
	public rootNode:Dynamic;
	public getValue:Dynamic;
	public setValue:Dynamic;
	public targetObject:Dynamic;
	public resolvedProperty:Dynamic;
	public propertyIndex:Int;
	public propertyName:String;

	public function new(rootNode:Dynamic, path:String, parsedPath:Dynamic) {
		this.path = path;
		this.parsedPath = parsedPath != null ? parsedPath : PropertyBinding.parseTrackName(path);

		this.node = PropertyBinding.findNode(rootNode, this.parsedPath.nodeName);

		this.rootNode = rootNode;

		// initial state of these methods that calls 'bind'
		this.getValue = this._getValue_unbound;
		this.setValue = this._setValue_unbound;
	}

	static public function create(root:Dynamic, path:String, parsedPath:Dynamic):Dynamic {
		if (!(root != null && root.isAnimationObjectGroup)) {
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
	static public function sanitizeNodeName(name:String):String {
		return name.replace(new Regex("\\s", "g"), "_").replace(_reservedRe, "");
	}

	static public function parseTrackName(trackName:String):Dynamic {
		var matches:Array<String> = _trackRe.match(trackName);

		if (matches == null) {
			throw new Error("PropertyBinding: Cannot parse trackName: " + trackName);
		}

		var results:Dynamic = {
			// directoryName: matches[ 1 ], // (tschw) currently unused
			nodeName: matches[2],
			objectName: matches[3],
			objectIndex: matches[4],
			propertyName: matches[5], // required
			propertyIndex: matches[6]
		};

		var lastDot:Int = results.nodeName != null && results.nodeName.lastIndexOf(".") != -1 ? results.nodeName.lastIndexOf(".") : -1;

		if (lastDot != -1) {
			var objectName:String = results.nodeName.substring(lastDot + 1);

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

	static public function findNode(root:Dynamic, nodeName:String):Dynamic {
		if (nodeName == null || nodeName == "" || nodeName == "." || nodeName == -1 || nodeName == root.name || nodeName == root.uuid) {
			return root;
		}

		// search into skeleton bones.
		if (root.skeleton != null) {
			var bone:Dynamic = root.skeleton.getBoneByName(nodeName);

			if (bone != null) {
				return bone;
			}
		}

		// search into node subtree.
		if (root.children != null) {
			var searchNodeSubtree:Dynamic = function(children:Array<Dynamic>):Dynamic {
				for (var i:Int = 0; i < children.length; i++) {
					var childNode:Dynamic = children[i];

					if (childNode.name == nodeName || childNode.uuid == nodeName) {
						return childNode;
					}

					var result:Dynamic = searchNodeSubtree(childNode.children);

					if (result != null) return result;
				}

				return null;
			};

			var subTreeNode:Dynamic = searchNodeSubtree(root.children);

			if (subTreeNode != null) {
				return subTreeNode;
			}
		}

		return null;
	}

	// these are used to "bind" a nonexistent property
	public function _getValue_unavailable():Void {
	}
	public function _setValue_unavailable():Void {
	}

	// Getters

	public function _getValue_direct(buffer:Array<Float>, offset:Int):Void {
		buffer[offset] = this.targetObject[this.propertyName];
	}

	public function _getValue_array(buffer:Array<Float>, offset:Int):Void {
		var source:Array<Float> = this.resolvedProperty;

		for (var i:Int = 0, n:Int = source.length; i != n; ++i) {
			buffer[offset++] = source[i];
		}
	}

	public function _getValue_arrayElement(buffer:Array<Float>, offset:Int):Void {
		buffer[offset] = this.resolvedProperty[this.propertyIndex];
	}

	public function _getValue_toArray(buffer:Array<Float>, offset:Int):Void {
		this.resolvedProperty.toArray(buffer, offset);
	}

	// Direct

	public function _setValue_direct(buffer:Array<Float>, offset:Int):Void {
		this.targetObject[this.propertyName] = buffer[offset];
	}

	public function _setValue_direct_setNeedsUpdate(buffer:Array<Float>, offset:Int):Void {
		this.targetObject[this.propertyName] = buffer[offset];
		this.targetObject.needsUpdate = true;
	}

	public function _setValue_direct_setMatrixWorldNeedsUpdate(buffer:Array<Float>, offset:Int):Void {
		this.targetObject[this.propertyName] = buffer[offset];
		this.targetObject.matrixWorldNeedsUpdate = true;
	}

	// EntireArray

	public function _setValue_array(buffer:Array<Float>, offset:Int):Void {
		var dest:Array<Float> = this.resolvedProperty;

		for (var i:Int = 0, n:Int = dest.length; i != n; ++i) {
			dest[i] = buffer[offset++];
		}
	}

	public function _setValue_array_setNeedsUpdate(buffer:Array<Float>, offset:Int):Void {
		var dest:Array<Float> = this.resolvedProperty;

		for (var i:Int = 0, n:Int = dest.length; i != n; ++i) {
			dest[i] = buffer[offset++];
		}

		this.targetObject.needsUpdate = true;
	}

	public function _setValue_array_setMatrixWorldNeedsUpdate(buffer:Array<Float>, offset:Int):Void {
		var dest:Array<Float> = this.resolvedProperty;

		for (var i:Int = 0, n:Int = dest.length; i != n; ++i) {
			dest[i] = buffer[offset++];
		}

		this.targetObject.matrixWorldNeedsUpdate = true;
	}

	// ArrayElement

	public function _setValue_arrayElement(buffer:Array<Float>, offset:Int):Void {
		this.resolvedProperty[this.propertyIndex] = buffer[offset];
	}

	public function _setValue_arrayElement_setNeedsUpdate(buffer:Array<Float>, offset:Int):Void {
		this.resolvedProperty[this.propertyIndex] = buffer[offset];
		this.targetObject.needsUpdate = true;
	}

	public function _setValue_arrayElement_setMatrixWorldNeedsUpdate(buffer:Array<Float>, offset:Int):Void {
		this.resolvedProperty[this.propertyIndex] = buffer[offset];
		this.targetObject.matrixWorldNeedsUpdate = true;
	}

	// HasToFromArray

	public function _setValue_fromArray(buffer:Array<Float>, offset:Int):Void {
		this.resolvedProperty.fromArray(buffer, offset);
	}

	public function _setValue_fromArray_setNeedsUpdate(buffer:Array<Float>, offset:Int):Void {
		this.resolvedProperty.fromArray(buffer, offset);
		this.targetObject.needsUpdate = true;
	}

	public function _setValue_fromArray_setMatrixWorldNeedsUpdate(buffer:Array<Float>, offset:Int):Void {
		this.resolvedProperty.fromArray(buffer, offset);
		this.targetObject.matrixWorldNeedsUpdate = true;
	}

	public function _getValue_unbound(targetArray:Array<Float>, offset:Int):Void {
		this.bind();
		this.getValue(targetArray, offset);
	}

	public function _setValue_unbound(sourceArray:Array<Float>, offset:Int):Void {
		this.bind();
		this.setValue(sourceArray, offset);
	}

	// create getter / setter pair for a property in the scene graph
	public function bind():Void {
		var targetObject:Dynamic = this.node;
		var parsedPath:Dynamic = this.parsedPath;

		var objectName:String = parsedPath.objectName;
		var propertyName:String = parsedPath.propertyName;
		var propertyIndex:Int = parsedPath.propertyIndex;

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
			var objectIndex:Int = parsedPath.objectIndex;

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
					for (var i:Int = 0; i < targetObject.length; i++) {
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
		var nodeProperty:Dynamic = targetObject[propertyName];

		if (nodeProperty == null) {
			var nodeName:String = parsedPath.nodeName;

			console.error("THREE.PropertyBinding: Trying to update property for track: " + nodeName +
				"." + propertyName + " but it wasn't found.", targetObject);
			return;
		}

		// determine versioning scheme
		var versioning:Int = this.Versioning.None;

		this.targetObject = targetObject;

		if (targetObject.needsUpdate != null) { // material
			versioning = this.Versioning.NeedsUpdate;
		} else if (targetObject.matrixWorldNeedsUpdate != null) { // node transform
			versioning = this.Versioning.MatrixWorldNeedsUpdate;
		}

		// determine how the property gets bound
		var bindingType:Int = this.BindingType.Direct;

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
		} else if (Std.isOfType(nodeProperty, Array)) {
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
	PropertyBinding.prototype._getValue_toArray
];

PropertyBinding.prototype.SetterByBindingTypeAndVersioning = [
	[
		// Direct
		PropertyBinding.prototype._setValue_direct,
		PropertyBinding.prototype._setValue_direct_setNeedsUpdate,
		PropertyBinding.prototype._setValue_direct_setMatrixWorldNeedsUpdate
	], [
		// EntireArray
		PropertyBinding.prototype._setValue_array,
		PropertyBinding.prototype._setValue_array_setNeedsUpdate,
		PropertyBinding.prototype._setValue_array_setMatrixWorldNeedsUpdate
	], [
		// ArrayElement
		PropertyBinding.prototype._setValue_arrayElement,
		PropertyBinding.prototype._setValue_arrayElement_setNeedsUpdate,
		PropertyBinding.prototype._setValue_arrayElement_setMatrixWorldNeedsUpdate
	], [
		// HasToFromArray
		PropertyBinding.prototype._setValue_fromArray,
		PropertyBinding.prototype._setValue_fromArray_setNeedsUpdate,
		PropertyBinding.prototype._setValue_fromArray_setMatrixWorldNeedsUpdate
	]
];

class PropertyBindingHaxe {
	public static function get(root:Dynamic, path:String):Dynamic {
		return new PropertyBinding(root, path, null);
	}
}