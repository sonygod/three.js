package three.animation;

import haxe.ds.StringMap;

class PropertyBinding {
	static var _reservedRe:EReg = ~/[^a-zA-Z0-9_]/;
	static var _trackRe:EReg = ~/^([^\.]+)\.([^\.]+)\.([^\.]+)(?:\.([0-9]+))?$/;
	static var _supportedObjectNames:Array<String> = ["materials", "bones", "map"];

	var path:String;
	var parsedPath:ParsedPath;
	var node:Object3D;
	var rootNode:Object3D;

	var getValue:Void->Void;
	var setValue:Void->Void;

	public function new(rootNode:Object3D, path:String, parsedPath:ParsedPath = null) {
		this.path = path;
		this.parsedPath = parsedPath != null ? parsedPath : parseTrackName(path);
		this.node = findNode(rootNode, parsedPath.nodeName);
		this.rootNode = rootNode;

		// initial state of these methods that calls 'bind'
		this.getValue = _getValue_unbound;
		this.setValue = _setValue_unbound;
	}

	static public function create(root:Object3D, path:String, parsedPath:ParsedPath = null):PropertyBinding {
		if (!(root && root.isAnimationObjectGroup)) {
			return new PropertyBinding(root, path, parsedPath);
		} else {
			return new PropertyBinding.Composite(root, path, parsedPath);
		}
	}

	static public function sanitizeNodeName(name:String):String {
		return name.replace(new EReg("\\s+", "g"), "_").replace(_reservedRe, "");
	}

	static public function parseTrackName(trackName:String):ParsedPath {
		var matches:Array<String> = _trackRe.exec(trackName);
		if (matches == null) {
			throw new Error('PropertyBinding: Cannot parse trackName: ' + trackName);
		}

		var results:ParsedPath = {
			nodeName: matches[2],
			objectName: matches[3],
			objectIndex: matches[4],
			propertyName: matches[5], // required
			propertyIndex: matches[6]
		};

		if (results.nodeName != null && (lastDot = results.nodeName.lastIndexOf('.')) != -1) {
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
			throw new Error('PropertyBinding: can not parse propertyName from trackName: ' + trackName);
		}

		return results;
	}

	static public function findNode(root:Object3D, nodeName:String):Object3D {
		if (nodeName == null || nodeName == '' || nodeName == '.' || nodeName == root.name || nodeName == root.uuid) {
			return root;
		}

		// search into skeleton bones.
		if (root.skeleton != null) {
			var bone:Object3D = root.skeleton.getBoneByName(nodeName);
			if (bone != null) {
				return bone;
			}
		}

		// search into node subtree.
		if (root.children != null) {
			var searchNodeSubtree = function(children:Array<Object3D>):Object3D {
				for (child in children) {
					if (child.name == nodeName || child.uuid == nodeName) {
						return child;
					}
					var result:Object3D = searchNodeSubtree(child.children);
					if (result != null) {
						return result;
					}
				}
				return null;
			};
			var subTreeNode:Object3D = searchNodeSubtree(root.children);
			if (subTreeNode != null) {
				return subTreeNode;
			}
		}

		return null;
	}

	// these are used to "bind" a nonexistent property
	function _getValue_unavailable() {}
	function _setValue_unavailable() {}

	// Getters
	function _getValue_direct(buffer:Array<Float>, offset:Int) {
		buffer[offset] = targetObject[propertyName];
	}

	function _getValue_array(buffer:Array<Float>, offset:Int) {
		var source:Array<Float> = resolvedProperty;
		for (i in 0...source.length) {
			buffer[offset++] = source[i];
		}
	}

	function _getValue_arrayElement(buffer:Array<Float>, offset:Int) {
		buffer[offset] = resolvedProperty[propertyIndex];
	}

	function _getValue_toArray(buffer:Array<Float>, offset:Int) {
		resolvedProperty.toArray(buffer, offset);
	}

