class PropertyBinding {

	public var path:String;
	public var parsedPath:ParsedPath;
	public var node:Dynamic;
	public var rootNode:Dynamic;
	public var getValue:Dynamic = this._getValue_unbound;
	public var setValue:Dynamic = this._setValue_unbound;

	public function new(rootNode:Dynamic, path:String, parsedPath:ParsedPath) {
		this.path = path;
		this.parsedPath = parsedPath != null ? parsedPath : PropertyBinding.parseTrackName(path);
		this.node = PropertyBinding.findNode(rootNode, this.parsedPath.nodeName);
		this.rootNode = rootNode;
	}

	static public function create(root:Dynamic, path:String, parsedPath:ParsedPath):PropertyBinding {
		if (!((root != null && root.isAnimationObjectGroup))) {
			return new PropertyBinding(root, path, parsedPath);
		} else {
			return new PropertyBinding.Composite(root, path, parsedPath);
		}
	}

	static public function sanitizeNodeName(name:String):String {
		return name.replace(RegExp.fromString("\\s"), '_').replace(_reservedRe, '');
	}

	static public function parseTrackName(trackName:String):ParsedPath {
		var matches = _trackRe.exec(trackName);
		if (matches == null) {
			throw new Error("PropertyBinding: Cannot parse trackName: " + trackName);
		}
		var results:ParsedPath = {
			nodeName: matches[2],
			objectName: matches[3],
			objectIndex: matches[4],
			propertyName: matches[5],
			propertyIndex: matches[6]
		};
		var lastDot = results.nodeName != null && results.nodeName.lastIndexOf('.');
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

	static public function findNode(root:Dynamic, nodeName:String):Dynamic {
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
			var searchNodeSubtree = function(children:Array<Dynamic>):Dynamic {
				for (var i = 0; i < children.length; i++) {
					var childNode = children[i];
					if (childNode.name == nodeName || childNode.uuid == nodeName) {
						return childNode;
					}
					var result = searchNodeSubtree(childNode.children);
					if (result != null) {
						return result;
					}
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

	public function _getValue_unavailable(targetArray:Array<Float>, offset:Int):Void {
		this.bind();
		this.getValue(targetArray, offset);
	}

	public function _setValue_unavailable(sourceArray:Array<Float>, offset:Int):Void {
		this.bind();
		this.setValue(sourceArray, offset);
	}

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
		this.getValue = this._getValue_unavailable;
		this.setValue = this._setValue_unavailable;
		if (targetObject == null) {
			console.warn("THREE.PropertyBinding: No target node found for track: " + this.path + ".");
			return;
		}
		if (objectName != null) {
			var objectIndex = parsedPath.objectIndex;
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
					targetObject = targetObject.skeleton.bones;
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
		var nodeProperty = targetObject[propertyName];
		if (nodeProperty == null) {
			var nodeName = parsedPath.nodeName;
			console.error("THREE.PropertyBinding: Trying to update property for track: " + nodeName + "." + propertyName + " but it wasn't found.", targetObject);
			return;
		}
		var versioning = this.Versioning.None;
		this.targetObject = targetObject;
		if (targetObject.needsUpdate != null) {
			versioning = this.Versioning.NeedsUpdate;
		} else if (targetObject.matrixWorldNeedsUpdate != null) {
			versioning = this.Versioning.MatrixWorldNeedsUpdate;
		}
		var bindingType = this.BindingType.Direct;
		if (propertyIndex != null) {
			if (propertyName == "morphTargetInfluences") {
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
			bindingType = this.BindingType.HasFromToArray;
			this.resolvedProperty = nodeProperty;
		} else if (Std.is(nodeProperty, Array)) {
			bindingType = this.BindingType.EntireArray;
			this.resolvedProperty = nodeProperty;
		} else {
			this.propertyName = propertyName;
		}
		this.getValue = this.GetterByBindingType[bindingType];
		this.setValue = this.SetterByBindingTypeAndVersioning[bindingType][versioning];
	}

	public function unbind():Void {
		this.node = null;
		this.getValue = this._getValue_unbound;
		this.setValue = this._setValue_unbound;
	}

	public function _getValue_direct(buffer:Array<Float>, offset:Int):Void {
		buffer[offset] = this.targetObject[this.propertyName];
	}

	public function _getValue_array(buffer:Array<Float>, offset:Int):Void {
		var source = this.resolvedProperty;
		for (var i = 0, n = source.length; i != n; ++i) {
			buffer[offset++] = source[i];
		}
	}

	public function _getValue_arrayElement(buffer:Array<Float>, offset:Int):Void {
		buffer[offset] = this.resolvedProperty[this.propertyIndex];
	}

	public function _getValue_toArray(buffer:Array<Float>, offset:Int):Void {
		this.resolvedProperty.toArray(buffer, offset);
	}

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

	public function _setValue_array(buffer:Array<Float>, offset:Int):Void {
		var dest = this.resolvedProperty;
		for (var i = 0, n = dest.length; i != n; ++i) {
			dest[i] = buffer[offset++];
		}
	}

	public function _setValue_array_setNeedsUpdate(buffer:Array<Float>, offset:Int):Void {
		var dest = this.resolvedProperty;
		for (var i = 0, n = dest.length; i != n; ++i) {
			dest[i] = buffer[offset++];
		}
		this.targetObject.needsUpdate = true;
	}

	public function _setValue_array_setMatrixWorldNeedsUpdate(buffer:Array<Float>, offset:Int):Void {
		var dest = this.resolvedProperty;
		for (var i = 0, n = dest.length; i != n; ++i) {
			dest[i] = buffer[offset++];
		}
		this.targetObject.matrixWorldNeedsUpdate = true;
	}

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

	public var targetObject:Dynamic;
	public var resolvedProperty:Dynamic;
	public var propertyIndex:Int;
	public var propertyName:String;

	public enum Versioning {
		None,
		NeedsUpdate,
		MatrixWorldNeedsUpdate
	}
	public enum BindingType {
		Direct,
		ArrayElement,
		EntireArray,
		HasFromToArray
	}

	static public var _trackRe:RegExp = RegExp.fromString("^(?:(?:\\.|[a-z_\\d]+)+)?(?:\\.([a-z_\\d]+))?(?:\\.([a-z_\\d]+))?(?:\\[([\\d]+)\\])?(?:\\.([a-z_\\d]+))?(?:\\[([\\d]+)\\])?$");
	static public var _reservedRe:RegExp = RegExp.fromString("[^a-z0-9_$]");
	static public var _supportedObjectNames:Array<String> = ["materials", "bones", "map"];
	static public var GetterByBindingType:Map<BindingType, Dynamic> = new Map<BindingType, Dynamic>();
	static public var SetterByBindingTypeAndVersioning:Map<BindingType, Map<Versioning, Dynamic>> = new Map<BindingType, Map<Versioning, Dynamic>>();

	static public function init():Void {
		GetterByBindingType.set(BindingType.Direct,  getPropertyBinding_getValue_direct);
		GetterByBindingType.set(BindingType.ArrayElement, getPropertyBinding_getValue_arrayElement);
		GetterByBindingType.set(BindingType.EntireArray, getPropertyBinding_getValue_array);
		GetterByBindingType.set(BindingType.HasFromToArray, getPropertyBinding_getValue_toArray);

		SetterByBindingTypeAndVersioning.set(BindingType.Direct, new Map<Versioning, Dynamic>());
		SetterByBindingTypeAndVersioning.set(BindingType.ArrayElement, new Map<Versioning, Dynamic>());
		SetterByBindingTypeAndVersioning.set(BindingType.EntireArray, new Map<Versioning, Dynamic>());
		SetterByBindingTypeAndVersioning.set(BindingType.HasFromToArray, new Map<Versioning, Dynamic>());

		SetterByBindingTypeAndVersioning[BindingType.Direct].set(Versioning.None, getPropertyBinding__setValue_direct);
		SetterByBindingTypeAndVersioning[BindingType.Direct].set(Versioning.NeedsUpdate, getPropertyBinding__setValue_direct_setNeedsUpdate);
		SetterByBindingTypeAndVersioning[BindingType.Direct].set(Versioning.MatrixWorldNeedsUpdate, getPropertyBinding__setValue_direct_setMatrixWorldNeedsUpdate);

		SetterByBindingTypeAndVersioning[BindingType.ArrayElement].set(Versioning.None, getPropertyBinding__setValue_arrayElement);
		SetterByBindingTypeAndVersioning[BindingType.ArrayElement].set(Versioning.NeedsUpdate, getPropertyBinding__setValue_arrayElement_setNeedsUpdate);
		SetterByBindingTypeAndVersioning[BindingType.ArrayElement].set(Versioning.MatrixWorldNeedsUpdate, getPropertyBinding__setValue_arrayElement_setMatrixWorldNeedsUpdate);

		SetterByBindingTypeAndVersioning[BindingType.EntireArray].set(Versioning.None, getPropertyBinding__setValue_array);
		SetterByBindingTypeAndVersioning[BindingType.EntireArray].set(Versioning.NeedsUpdate, getPropertyBinding__setValue_array_setNeedsUpdate);
		SetterByBindingTypeAndVersioning[BindingType.EntireArray].set(Versioning.MatrixWorldNeedsUpdate, getPropertyBinding__setValue_array_setMatrixWorldNeedsUpdate);

		SetterByBindingTypeAndVersioning[BindingType.HasFromToArray].set(Versioning.None, getPropertyBinding__setValue_fromArray);
		SetterByBindingTypeAndVersioning[BindingType.HasFromToArray].set(Versioning.NeedsUpdate, getPropertyBinding__setValue_fromArray_setNeedsUpdate);
		SetterByBindingTypeAndVersioning[BindingType.HasFromToArray].set(Versioning.MatrixWorldNeedsUpdate, getPropertyBinding__setValue_fromArray_setMatrixWorldNeedsUpdate);
	}

	static public function getPropertyBinding_getValue_direct(this:PropertyBinding, buffer:Array<Float>, offset:Int):Void {
		buffer[offset] = this.targetObject[this.propertyName];
	}

	static public function getPropertyBinding_getValue_arrayElement(this:PropertyBinding, buffer:Array<Float>, offset:Int):Void {
		buffer[offset] = this.resolvedProperty[this.propertyIndex];
	}

	static public function getPropertyBinding_getValue_array(this:PropertyBinding, buffer:Array<Float>, offset:Int):Void {
		var source = this.resolvedProperty;
		for (var i = 0, n = source.length; i != n; ++i) {
			buffer[offset++] = source[i];
		}
	}

	static public function getPropertyBinding_getValue_toArray(this:PropertyBinding, buffer:Array<Float>, offset:Int):Void {
		this.resolvedProperty.toArray(buffer, offset);
	}

	static public function getPropertyBinding__setValue_direct(this:PropertyBinding, buffer:Array<Float>, offset:Int):Void {
		this.targetObject[this.propertyName] = buffer[offset];
	}

	static public function getPropertyBinding__setValue_direct_setNeedsUpdate(this:PropertyBinding, buffer:Array<Float>, offset:Int):Void {
		this.targetObject[this.propertyName] = buffer[offset];
		this.targetObject.needsUpdate = true;
	}

	static public function getPropertyBinding__setValue_direct_setMatrixWorldNeedsUpdate(this:PropertyBinding, buffer:Array<Float>, offset:Int):Void {
		this.targetObject[this.propertyName] = buffer[offset];
		this.targetObject.matrixWorldNeedsUpdate = true;
	}

	static public function getPropertyBinding__setValue_array(this:PropertyBinding, buffer:Array<Float>, offset:Int):Void {
		var dest = this.resolvedProperty;
		for (var i = 0, n = dest.length; i != n; ++i) {
			dest[i] = buffer[offset++];
		}
	}

	static public function getPropertyBinding__setValue_array_setNeedsUpdate(this:PropertyBinding, buffer:Array<Float>, offset:Int):Void {
		var dest = this.resolvedProperty;
		for (var i = 0, n = dest.length; i != n; ++i) {
			dest[i] = buffer[offset++];
		}
		this.targetObject.needsUpdate = true;
	}

	static public function getPropertyBinding__setValue_array_setMatrixWorldNeedsUpdate(this:PropertyBinding, buffer:Array<Float>, offset:Int):Void {
		var dest = this.resolvedProperty;
		for (var i = 0, n = dest.length; i != n; ++i) {
			dest[i] = buffer[offset++];
		}
		this.targetObject.matrixWorldNeedsUpdate = true;
	}

	static public function getPropertyBinding__setValue_arrayElement(this:PropertyBinding, buffer:Array<Float>, offset:Int):Void {
		this.resolvedProperty[this.propertyIndex] = buffer[offset];
	}

	static public function getPropertyBinding__setValue_arrayElement_setNeedsUpdate(this:PropertyBinding, buffer:Array<Float>, offset:Int):Void {
		this.resolvedProperty[this.propertyIndex] = buffer[offset];
		this.targetObject.needsUpdate = true;
	}

	static public function getPropertyBinding__setValue_arrayElement_setMatrixWorldNeedsUpdate(this:PropertyBinding, buffer:Array<Float>, offset:Int):Void {
		this.resolvedProperty[this.propertyIndex] = buffer[offset];
		this.targetObject.matrixWorldNeedsUpdate = true;
	}

	static public function getPropertyBinding__setValue_fromArray(this:PropertyBinding, buffer:Array<Float>, offset:Int):Void {
		this.resolvedProperty.fromArray(buffer, offset);
	}

	static public function getPropertyBinding__setValue_fromArray_setNeedsUpdate(this:PropertyBinding, buffer:Array<Float>, offset:Int):Void {
		this.resolvedProperty.fromArray(buffer, offset);
		this.targetObject.needsUpdate = true;
	}

	static public function getPropertyBinding__setValue_fromArray_setMatrixWorldNeedsUpdate(this:PropertyBinding, buffer:Array<Float>, offset:Int):Void {
		this.resolvedProperty.fromArray(buffer, offset);
		this.targetObject.matrixWorldNeedsUpdate = true;
	}

	public static function main():Void {
		init();
	}
}

typedef ParsedPath = {
	nodeName:String,
	objectName:String,
	objectIndex:String,
	propertyName:String,
	propertyIndex:String
};