class PropertyBinding {

	var path:String;
	var parsedPath:{ nodeName:String, objectName:String, objectIndex:String, propertyName:String, propertyIndex:String };
	var node:Dynamic;
	var rootNode:Dynamic;
	var getValue:Void->Void;
	var setValue:Void->Void;

	public function new(rootNode:Dynamic, path:String, parsedPath:{ nodeName:String, objectName:String, objectIndex:String, propertyName:String, propertyIndex:String } = null) {
		this.path = path;
		this.parsedPath = parsedPath != null ? parsedPath : PropertyBinding.parseTrackName(path);
		this.node = PropertyBinding.findNode(rootNode, this.parsedPath.nodeName);
		this.rootNode = rootNode;
		this.getValue = this._getValue_unbound;
		this.setValue = this._setValue_unbound;
	}

	public static function create(root:Dynamic, path:String, parsedPath:{ nodeName:String, objectName:String, objectIndex:String, propertyName:String, propertyIndex:String }):PropertyBinding {
		if (!(root != null && Reflect.field(root, "isAnimationObjectGroup"))) {
			return new PropertyBinding(root, path, parsedPath);
		} else {
			return new PropertyBinding.Composite(root, path, parsedPath);
		}
	}

	public static function sanitizeNodeName(name:String):String {
		return name.split(" ").join("_").split(_reservedRe).join("");
	}

