class PropertyBinding {

	public var path:String;
	public var parsedPath:Dynamic;
	public var node:Dynamic;
	public var rootNode:Dynamic;

	public var getValue:Dynamic;
	public var setValue:Dynamic;

	public function new(rootNode:Dynamic, path:String, parsedPath:Dynamic) {
		this.path = path;
		this.parsedPath = parsedPath != null ? parsedPath : PropertyBinding.parseTrackName(path);
		this.node = PropertyBinding.findNode(rootNode, this.parsedPath.nodeName);
		this.rootNode = rootNode;

		// initial state of these methods that calls 'bind'
		this.getValue = this._getValue_unbound;
		this.setValue = this._setValue_unbound;
	}

	static public function create(root:Dynamic, path:String, parsedPath:Dynamic):PropertyBinding {
		if (root != null && root.isAnimationObjectGroup) {
			return new PropertyBinding.Composite(root, path, parsedPath);
		} else {
			return new PropertyBinding(root, path, parsedPath);
		}
	}

	static public function sanitizeNodeName(name:String):String {
		return name.replace(RegExp.quote("\\s"), "_").replace(_reservedRe, "");
	}

	static public function parseTrackName(trackName:String):Dynamic {
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

		var lastDot = results.nodeName != null ? results.nodeName.lastIndexOf(".") : undefined;
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

	static public function findNode(root:Dynamic, nodeName:String):Dynamic {
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

	private function _getValue_unavailable() {}
	private function _setValue_unavailable() {}
	private function _getValue_direct(buffer:Array<Float>, offset:Int) {
		buffer[offset] = this.targetObject[this.propertyName];
	}
	private function _getValue_array(buffer:Array<Float>, offset:Int) {
		var source = this.resolvedProperty;
		for (var i = 0; i < source.length; i++) {
			buffer[offset++] = source[i];
		}
	}
	private function _getValue_arrayElement(buffer:Array<Float>, offset:Int) {
		buffer[offset] = this.resolvedProperty[this.propertyIndex];
	}
	private function _getValue_toArray(buffer:Array<Float>, offset:Int) {
		this.resolvedProperty.toArray(buffer, offset);
	}
	private function _setValue_direct(buffer:Array<Float>, offset:Int) {
		this.targetObject[this.propertyName] = buffer[offset];
	}
	private function _setValue_direct_setNeedsUpdate(buffer:Array<Float>, offset:Int) {
		this.targetObject[this.propertyName] = buffer[offset];
		this.targetObject.needsUpdate = true;
	}
	private function _setValue_direct_setMatrixWorldNeedsUpdate(buffer:Array<Float>, offset:Int) {
		this.targetObject[this.propertyName] = buffer[offset];
		this.targetObject.matrixWorldNeedsUpdate = true;
	}
	private function _setValue_array(buffer:Array<Float>, offset:Int) {
		var dest = this.resolvedProperty;
		for (var i = 0; i < dest.length; i++) {
			dest[i] = buffer[offset++];
		}
	}
	private function _setValue_array_setNeedsUpdate(buffer:Array<Float>, offset:Int) {
		var dest = this.resolvedProperty;
		for (var i = 0; i < dest.length; i++) {
			dest[i] = buffer[offset++];
		}

		this.targetObject.needsUpdate = true;
	}
	private function _setValue_array_setMatrixWorldNeedsUpdate(buffer:Array<Float>, offset:Int) {
		var dest = this.resolvedProperty;
		for (var i = 0; i < dest.length; i++) {
			dest[i] = buffer[offset++];
		}

		this.targetObject.matrixWorldNeedsUpdate = true;
	}
	private function _setValue_arrayElement(buffer:Array<Float>, offset:Int) {
		this.resolvedProperty[this.propertyIndex] = buffer[offset];
	}
	private function _setValue_arrayElement_setNeedsUpdate(buffer:Array<Float>, offset:Int) {
		this.resolvedProperty[this.propertyIndex] = buffer[offset];
		this.targetObject.needsUpdate = true;
	}
	private function _setValue_arrayElement_setMatrixWorldNeedsUpdate(buffer:Array<Float>, offset:Int) {
		this.resolvedProperty[this.propertyIndex] = buffer[offset];
		this.targetObject.matrixWorldNeedsUpdate = true;
	}
	private function _setValue_fromArray(buffer:Array<Float>, offset:Int) {
		this.resolvedProperty.fromArray(buffer, offset);
	}
	private function _setValue_fromArray_setNeedsUpdate(buffer:Array<Float>, offset:Int) {
		this.resolvedProperty.fromArray(buffer, offset);
		this.targetObject.needsUpdate = true;
	}
	private function _setValue_fromArray_setMatrixWorldNeedsUpdate(buffer:Array<Float>, offset:Int) {
		this.resolvedProperty.fromArray(buffer, offset);
		this.targetObject.matrixWorldNeedsUpdate = true;
	}
	private function _getValue_unbound(targetArray:Array<Float>, offset:Int) {
		this.bind();
		this.getValue(targetArray, offset);
	}
	private function _setValue_unbound(sourceArray:Array<Float>, offset:Int) {
		this.bind();
		this.setValue(sourceArray, offset);
	}

	public function bind() {
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
			console.error("THREE.PropertyBinding: Trying to update property for track: " + nodeName +
				"." + propertyName + " but it wasn't found.", targetObject);
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
		} else if (Std.is(nodeProperty, Array)) {
			bindingType = this.BindingType.EntireArray;
			this.resolvedProperty = nodeProperty;
		} else {
			this.propertyName = propertyName;
		}

		// select getter / setter
		this.getValue = this.GetterByBindingType[bindingType];
		this.setValue = this.SetterByBindingTypeAndVersioning[bindingType][versioning];
	}

	public function unbind() {
		this.node = null;
		// back to the prototype version of getValue / setValue
		// note: avoiding to mutate the shape of 'this' via 'delete'
		this.getValue = this._getValue_unbound;
		this.setValue = this._setValue_unbound;
	}

	public enum BindingType {
		Direct;
		ArrayElement;
		EntireArray;
		HasFromToArray;
	}

	public enum Versioning {
		None;
		NeedsUpdate;
		MatrixWorldNeedsUpdate;
	}

	private static var _reservedRe = RegExp.quote("[\\[\]\\.,\\/ \\t\\r\\n]");
	private static var _trackRe = RegExp.quote("^(?:(?:[\\w\\.]+)?\\.)?(?:([\\w\\.]+)?\\.)?([\\w]+)?(?:\\.([\\w]+))?(?:\\.(\\w+))?(?:\\.([\\d]+))?$");
	private static var _supportedObjectNames = ["materials", "bones", "map"];

	private var targetObject:Dynamic;
	private var propertyName:String;
	private var propertyIndex:Int;
	private var resolvedProperty:Dynamic;

	private static var GetterByBindingType = {
		Direct: _getValue_direct,
		ArrayElement: _getValue_arrayElement,
		EntireArray: _getValue_array,
		HasFromToArray: _getValue_toArray
	};

	private static var SetterByBindingTypeAndVersioning = {
		Direct: {
			None: _setValue_direct,
			NeedsUpdate: _setValue_direct_setNeedsUpdate,
			MatrixWorldNeedsUpdate: _setValue_direct_setMatrixWorldNeedsUpdate
		},
		ArrayElement: {
			None: _setValue_arrayElement,
			NeedsUpdate: _setValue_arrayElement_setNeedsUpdate,
			MatrixWorldNeedsUpdate: _setValue_arrayElement_setMatrixWorldNeedsUpdate
		},
		EntireArray: {
			None: _setValue_array,
			NeedsUpdate: _setValue_array_setNeedsUpdate,
			MatrixWorldNeedsUpdate: _setValue_array_setMatrixWorldNeedsUpdate
		},
		HasFromToArray: {
			None: _setValue_fromArray,
			NeedsUpdate: _setValue_fromArray_setNeedsUpdate,
			MatrixWorldNeedsUpdate: _setValue_fromArray_setMatrixWorldNeedsUpdate
		}
	};

	public static class Composite extends PropertyBinding {
		public function new(rootNode:Dynamic, path:String, parsedPath:Dynamic) {
			super(rootNode, path, parsedPath);
		}
	}

}