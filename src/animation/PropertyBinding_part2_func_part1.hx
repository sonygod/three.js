package three.animation;

class PropertyBinding {
    public var path:String;
    public var parsedPath:Dynamic;
    public var node:Dynamic;
    public var rootNode:Dynamic;
    public var getValue:Dynamic;
    public var setValue:Dynamic;
    public var targetObject:Dynamic;
    public var resolvedProperty:Dynamic;
    public var propertyName:String;
    public var propertyIndex:Int;

    public function new(rootNode:Dynamic, path:String, parsedPath:Dynamic) {
        this.path = path;
        this.parsedPath = parsedPath != null ? parsedPath : PropertyBinding.parseTrackName(path);

        this.node = PropertyBinding.findNode(rootNode, this.parsedPath.nodeName);

        this.rootNode = rootNode;

        // initial state of these methods that calls 'bind'
        this.getValue = _getValue_unbound;
        this.setValue = _setValue_unbound;
    }

    static public function create(root:Dynamic, path:String, parsedPath:Dynamic) {
        if (!root || !root.isAnimationObjectGroup) {
            return new PropertyBinding(root, path, parsedPath);
        } else {
            return new PropertyBinding.Composite(root, path, parsedPath);
        }
    }

    static public function sanitizeNodeName(name:String) {
        return name.replace(/\s/g, '_').replace(_reservedRe, '');
    }

    static public function parseTrackName(trackName:String) {
        var matches:Array<Dynamic> = _trackRe.exec(trackName);

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

        var lastDot:Int = results.nodeName.lastIndexOf('.');

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
            throw new Error('PropertyBinding: can not parse propertyName from trackName: ' + trackName);
        }

        return results;
    }

    static public function findNode(root:Dynamic, nodeName:String) {
        if (nodeName == null || nodeName == '' || nodeName == '.' || nodeName == -1 || nodeName == root.name || nodeName == root.uuid) {
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
            var searchNodeSubtree = function(children:Array<Dynamic>) {
                for (i in 0...children.length) {
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

    private function _getValue_unavailable() {}

    private function _setValue_unavailable() {}

    private function _getValue_direct(buffer:Array<Float>, offset:Int) {
        buffer[offset] = targetObject[propertyName];
    }

    private function _getValue_array(buffer:Array<Float>, offset:Int) {
        var source:Array<Dynamic> = resolvedProperty;

        for (i in 0...source.length) {
            buffer[offset++] = source[i];
        }
    }

    private function _getValue_arrayElement(buffer:Array<Float>, offset:Int) {
        buffer[offset] = resolvedProperty[propertyIndex];
    }

    private function _getValue_toArray(buffer:Array<Float>, offset:Int) {
        resolvedProperty.toArray(buffer, offset);
    }

    private function _setValue_direct(buffer:Array<Float>, offset:Int) {
        targetObject[propertyName] = buffer[offset];
    }

    private function _setValue_direct_setNeedsUpdate(buffer:Array<Float>, offset:Int) {
        targetObject[propertyName] = buffer[offset];
        targetObject.needsUpdate = true;
    }

    private function _setValue_direct_setMatrixWorldNeedsUpdate(buffer:Array<Float>, offset:Int) {
        targetObject[propertyName] = buffer[offset];
        targetObject.matrixWorldNeedsUpdate = true;
    }

    private function _setValue_array(buffer:Array<Float>, offset:Int) {
        var dest:Array<Dynamic> = resolvedProperty;

        for (i in 0...dest.length) {
            dest[i] = buffer[offset++];
        }
    }

    private function _setValue_array_setNeedsUpdate(buffer:Array<Float>, offset:Int) {
        var dest:Array<Dynamic> = resolvedProperty;

        for (i in 0...dest.length) {
            dest[i] = buffer[offset++];
        }

        targetObject.needsUpdate = true;
    }

    private function _setValue_array_setMatrixWorldNeedsUpdate(buffer:Array<Float>, offset:Int) {
        var dest:Array<Dynamic> = resolvedProperty;

        for (i in 0...dest.length) {
            dest[i] = buffer[offset++];
        }

        targetObject.matrixWorldNeedsUpdate = true;
    }

    private function _setValue_arrayElement(buffer:Array<Float>, offset:Int) {
        resolvedProperty[propertyIndex] = buffer[offset];
    }

    private function _setValue_arrayElement_setNeedsUpdate(buffer:Array<Float>, offset:Int) {
        resolvedProperty[propertyIndex] = buffer[offset];
        targetObject.needsUpdate = true;
    }

    private function _setValue_arrayElement_setMatrixWorldNeedsUpdate(buffer:Array<Float>, offset:Int) {
        resolvedProperty[propertyIndex] = buffer[offset];
        targetObject.matrixWorldNeedsUpdate = true;
    }

    private function _setValue_fromArray(buffer:Array<Float>, offset:Int) {
        resolvedProperty.fromArray(buffer, offset);
    }

    private function _setValue_fromArray_setNeedsUpdate(buffer:Array<Float>, offset:Int) {
        resolvedProperty.fromArray(buffer, offset);
        targetObject.needsUpdate = true;
    }

    private function _setValue_fromArray_setMatrixWorldNeedsUpdate(buffer:Array<Float>, offset:Int) {
        resolvedProperty.fromArray(buffer, offset);
        targetObject.matrixWorldNeedsUpdate = true;
    }

    private function _getValue_unbound(targetArray:Array<Float>, offset:Int) {
        bind();
        getValue(targetArray, offset);
    }

    private function _setValue_unbound(sourceArray:Array<Float>, offset:Int) {
        bind();
        setValue(sourceArray, offset);
    }

    public function bind() {
        var targetObject:Dynamic = node;
        var parsedPath:Dynamic = parsedPath;

        var objectName:String = parsedPath.objectName;
        var propertyName:String = parsedPath.propertyName;
        var propertyIndex:Int = parsedPath.propertyIndex;

        if (targetObject == null) {
            targetObject = PropertyBinding.findNode(rootNode, parsedPath.nodeName);

            node = targetObject;
        }

        // set fail state so we can just 'return' on error
        getValue = _getValue_unavailable;
        setValue = _setValue_unavailable;

        // ensure there is a value node
        if (targetObject == null) {
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
                    if (targetObject[objectName] == null) {
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
            var nodeName:String = parsedPath.nodeName;

            console.error('THREE.PropertyBinding: Trying to update property for track: ' + nodeName +
                '.' + propertyName + ' but it wasn\'t found.', targetObject);
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
        var bindingType:Int;

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

    public function unbind() {
        node = null;

        // back to the prototype version of getValue / setValue
        // note: avoiding to mutate the shape of 'this' via 'delete'
        getValue = _getValue_unbound;
        setValue = _setValue_unbound;
    }
}