	public static function parseTrackName(trackName:String):{ nodeName:String, objectName:String, objectIndex:String, propertyName:String, propertyIndex:String } {
		var matches = _trackRe.match(trackName);
		if (matches == null) throw new Error("PropertyBinding: Cannot parse trackName: " + trackName);
		var results = {
			nodeName: matches[2],
			objectName: matches[3],
			objectIndex: matches[4],
			propertyName: matches[5],
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
		if (results.propertyName == null || results.propertyName.length == 0) throw new Error("PropertyBinding: can not parse propertyName from trackName: " + trackName);
		return results;
	}

	public static function findNode(root:Dynamic, nodeName:String):Dynamic {
		if (nodeName == null || nodeName == "" || nodeName == "." || nodeName == -1 || nodeName == root.name || nodeName == root.uuid) {
			return root;
		}
		if (root.skeleton != null) {
			var bone = root.skeleton.getBoneByName(nodeName);
			if (bone != null) return bone;
		}
		if (root.children != null) {
			var searchNodeSubtree = function(children:Array<Dynamic>):Dynamic {
				for (i in 0...children.length) {
					var childNode = children[i];
					if (childNode.name == nodeName || childNode.uuid == nodeName) return childNode;
					var result = searchNodeSubtree(childNode.children);
					if (result != null) return result;
				}
				return null;
			};
			var subTreeNode = searchNodeSubtree(root.children);
			if (subTreeNode != null) return subTreeNode;
		}
		return null;
	}

	function _getValue_unavailable() {}
	function _setValue_unavailable() {}
	function _getValue_direct(buffer:Array<Float>, offset:Int):Void {
		buffer[offset] = Reflect.field(this.targetObject, this.propertyName);
	}
	function _getValue_array(buffer:Array<Float>, offset:Int):Void {
		var source = this.resolvedProperty;
		for (i in 0...source.length) {
			buffer[offset++] = source[i];
		}
	}
	function _getValue_arrayElement(buffer:Array<Float>, offset:Int):Void {
		buffer[offset] = this.resolvedProperty[this.propertyIndex];
	}
	function _getValue_toArray(buffer:Array<Float>, offset:Int):Void {
		this.resolvedProperty.toArray(buffer, offset);
	}
	function _setValue_direct(buffer:Array<Float>, offset:Int):Void {
		Reflect.setField(this.targetObject, this.propertyName, buffer[offset]);
	}
	function _setValue_direct_setNeedsUpdate(buffer:Array<Float>, offset:Int):Void {
		Reflect.setField(this.targetObject, this.propertyName, buffer[offset]);
		this.targetObject.needsUpdate = true;
	}
	function _setValue_direct_setMatrixWorldNeedsUpdate(buffer:Array<Float>, offset:Int):Void {
		Reflect.setField(this.targetObject, this.propertyName, buffer[offset]);
		this.targetObject.matrixWorldNeedsUpdate = true;
	}
	function _setValue_array(buffer:Array<Float>, offset:Int):Void {
		var dest = this.resolvedProperty;
		for (i in 0...dest.length) {
			dest[i] = buffer[offset++];
		}
	}
	function _setValue_array_setNeedsUpdate(buffer:Array<Float>, offset:Int):Void {
		var dest = this.resolvedProperty;
		for (i in 0...dest.length) {
			dest[i] = buffer[offset++];
		}
		this.targetObject.needsUpdate = true;
	}
	function _setValue_array_setMatrixWorldNeedsUpdate(buffer:Array<Float>, offset:Int):Void {
		var dest = this.resolvedProperty;
		for (i in 0...dest.length) {
			dest[i] = buffer[offset++];
		}
		this.targetObject.matrixWorldNeedsUpdate = true;
	}
	function _setValue_arrayElement(buffer:Array<Float>, offset:Int):Void {
		this.resolvedProperty[this.propertyIndex] = buffer[offset];
	}
	function _setValue_arrayElement_setNeedsUpdate(buffer:Array<Float>, offset:Int):Void {
		this.resolvedProperty[this.propertyIndex] = buffer[offset];
		this.targetObject.needsUpdate = true;
	}
	function _setValue_arrayElement_setMatrixWorldNeedsUpdate(buffer:Array<Float>, offset:Int):Void {
		this.resolvedProperty[this.propertyIndex] = buffer[offset];
		this.targetObject.matrixWorldNeedsUpdate = true;
	}
	function _setValue_fromArray(buffer:Array<Float>, offset:Int):Void {
		this.resolvedProperty.fromArray(buffer, offset);
	}
	function _setValue_fromArray_setNeedsUpdate(buffer:Array<Float>, offset:Int):Void {
		this.resolvedProperty.fromArray(buffer, offset);
		this.targetObject.needsUpdate = true;
	}
	function _setValue_fromArray_setMatrixWorldNeedsUpdate(buffer:Array<Float>, offset:Int):Void {
		this.resolvedProperty.fromArray(buffer, offset);
		this.targetObject.matrixWorldNeedsUpdate = true;
	}
	function _getValue_unbound(targetArray:Array<Float>, offset:Int):Void {
		this.bind();
		this.getValue(targetArray, offset);
	}
	function _setValue_unbound(sourceArray:Array<Float>, offset:Int):Void {
		this.bind();
		this.setValue(sourceArray, offset);
	}
	function bind():Void {
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
			trace("THREE.PropertyBinding: No target node found for track: " + this.path + ".");
			return;
		}
		if (objectName != null) {
			var objectIndex = parsedPath.objectIndex;
			switch (objectName) {
				case "materials":
					if (targetObject.material == null) {
						trace("THREE.PropertyBinding: Can not bind to material as node does not have a material.", this);
						return;
					}
					if (targetObject.material.materials == null) {
						trace("THREE.PropertyBinding: Can not bind to material.materials as node.material does not have a materials array.", this);
						return;
					}
					targetObject = targetObject.material.materials;
					break;
				case "bones":
					if (targetObject.skeleton == null) {
						trace("THREE.PropertyBinding: Can not bind to bones as node does not have a skeleton.", this);
						return;
					}
					targetObject = targetObject.skeleton.bones;
					for (i in 0...targetObject.length) {
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
						trace("THREE.PropertyBinding: Can not bind to material as node does not have a material.", this);
						return;
					}
					if (targetObject.material.map == null) {
						trace("THREE.PropertyBinding: Can not bind to material.map as node.material does not have a map.", this);
						return;
					}
					targetObject = targetObject.material.map;
					break;
				default:
					if (Reflect.field(targetObject, objectName) == null) {
						trace("THREE.PropertyBinding: Can not bind to objectName of node undefined.", this);
						return;
					}
					targetObject = Reflect.field(targetObject, objectName);
			}
			if (objectIndex != null) {
				if (Reflect.field(targetObject, objectIndex) == null) {
					trace("THREE.PropertyBinding: Trying to bind to objectIndex of objectName, but is undefined.", this, targetObject);
					return;
				}
				targetObject = Reflect.field(targetObject, objectIndex);
			}
		}
		var nodeProperty = Reflect.field(targetObject, propertyName);
		if (nodeProperty == null) {
			var nodeName = parsedPath.nodeName;
			trace("THREE.PropertyBinding: Trying to update property for track: " + nodeName + "." + propertyName + " but it wasn't found.", targetObject);
			return;
		}
		var versioning = this.Versioning.None;
		this.targetObject = targetObject;
		if (Reflect.hasField(targetObject, "needsUpdate")) {
			versioning = this.Versioning.NeedsUpdate;
		} else if (Reflect.hasField(targetObject, "matrixWorldNeedsUpdate")) {
			versioning = this.Versioning.MatrixWorldNeedsUpdate;
		}
		var bindingType = this.BindingType.Direct;
		if (propertyIndex != null) {
			if (propertyName == "morphTargetInfluences") {
				if (targetObject.geometry == null) {
					trace("THREE.PropertyBinding: Can not bind to morphTargetInfluences because node does not have a geometry.", this);
					return;
				}
				if (targetObject.geometry.morphAttributes == null) {
					trace("THREE.PropertyBinding: Can not bind to morphTargetInfluences because node does not have a geometry.morphAttributes.", this);
					return;
				}
				if (Reflect.field(targetObject.morphTargetDictionary, propertyIndex) != null) {
					propertyIndex = Reflect.field(targetObject.morphTargetDictionary, propertyIndex);
				}
			}
			bindingType = this.BindingType.ArrayElement;
			this.resolvedProperty = nodeProperty;
			this.propertyIndex = propertyIndex;
		} else if (Reflect.hasField(nodeProperty, "fromArray") && Reflect.hasField(nodeProperty, "toArray")) {
			bindingType = this.BindingType.HasFromToArray;
			this.resolvedProperty = nodeProperty;
		} else if (nodeProperty instanceof Array<Float>) {
			bindingType = this.BindingType.EntireArray;
			this.resolvedProperty = nodeProperty;
		} else {
			this.propertyName = propertyName;
		}
		this.getValue = this.GetterByBindingType[bindingType];
		this.setValue = this.SetterByBindingTypeAndVersioning[bindingType][versioning];
	}

	function unbind():Void {
		this.node = null;
		this.getValue = this._getValue_unbound;
		this.setValue = this._setValue_unbound;
	}
}