	// Direct
	function _setValue_direct(buffer:Array<Float>, offset:Int) {
		targetObject[propertyName] = buffer[offset];
	}

	function _setValue_direct_setNeedsUpdate(buffer:Array<Float>, offset:Int) {
		targetObject[propertyName] = buffer[offset];
		targetObject.needsUpdate = true;
	}

	function _setValue_direct_setMatrixWorldNeedsUpdate(buffer:Array<Float>, offset:Int) {
		targetObject[propertyName] = buffer[offset];
		targetObject.matrixWorldNeedsUpdate = true;
	}

	// EntireArray
	function _setValue_array(buffer:Array<Float>, offset:Int) {
		var dest:Array<Float> = resolvedProperty;
		for (i in 0...dest.length) {
			dest[i] = buffer[offset++];
		}
	}

	function _setValue_array_setNeedsUpdate(buffer:Array<Float>, offset:Int) {
		var dest:Array<Float> = resolvedProperty;
		for (i in 0...dest.length) {
			dest[i] = buffer[offset++];
		}
		targetObject.needsUpdate = true;
	}

	function _setValue_array_setMatrixWorldNeedsUpdate(buffer:Array<Float>, offset:Int) {
		var dest:Array<Float> = resolvedProperty;
		for (i in 0...dest.length) {
			dest[i] = buffer[offset++];
		}
		targetObject.matrixWorldNeedsUpdate = true;
	}

	// ArrayElement
	function _setValue_arrayElement(buffer:Array<Float>, offset:Int) {
		resolvedProperty[propertyIndex] = buffer[offset];
	}

	function _setValue_arrayElement_setNeedsUpdate(buffer:Array<Float>, offset:Int) {
		resolvedProperty[propertyIndex] = buffer[offset];
		targetObject.needsUpdate = true;
	}

	function _setValue_arrayElement_setMatrixWorldNeedsUpdate(buffer:Array<Float>, offset:Int) {
		resolvedProperty[propertyIndex] = buffer[offset];
		targetObject.matrixWorldNeedsUpdate = true;
	}

	// HasToFromArray
	function _setValue_fromArray(buffer:Array<Float>, offset:Int) {
		resolvedProperty.fromArray(buffer, offset);
	}

	function _setValue_fromArray_setNeedsUpdate(buffer:Array<Float>, offset:Int) {
		resolvedProperty.fromArray(buffer, offset);
		targetObject.needsUpdate = true;
	}

	function _setValue_fromArray_setMatrixWorldNeedsUpdate(buffer:Array<Float>, offset:Int) {
		resolvedProperty.fromArray(buffer, offset);
		targetObject.matrixWorldNeedsUpdate = true;
	}

	function _getValue_unbound(targetArray:Array<Float>, offset:Int) {
		bind();
		getValue(targetArray, offset);
	}

	function _setValue_unbound(sourceArray:Array<Float>, offset:Int) {
		bind();
		setValue(sourceArray, offset);
	}

