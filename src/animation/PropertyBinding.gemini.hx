import three.AnimationObjectGroup;

class PropertyBinding {
	
	public var path:String;
	public var parsedPath:ParsedTrackName;
	public var node:Dynamic;
	public var rootNode:Dynamic;
	
	public var getValue:Dynamic = _getValue_unbound;
	public var setValue:Dynamic = _setValue_unbound;
	
	public function new(rootNode:Dynamic, path:String, parsedPath:ParsedTrackName) {
		this.path = path;
		this.parsedPath = parsedPath != null ? parsedPath : PropertyBinding.parseTrackName(path);
		this.node = PropertyBinding.findNode(rootNode, this.parsedPath.nodeName);
		this.rootNode = rootNode;
	}
	
	public static function create(root:Dynamic, path:String, parsedPath:ParsedTrackName):PropertyBinding {
		if (!cast root.isAnimationObjectGroup) {
			return new PropertyBinding(root, path, parsedPath);
		} else {
			return new Composite(root, path, parsedPath);
		}
	}
	
	public static function sanitizeNodeName(name:String):String {
		return name.replace(RegExp.quote(' '), '_').replace(_reservedRe, '');
	}
	
	public static function parseTrackName(trackName:String):ParsedTrackName {
		var matches = _trackRe.exec(trackName);
		if (matches == null) {
			throw new Error("PropertyBinding: Cannot parse trackName: " + trackName);
		}
		
		return {
			nodeName: matches[2],
			objectName: matches[3],
			objectIndex: matches[4],
			propertyName: matches[5],
			propertyIndex: matches[6]
		};
	}
	
	public static function findNode(root:Dynamic, nodeName:String):Dynamic {
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
			var subTreeNode = searchNodeSubtree(root.children);
			if (subTreeNode != null) {
				return subTreeNode;
			}
		}
		
		return null;
		
		function searchNodeSubtree(children:Array<Dynamic>):Dynamic {
			for (i in 0...children.length) {
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
		}
	}
	
	public function _getValue_unavailable(_targetArray:Array<Float>, _offset:Int):Void {
	}
	
	public function _setValue_unavailable(_sourceArray:Array<Float>, _offset:Int):Void {
	}
	
	public function _getValue_direct(buffer:Array<Float>, offset:Int):Void {
		buffer[offset] = this.targetObject[this.propertyName];
	}
	
