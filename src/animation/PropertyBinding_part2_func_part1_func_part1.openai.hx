package three.animation;

import three.animation.PropertyBinding;

class PropertyBinding {

    public var path:String;
    public var parsedPath:Dynamic;
    public var node:Dynamic;
    public var rootNode:Dynamic;
    public var getValue:Dynamic;
    public var setValue:Dynamic;
    public var targetObject:Dynamic;
    public var resolvedProperty:Dynamic;
    public var propertyIndex:Int;
    public var propertyName:String;

    public function new(rootNode:Dynamic, path:String, parsedPath:Dynamic) {
        this.path = path;
        this.parsedPath = parsedPath != null ? parsedPath : PropertyBinding.parseTrackName(path);
        this.node = PropertyBinding.findNode(rootNode, this.parsedPath.nodeName);
        this.rootNode = rootNode;
        this.getValue = _getValue_unbound;
        this.setValue = _setValue_unbound;
    }

    static public function create(root:Dynamic, path:String, parsedPath:Dynamic):PropertyBinding {
        if (!root || !root.isAnimationObjectGroup) {
            return new PropertyBinding(root, path, parsedPath);
        } else {
            return new PropertyBinding.Composite(root, path, parsedPath);
        }
    }

    static public function sanitizeNodeName(name:String):String {
        return name.replace(/\s/g, '_').replace(_reservedRe, '');
    }