	// create getter / setter pair for a property in the scene graph
	function bind() {
		var targetObject:Object3D = node;
		var parsedPath:ParsedPath = this.parsedPath;

		var objectName:String = parsedPath.objectName;
		var propertyName:String = parsedPath.propertyName;
		var propertyIndex:Int = parsedPath.propertyIndex;

		if (!targetObject) {
			targetObject = findNode(rootNode, parsedPath.nodeName);
			this.node = targetObject;
		}

		// set fail state so we can just 'return' on error
		this.getValue = _getValue_unavailable;
		this.setValue = _setValue_unavailable;

		// ensure there is a value node
		if (!targetObject) {
			trace('THREE.PropertyBinding: No target node found for track: ' + this.path + '.');
			return;
		}

		if (objectName != null) {
			var objectIndex:Int = parsedPath.objectIndex;

			// special cases were we need to reach deeper into the hierarchy to get the face materials....
			switch (objectName) {
				case 'materials':
					if (!targetObject.material) {
						trace('THREE.PropertyBinding: Can not bind to material as node does not have a material.');
						return;
					}

					if (!targetObject.material.materials) {
						trace('THREE.PropertyBinding: Can not bind to material.materials as node.material does not have a materials array.');
						return;
					}

					targetObject = targetObject.material.materials;

				case 'bones':
					if (!targetObject.skeleton) {
						trace('THREE.PropertyBinding: Can not bind to bones as node does not have a skeleton.');
						return;
					}

					// potential future optimization: skip this if propertyIndex is already an integer
					// and convert the integer string to a true integer.

					targetObject = targetObject.skeleton.bones;

					// support resolving morphTarget names into indices.
					for (i in 0...targetObject.length) {
						if (targetObject[i].name == objectIndex) {
							objectIndex = i;
							break;
						}
					}

				case 'map':
					if ('map' in targetObject) {
						targetObject = targetObject.map;
						break;
					}

					if (!targetObject.material) {
						trace('THREE.PropertyBinding: Can not bind to material as node does not have a material.');
						return;
					}

					if (!targetObject.material.map) {
						trace('THREE.PropertyBinding: Can not bind to material.map as node.material does not have a map.');
						return;
					}

					targetObject = targetObject.material.map;
					break;

				default:
					if (!(objectName in targetObject)) {
						trace('THREE.PropertyBinding: Can not bind to objectName of node undefined.');
						return;
					}

					targetObject = targetObject[objectName];

			}

			if (objectIndex != null) {
				if (!(objectIndex in targetObject)) {
					trace('THREE.PropertyBinding: Trying to bind to objectIndex of objectName, but is undefined.', targetObject);
					return;
				}

				targetObject = targetObject[objectIndex];
			}

		}

		// resolve property
		var nodeProperty:Dynamic = targetObject[propertyName];

		if (nodeProperty == null) {
			trace('THREE.PropertyBinding: Trying to update property for track: ' + parsedPath.nodeName + '.' + propertyName + ' but it wasn\'t found.', targetObject);
			return;
		}

		// determine versioning scheme
		var versioning:Int = Versioning.None;

		if (targetObject.needsUpdate != null) { // material
			versioning = Versioning.NeedsUpdate;
		} else if (targetObject.matrixWorldNeedsUpdate != null) { // node transform
			versioning = Versioning.MatrixWorldNeedsUpdate;
		}

		// determine how the property gets bound
		var bindingType:Int = BindingType.Direct;

		if (propertyIndex != null) {
			// access a sub element of the property array (only primitives are supported right now)

			if (propertyName == 'morphTargetInfluences') {
				// potential optimization, skip this if propertyIndex is already an integer, and convert the integer string to a true integer.

				// support resolving morphTarget names into indices.
				if (!targetObject.geometry) {
					trace('THREE.PropertyBinding: Can not bind to morphTargetInfluences because node does not have a geometry.');
					return;
				}

				if (!targetObject.geometry.morphAttributes) {
					trace('THREE.PropertyBinding: Can not bind to morphTargetInfluences because node does not have a geometry.morphAttributes.');
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
			// must use copy for Object3D.Euler/Quaternion

			bindingType = BindingType.HasFromToArray;

			this.resolvedProperty = nodeProperty;

		} else if (Std.is(nodeProperty, Array)) {
			bindingType = BindingType.EntireArray;

			this.resolvedProperty = nodeProperty;

		} else {
			this.propertyName = propertyName;
		}

		// select getter / setter
		this.getValue = GetterByBindingType[bindingType];
		this.setValue = SetterByBindingTypeAndVersioning[bindingType][versioning];
	}

	function unbind() {
		this.node = null;

		// back to the prototype version of getValue / setValue
		// note: avoiding to mutate the shape of 'this' via 'delete'
		this.getValue = _getValue_unbound;
		this.setValue = _setValue_unbound;
	}
}