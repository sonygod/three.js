class PropertyBinding {

	var path:String;
	var parsedPath:Dynamic;
	var node:Dynamic;
	var rootNode:Dynamic;
	var getValue:Dynamic;
	var setValue:Dynamic;

	public function new(rootNode:Dynamic, path:String, parsedPath:Dynamic) {
		this.path = path;
		this.parsedPath = parsedPath || PropertyBinding.parseTrackName(path);
		this.node = PropertyBinding.findNode(rootNode, this.parsedPath.nodeName);
		this.rootNode = rootNode;
		this.getValue = this._getValue_unbound;
		this.setValue = this._setValue_unbound;
	}

	static function create(root:Dynamic, path:String, parsedPath:Dynamic):PropertyBinding {
		if (!(root && root.isAnimationObjectGroup)) {
			return new PropertyBinding(root, path, parsedPath);
		} else {
			return new PropertyBinding.Composite(root, path, parsedPath);
		}
	}

	static function sanitizeNodeName(name:String):String {
		return name.replace(/\s/g, '_').replace(_reservedRe, '');
	}

	static function parseTrackName(trackName:String):Dynamic {
		var matches = _trackRe.exec(trackName);
		if (matches === null) {
			throw 'PropertyBinding: Cannot parse trackName: ' + trackName;
		}
		var results = {
			nodeName: matches[2],
			objectName: matches[3],
			objectIndex: matches[4],
			propertyName: matches[5],
			propertyIndex: matches[6]
		};
		var lastDot = results.nodeName && results.nodeName.lastIndexOf('.');
		if (lastDot !== undefined && lastDot !== -1) {
			var objectName = results.nodeName.substring(lastDot + 1);
			if (_supportedObjectNames.indexOf(objectName) !== -1) {
				results.nodeName = results.nodeName.substring(0, lastDot);
				results.objectName = objectName;
			}
		}
		if (results.propertyName === null || results.propertyName.length === 0) {
			throw 'PropertyBinding: can not parse propertyName from trackName: ' + trackName;
		}
		return results;
	}

	static function findNode(root:Dynamic, nodeName:String):Dynamic {
		if (nodeName === undefined || nodeName === '' || nodeName === '.' || nodeName === -1 || nodeName === root.name || nodeName === root.uuid) {
			return root;
		}
		if (root.skeleton) {
			var bone = root.skeleton.getBoneByName(nodeName);
			if (bone !== undefined) {
				return bone;
			}
		}
		if (root.children) {
			var searchNodeSubtree = function(children:Array<Dynamic>) {
				for (i in children) {
					var childNode = children[i];
					if (childNode.name === nodeName || childNode.uuid === nodeName) {
						return childNode;
					}
					var result = searchNodeSubtree(childNode.children);
					if (result) return result;
				}
				return null;
			};
			var subTreeNode = searchNodeSubtree(root.children);
			if (subTreeNode) {
				return subTreeNode;
			}
		}
		return null;
	}

	function _getValue_unavailable():Void {}
	function _setValue_unavailable():Void {}
	function _getValue_direct(buffer:Array<Dynamic>, offset:Int):Void {
		buffer[offset] = this.targetObject[this.propertyName];
	}
	function _getValue_array(buffer:Array<Dynamic>, offset:Int):Void {
		var source = this.resolvedProperty;
		for (i in source) {
			buffer[offset++] = source[i];
		}
	}
	function _getValue_arrayElement(buffer:Array<Dynamic>, offset:Int):Void {
		buffer[offset] = this.resolvedProperty[this.propertyIndex];
	}
	function _getValue_toArray(buffer:Array<Dynamic>, offset:Int):Void {
		this.resolvedProperty.toArray(buffer, offset);
	}
	function _setValue_direct(buffer:Array<Dynamic>, offset:Int):Void {
		this.targetObject[this.propertyName] = buffer[offset];
	}
	function _setValue_direct_setNeedsUpdate(buffer:Array<Dynamic>, offset:Int):Void {
		this.targetObject[this.propertyName] = buffer[offset];
		this.targetObject.needsUpdate = true;
	}
	function _setValue_direct_setMatrixWorldNeedsUpdate(buffer:Array<Dynamic>, offset:Int):Void {
		this.targetObject[this.propertyName] = buffer[offset];
		this.targetObject.matrixWorldNeedsUpdate = true;
	}
	function _setValue_array(buffer:Array<Dynamic>, offset:Int):Void {
		var dest = this.resolvedProperty;
		for (i in dest) {
			dest[i] = buffer[offset++];
		}
	}
	function _setValue_array_setNeedsUpdate(buffer:Array<Dynamic>, offset:Int):Void {
		var dest = this.resolvedProperty;
		for (i in dest) {
			dest[i] = buffer[offset++];
		}
		this.targetObject.needsUpdate = true;
	}
	function _setValue_array_setMatrixWorldNeedsUpdate(buffer:Array<Dynamic>, offset:Int):Void {
		var dest = this.resolvedProperty;
		for (i in dest) {
			dest[i] = buffer[offset++];
		}
		this.targetObject.matrixWorldNeedsUpdate = true;
	}
	function _setValue_arrayElement(buffer:Array<Dynamic>, offset:Int):Void {
		this.resolvedProperty[this.propertyIndex] = buffer[offset];
	}
	function _setValue_arrayElement_setNeedsUpdate(buffer:Array<Dynamic>, offset:Int):Void {
		this.resolvedProperty[this.propertyIndex] = buffer[offset];
		this.targetObject.needsUpdate = true;
	}
	function _setValue_arrayElement_setMatrixWorldNeedsUpdate(buffer:Array<Dynamic>, offset:Int):Void {
		this.resolvedProperty[this.propertyIndex] = buffer[offset];
		this.targetObject.matrixWorldNeedsUpdate = true;
	}
	function _setValue_fromArray(buffer:Array<Dynamic>, offset:Int):Void {
		this.resolvedProperty.fromArray(buffer, offset);
	}
	function _setValue_fromArray_setNeedsUpdate(buffer:Array<Dynamic>, offset:Int):Void {
		this.resolvedProperty.fromArray(buffer, offset);
		this.targetObject.needsUpdate = true;
	}
	function _setValue_fromArray_setMatrixWorldNeedsUpdate(buffer:Array<Dynamic>, offset:Int):Void {
		this.resolvedProperty.fromArray(buffer, offset);
		this.targetObject.matrixWorldNeedsUpdate = true;
	}
	function _getValue_unbound(targetArray:Array<Dynamic>, offset:Int):Void {
		this.bind();
		this.getValue(targetArray, offset);
	}
	function _setValue_unbound(sourceArray:Array<Dynamic>, offset:Int):Void {
		this.bind();
		this.setValue(sourceArray, offset);
	}
	function bind():Void {
		var targetObject = this.node;
		var parsedPath = this.parsedPath;
		var objectName = parsedPath.objectName;
		var propertyName = parsedPath.propertyName;
		var propertyIndex = parsedPath.propertyIndex;
		if (!targetObject) {
			targetObject = PropertyBinding.findNode(this.rootNode, parsedPath.nodeName);
			this.node = targetObject;
		}
		this.getValue = this._getValue_unavailable;
		this.setValue = this._setValue_unavailable;
		if (!targetObject) {
			trace('THREE.PropertyBinding: No target node found for track: ' + this.path + '.');
			return;
		}
		if (objectName) {
			var objectIndex = parsedPath.objectIndex;
			switch (objectName) {
				case 'materials':
					if (!targetObject.material) {
						trace('THREE.PropertyBinding: Can not bind to material as node does not have a material.', this);
						return;
					}
					if (!targetObject.material.materials) {
						trace('THREE.PropertyBinding: Can not bind to material.materials as node.material does not have a materials array.', this);
						return;
					}
					targetObject = targetObject.material.materials;
					break;
				case 'bones':
					if (!targetObject.skeleton) {
						trace('THREE.PropertyBinding: Can not bind to bones as node does not have a skeleton.', this);
						return;
					}
					targetObject = targetObject.skeleton.bones;
					if (targetObject.skeleton.bones[objectIndex] !== undefined) {
						objectIndex = targetObject.skeleton.bones[objectIndex];
					}
					break;
				case 'map':
					if ('map' in targetObject) {
						targetObject = targetObject.map;
						break;
					}
					if (!targetObject.material) {
						trace('THREE.PropertyBinding: Can not bind to material as node does not have a material.', this);
						return;
					}
					if (!targetObject.material.map) {
						trace('THREE.PropertyBinding: Can not bind to material.map as node.material does not have a map.', this);
						return;
					}
					targetObject = targetObject.material.map;
					break;
				default:
					if (targetObject[objectName] === undefined) {
						trace('THREE.PropertyBinding: Can not bind to objectName of node undefined.', this);
						return;
					}
					targetObject = targetObject[objectName];
			}
			if (objectIndex !== undefined) {
				if (targetObject[objectIndex] === undefined) {
					trace('THREE.PropertyBinding: Trying to bind to objectIndex of objectName, but is undefined.', this, targetObject);
					return;
				}
				targetObject = targetObject[objectIndex];
			}
		}
		var nodeProperty = targetObject[propertyName];
		if (nodeProperty === undefined) {
			var nodeName = parsedPath.nodeName;
			trace('THREE.PropertyBinding: Trying to update property for track: ' + nodeName + '.' + propertyName + ' but it wasn\'t found.', targetObject);
			return;
		}
		var versioning = this.Versioning.None;
		this.targetObject = targetObject;
		if (targetObject.needsUpdate !== undefined) {
			versioning = this.Versioning.NeedsUpdate;
		} else if (targetObject.matrixWorldNeedsUpdate !== undefined) {
			versioning = this.Versioning.MatrixWorldNeedsUpdate;
		}
		var bindingType = this.BindingType.Direct;
		if (propertyIndex !== undefined) {
			if (propertyName === 'morphTargetInfluences') {
				if (!targetObject.geometry) {
					trace('THREE.PropertyBinding: Can not bind to morphTargetInfluences because node does not have a geometry.', this);
					return;
				}
				if (!targetObject.geometry.morphAttributes) {
					trace('THREE.PropertyBinding: Can not bind to morphTargetInfluences because node does not have a geometry.morphAttributes.', this);
					return;
				}
				if (targetObject.morphTargetDictionary[propertyIndex] !== undefined) {
					propertyIndex = targetObject.morphTargetDictionary[propertyIndex];
				}
			}
			bindingType = this.BindingType.ArrayElement;
			this.resolvedProperty = nodeProperty;
			this.propertyIndex = propertyIndex;
		} else if (nodeProperty.fromArray !== undefined && nodeProperty.toArray !== undefined) {
			bindingType = this.BindingType.HasFromToArray;
			this.resolvedProperty = nodeProperty;
		} else if (Array.isArray(nodeProperty)) {
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