	public function _getValue_array(buffer:Array<Float>, offset:Int):Void {
		var source = this.resolvedProperty;
		for (i in 0...source.length) {
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
		for (i in 0...dest.length) {
			dest[i] = buffer[offset++];
		}
	}
	
	public function _setValue_array_setNeedsUpdate(buffer:Array<Float>, offset:Int):Void {
		var dest = this.resolvedProperty;
		for (i in 0...dest.length) {
			dest[i] = buffer[offset++];
		}
		this.targetObject.needsUpdate = true;
	}
	
	public function _setValue_array_setMatrixWorldNeedsUpdate(buffer:Array<Float>, offset:Int):Void {
		var dest = this.resolvedProperty;
		for (i in 0...dest.length) {
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
		
		this.getValue = _getValue_unavailable;
		this.setValue = _setValue_unavailable;
		
		if (targetObject == null) {
			Sys.println("THREE.PropertyBinding: No target node found for track: " + this.path + ".");
			return;
		}
		
		if (objectName != null) {
			var objectIndex = parsedPath.objectIndex;
			switch (objectName) {
				case "materials":
					if (targetObject.material == null) {
						Sys.println("THREE.PropertyBinding: Can not bind to material as node does not have a material.", this);
						return;
					}
					
					if (targetObject.material.materials == null) {
						Sys.println("THREE.PropertyBinding: Can not bind to material.materials as node.material does not have a materials array.", this);
						return;
					}
					
					targetObject = targetObject.material.materials;
					break;
				case "bones":
					if (targetObject.skeleton == null) {
						Sys.println("THREE.PropertyBinding: Can not bind to bones as node does not have a skeleton.", this);
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
						Sys.println("THREE.PropertyBinding: Can not bind to material as node does not have a material.", this);
						return;
					}
					
					if (targetObject.material.map == null) {
						Sys.println("THREE.PropertyBinding: Can not bind to material.map as node.material does not have a map.", this);
						return;
					}
					
					targetObject = targetObject.material.map;
					break;
				default:
					if (targetObject[objectName] == null) {
						Sys.println("THREE.PropertyBinding: Can not bind to objectName of node undefined.", this);
						return;
					}
					
					targetObject = targetObject[objectName];
			}
			
			if (objectIndex != null) {
				if (targetObject[objectIndex] == null) {
					Sys.println("THREE.PropertyBinding: Trying to bind to objectIndex of objectName, but is undefined.", this, targetObject);
					return;
				}
				
				targetObject = targetObject[objectIndex];
			}
		}
		
		var nodeProperty = targetObject[propertyName];
		
		if (nodeProperty == null) {
			Sys.println("THREE.PropertyBinding: Trying to update property for track: " + parsedPath.nodeName + "." + propertyName + " but it wasn't found.", targetObject);
			return;
		}
		
		var versioning = Versioning.None;
		this.targetObject = targetObject;
		if (targetObject.needsUpdate != null) {
			versioning = Versioning.NeedsUpdate;
		} else if (targetObject.matrixWorldNeedsUpdate != null) {
			versioning = Versioning.MatrixWorldNeedsUpdate;
		}
		
		var bindingType = BindingType.Direct;
		if (propertyIndex != null) {
			if (propertyName == "morphTargetInfluences") {
				if (targetObject.geometry == null) {
					Sys.println("THREE.PropertyBinding: Can not bind to morphTargetInfluences because node does not have a geometry.", this);
					return;
				}
				
				if (targetObject.geometry.morphAttributes == null) {
					Sys.println("THREE.PropertyBinding: Can not bind to morphTargetInfluences because node does not have a geometry.morphAttributes.", this);
					return;
				}
				
				if (targetObject.morphTargetDictionary[propertyIndex] != null) {
					propertyIndex = targetObject.morphTargetDictionary[propertyIndex];
				}
			}
			
			bindingType = BindingType.ArrayElement;
			this.resolvedProperty = nodeProperty;
			this.propertyIndex = propertyIndex;
		} else if (nodeProperty.fromArray != null && nodeProperty.toArray != null) {
			bindingType = BindingType.HasFromToArray;
			this.resolvedProperty = nodeProperty;
		} else if (Reflect.is(nodeProperty, Array)) {
			bindingType = BindingType.EntireArray;
			this.resolvedProperty = nodeProperty;
		} else {
			this.propertyName = propertyName;
		}
		
		this.getValue = GetterByBindingType[bindingType];
		this.setValue = SetterByBindingTypeAndVersioning[bindingType][versioning];
	}
	
	public function unbind():Void {
		this.node = null;
		this.getValue = _getValue_unbound;
		this.setValue = _setValue_unbound;
	}
	
	public static inline function _reservedRe():RegExp {
		return RegExp.quote('[\\' + _RESERVED_CHARS_RE + '\\']', 'g');
	}
	
	public static inline function _trackRe():RegExp {
		return RegExp.new("^(?:WC+[\/:])*?(WCOD+)?(?:\\.(WC+)(?:\[(.+)\])?)?\\.(WC+)(?:\[(.+)\])?$", "g", ["WC", _wordChar, "WCOD", _wordCharOrDot]);
	}
	
	public static inline function _wordChar():String {
		return '[^' + _RESERVED_CHARS_RE + ']';
	}
	
	public static inline function _wordCharOrDot():String {
		return '[^' + _RESERVED_CHARS_RE.replace('\\.', '') + ']';
	}
	
	static inline var _RESERVED_CHARS_RE:String = "\\[\\" + "]" + "\\.:\\/";
	
	public static inline var _supportedObjectNames:Array<String> = ["material", "materials", "bones", "map"];
	
	public var targetObject:Dynamic;
	public var resolvedProperty:Dynamic;
	public var propertyIndex:Int;
	public var propertyName:String;
	
	public enum BindingType {
		Direct;
		EntireArray;
		ArrayElement;
		HasFromToArray;
	}
	
	public enum Versioning {
		None;
		NeedsUpdate;
		MatrixWorldNeedsUpdate;
	}
	
	public static var GetterByBindingType:Array<Dynamic> = [
		_getValue_direct,
		_getValue_array,
		_getValue_arrayElement,
		_getValue_toArray
	];
	
	public static var SetterByBindingTypeAndVersioning:Array<Array<Dynamic>> = [
		[
			_setValue_direct,
			_setValue_direct_setNeedsUpdate,
			_setValue_direct_setMatrixWorldNeedsUpdate
		], [
			_setValue_array,
			_setValue_array_setNeedsUpdate,
			_setValue_array_setMatrixWorldNeedsUpdate
		], [
			_setValue_arrayElement,
			_setValue_arrayElement_setNeedsUpdate,
			_setValue_arrayElement_setMatrixWorldNeedsUpdate
		], [
			_setValue_fromArray,
			_setValue_fromArray_setNeedsUpdate,
			_setValue_fromArray_setMatrixWorldNeedsUpdate
		]
	];
}

typedef ParsedTrackName = {
	nodeName:String;
	objectName:String;
	objectIndex:String;
	propertyName:String;
	propertyIndex:String;
};

class Composite extends PropertyBinding {
	
	public var _targetGroup:AnimationObjectGroup;
	public var _bindings:Array<PropertyBinding>;
	
	public function new(targetGroup:AnimationObjectGroup, path:String, optionalParsedPath:ParsedTrackName) {
		super(targetGroup, path, optionalParsedPath);
		this._targetGroup = targetGroup;
		this._bindings = targetGroup.subscribe_(path, this.parsedPath);
	}
	
	public function getValue(array:Array<Float>, offset:Int):Void {
		this.bind();
		var firstValidIndex = this._targetGroup.nCachedObjects_;
		var binding = this._bindings[firstValidIndex];
		if (binding != null) {
			binding.getValue(array, offset);
		}
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