    static public function parseTrackName(trackName:String):Dynamic {
        var matches:Array<String> = _trackRe.exec(trackName);
        if (matches == null) {
            throw new Error('PropertyBinding: Cannot parse trackName: ' + trackName);
        }
        var results:Dynamic = {
            // directoryName: matches[ 1 ], // (tschw) currently unused
            nodeName: matches[2],
            objectName: matches[3],
            objectIndex: matches[4],
            propertyName: matches[5], // required
            propertyIndex: matches[6]
        };
        if (results.nodeName.lastIndexOf('.') != -1) {
            var lastDot:Int = results.nodeName.lastIndexOf('.');
            var objectName:String = results.nodeName.substring(lastDot + 1);
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

    static public function findNode(root:Dynamic, nodeName:String):Dynamic {
        if (nodeName == null || nodeName == '' || nodeName == '.' || nodeName == -1 || nodeName == root.name || nodeName == root.uuid) {
            return root;
        }
        if (root.skeleton != null) {
            var bone:Dynamic = root.skeleton.getBoneByName(nodeName);
            if (bone != null) {
                return bone;
            }
        }
        if (root.children != null) {
            var searchNodeSubtree:Dynamic = function (children:Array<Dynamic>):Dynamic {
                for (i in 0...children.length) {
                    var childNode:Dynamic = children[i];
                    if (childNode.name == nodeName || childNode.uuid == nodeName) {
                        return childNode;
                    }
                    var result:Dynamic = searchNodeSubtree(childNode.children);
                    if (result != null) {
                        return result;
                    }
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

    function _getValue_unavailable():Void {}

    function _setValue_unavailable():Void {}

    function _getValue_direct(buffer:Array<Float>, offset:Int):Void {
        buffer[offset] = targetObject[propertyName];
    }

    function _getValue_array(buffer:Array<Float>, offset:Int):Void {
        var source:Array<Float> = resolvedProperty;
        for (i in 0...source.length) {
            buffer[offset++] = source[i];
        }
    }

    function _getValue_arrayElement(buffer:Array<Float>, offset:Int):Void {
        buffer[offset] = resolvedProperty[propertyIndex];
    }

    function _getValue_toArray(buffer:Array<Float>, offset:Int):Void {
        resolvedProperty.toArray(buffer, offset);
    }

    function _setValue_direct(buffer:Array<Float>, offset:Int):Void {
        targetObject[propertyName] = buffer[offset];
    }

    function _setValue_direct_setNeedsUpdate(buffer:Array<Float>, offset:Int):Void {
        targetObject[propertyName] = buffer[offset];
        targetObject.needsUpdate = true;
    }

    function _setValue_direct_setMatrixWorldNeedsUpdate(buffer:Array<Float>, offset:Int):Void {
        targetObject[propertyName] = buffer[offset];
        targetObject.matrixWorldNeedsUpdate = true;
    }

    function _setValue_array(buffer:Array<Float>, offset:Int):Void {
        var dest:Array<Float> = resolvedProperty;
        for (i in 0...dest.length) {
            dest[i] = buffer[offset++];
        }
    }

    function _setValue_array_setNeedsUpdate(buffer:Array<Float>, offset:Int):Void {
        var dest:Array<Float> = resolvedProperty;
        for (i in 0...dest.length) {
            dest[i] = buffer[offset++];
        }
        targetObject.needsUpdate = true;
    }

    function _setValue_array_setMatrixWorldNeedsUpdate(buffer:Array<Float>, offset:Int):Void {
        var dest:Array<Float> = resolvedProperty;
        for (i in 0...dest.length) {
            dest[i] = buffer[offset++];
        }
        targetObject.matrixWorldNeedsUpdate = true;
    }

    function _setValue_arrayElement(buffer:Array<Float>, offset:Int):Void {
        resolvedProperty[propertyIndex] = buffer[offset];
    }

    function _setValue_arrayElement_setNeedsUpdate(buffer:Array_Float, offset:Int):Void {
        resolvedProperty[propertyIndex] = buffer[offset];
        targetObject.needsUpdate = true;
    }

    function _setValue_arrayElement_setMatrixWorldNeedsUpdate(buffer:Array<Float>, offset:Int):Void {
        resolvedProperty[propertyIndex] = buffer[offset];
        targetObject.matrixWorldNeedsUpdate = true;
    }

    function _setValue_fromArray(buffer:Array<Float>, offset:Int):Void {
        resolvedProperty.fromArray(buffer, offset);
    }

    function _setValue_fromArray_setNeedsUpdate(buffer:Array<Float>, offset:Int):Void {
        resolvedProperty.fromArray(buffer, offset);
        targetObject.needsUpdate = true;
    }

    function _setValue_fromArray_setMatrixWorldNeedsUpdate(buffer:Array<Float>, offset:Int):Void {
        resolvedProperty.fromArray(buffer, offset);
        targetObject.matrixWorldNeedsUpdate = true;
    }

    function _getValue_unbound(targetArray:Array<Float>, offset:Int):Void {
        bind();
        getValue(targetArray, offset);
    }

    function _setValue_unbound(sourceArray:Array<Float>, offset:Int):Void {
        bind();
        setValue(sourceArray, offset);
    }

    function bind():Void {
        var targetObject:Dynamic = node;
        var parsedPath:Dynamic = parsedPath;
        var objectName:String = parsedPath.objectName;
        var propertyName:String = parsedPath.propertyName;
        var propertyIndex:Int = parsedPath.propertyIndex;

        if (!targetObject) {
            targetObject = PropertyBinding.findNode(rootNode, parsedPath.nodeName);
            node = targetObject;
        }

        // set fail state so we can just 'return' on error
        getValue = _getValue_unavailable;
        setValue = _setValue_unavailable;

        // ensure there is a value node
        if (!targetObject) {
            console.warn('THREE.PropertyBinding: No target node found for track: ' + path + '.');
            return;
        }

        if (objectName != null) {
            var objectIndex:Int = parsedPath.objectIndex;

            // special cases were we need to reach deeper into the hierarchy to get the face materials....
            switch (objectName) {
                case 'materials':
                    if (!targetObject.material) {
                        console.error('THREE.PropertyBinding: Can not bind to material as node does not have a material.', this);
                        return;
                    }
                    if (!targetObject.material.materials) {
                        console.error('THREE.PropertyBinding: Can not bind to material.materials as node.material does not have a materials array.', this);
                        return;
                    }
                    targetObject = targetObject.material.materials;
                    break;

                case 'bones':
                    if (!targetObject.skeleton) {
                        console.error('THREE.PropertyBinding: Can not bind to bones as node does not have a skeleton.', this);
                        return;
                    }
                    targetObject = targetObject.skeleton.bones;
                    if (objectIndex != null) {
                        // potential future optimization: skip this if propertyIndex is already an integer
                        // and convert the integer string to a true integer.
                        for (i in 0...targetObject.length) {
                            if (targetObject[i].name == objectIndex) {
                                objectIndex = i;
                                break;
                            }
                        }
                    }
                    break;

                case 'map':
                    if ('map' in targetObject) {
                        targetObject = targetObject.map;
                        break;
                    }
                    if (!targetObject.material) {
                        console.error('THREE.PropertyBinding: Can not bind to material as node does not have a material.', this);
                        return;
                    }
                    if (!targetObject.material.map) {
                        console.error('THREE.PropertyBinding: Can not bind to material.map as node.material does not have a map.', this);
                        return;
                    }
                    targetObject = targetObject.material.map;
                    break;

                default:
                    if (!targetObject[objectName]) {
                        console.error('THREE.PropertyBinding: Can not bind to objectName of node undefined.', this);
                        return;
                    }
                    targetObject = targetObject[objectName];
            }

            if (objectIndex != null) {
                if (targetObject[objectIndex] == null) {
                    console.error('THREE.PropertyBinding: Trying to bind to objectIndex of objectName, but is undefined.', this, targetObject);
                    return;
                }
                targetObject = targetObject[objectIndex];
            }
        }

        // resolve property
        var nodeProperty:Dynamic = targetObject[propertyName];

        if (nodeProperty == null) {
            console.error('THREE.PropertyBinding: Trying to update property for track: ' + propertyName + ' but it wasn\'t found.', targetObject);
            return;
        }

        // determine versioning scheme
        var versioning:Int = Versioning.None;

        targetObject = targetObject;

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
                    console.error('THREE.PropertyBinding: Can not bind to morphTargetInfluences because node does not have a geometry.', this);
                    return;
                }
                if (!targetObject.geometry.morphAttributes) {
                    console.error('THREE.PropertyBinding: Can not bind to morphTargetInfluences because node does not have a geometry.morphAttributes.', this);
                    return;
                }
                if (targetObject.morphTargetDictionary[propertyIndex] != null) {
                    propertyIndex = targetObject.morphTargetDictionary[propertyIndex];
                }
            }

            bindingType = BindingType.ArrayElement;
            resolvedProperty = nodeProperty;
            this.propertyIndex = propertyIndex;

        } else if (nodeProperty.fromArray != null && nodeProperty.toArray != null) {
            // must use copy for Object3D.Euler/Quaternion
            bindingType = BindingType.HasFromToArray;
            resolvedProperty = nodeProperty;
        } else if (Std.is(nodeProperty, Array)) {
            bindingType = BindingType.EntireArray;
            resolvedProperty = nodeProperty;
        } else {
            this.propertyName = propertyName;
        }

        // select getter / setter
        getValue = GetterByBindingType[bindingType];
        setValue = SetterByBindingTypeAndVersioning[bindingType][versioning];
    }

    function unbind():Void {
        node = null;
        // back to the prototype version of getValue / setValue
        // note: avoiding to mutate the shape of 'this' via 'delete'
        getValue = _getValue_unbound;
        setValue = _setValue_unbound;
    }
}