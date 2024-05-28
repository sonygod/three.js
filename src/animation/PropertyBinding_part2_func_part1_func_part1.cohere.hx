class PropertyBinding {
    public var path:String;
    public var parsedPath:Dynamic;
    public var node:Dynamic;
    public var rootNode:Dynamic;
    public var getValue:Dynamic;
    public var setValue:Dynamic;

    public function new(rootNode:Dynamic, path:String, parsedPath:Dynamic) {
        this.path = path;
        this.parsedPath = parsedPath || PropertyBinding.parseTrackName(path);
        this.node = PropertyBinding.findNode(rootNode, this.parsedPath.nodeName);
        this.rootNode = rootNode;
        this.getValue = this._getValue_unbound;
        this.setValue = this._setValue_unbound;
    }

    public static function create(root:Dynamic, path:String, parsedPath:Dynamic):PropertyBinding {
        if (! (root && root.isAnimationObjectGroup)) {
            return new PropertyBinding(root, path, parsedPath);
        } else {
            return new PropertyBinding.Composite(root, path, parsedPath);
        }
    }

    public static function sanitizeNodeName(name:String):String {
        return name.replace(/\s/g, '_').replace(_reservedRe, '');
    }

    public static function parseTrackName(trackName:String):Dynamic {
        var matches = _trackRe.exec(trackName);
        if (matches == null) {
            throw new Error('PropertyBinding: Cannot parse trackName: ' + trackName);
        }

        var results = { nodeName: matches[2], objectName: matches[3], objectIndex: matches[4], propertyName: matches[5], propertyIndex: matches[6] };

        var lastDot = results.nodeName.lastIndexOf('.');
        if (lastDot != -1) {
            var objectName = results.nodeName.substring(lastDot + 1);
            if (_supportedObjectNames.indexOf(objectName) != -1) {
                results.nodeName = results.nodeName.substring(0, lastDot);
                results.objectName = objectName;
            }
        }

        if (results.propertyName == null || results.propertyName == "") {
            throw new Error('PropertyBinding: can not parse propertyName from trackName: ' + trackName);
        }

        return results;
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
            function searchNodeSubtree(children:Array<Dynamic>):Dynamic {
                for (child in children) {
                    if (child.name == nodeName || child.uuid == nodeName) {
                        return child;
                    }
                    var result = searchNodeSubtree(child.children);
                    if (result != null) {
                        return result;
                    }
                }
                return null;
            }

            var subTreeNode = searchNodeSubtree(root.children);
            if (subTreeNode != null) {
                return subTreeNode;
            }
        }

        return null;
    }

    private function _getValue_unavailable() {}
    private function _setValue_unavailable() {}
    private function _getValue_direct(buffer:Array<Int>, offset:Int) {
        buffer[offset] = this.targetObject[this.propertyName];
    }
    private function _getValue_array(buffer:Array<Int>, offset:Int) {
        var source = this.resolvedProperty;
        for (i in 0...source.length) {
            buffer[offset++] = source[i];
        }
    }
    private function _getValue_arrayElement(buffer:Array<Int>, offset:Int) {
        buffer[offset] = this.resolvedProperty[this.propertyIndex];
    }
    private function _getValue_toArray(buffer:Array<Int>, offset:Int) {
        this.resolvedProperty.toArray(buffer, offset);
    }
    private function _setValue_direct(buffer:Array<Int>, offset:Int) {
        this.targetObject[this.propertyName] = buffer[offset];
    }
    private function _setValue_direct_setNeedsUpdate(buffer:Array<Int>, offset:Int) {
        this.targetObject[this.propertyName] = buffer[offset];
        this.targetObject.needsUpdate = true;
    }
    private function _setValue_direct_setMatrixWorldNeedsUpdate(buffer:Array<Int>, offset:Int) {
        this.targetObject[this.propertyName] = buffer[offset];
        this.targetObject.matrixWorldNeedsUpdate = true;
    }
    private function _setValue_array(buffer:Array<Int>, offset:Int) {
        var dest = this.resolvedProperty;
        for (i in 0...dest.length) {
            dest[i] = buffer[offset++];
        }
    }
    private function _setValue_array_setNeedsUpdate(buffer:Array<Int>, offset:Int) {
        var dest = this.resolvedProperty;
        for (i in 0...dest.length) {
            dest[i] = buffer[offset++];
        }
        this.targetObject.needsUpdate = true;
    }
    private function _setValue_array_setMatrixWorldNeedsUpdate(buffer:Array<Int>, offset:Int) {
        var dest = this.resolvedProperty;
        for (i in 0...dest.length) {
            dest[i] = buffer[offset++];
        }
        this.targetObject.matrixWorldNeedsUpdate = true;
    }
    private function _setValue_arrayElement(buffer:Array<Int>, offset:Int) {
        this.resolvedProperty[this.propertyIndex] = buffer[offset];
    }
    private function _setValue_arrayElement_setNeedsUpdate(buffer:Array<Int>, offset:Int) {
        this.resolvedProperty[this.propertyIndex] = buffer[offset];
        this.targetObject.needsUpdate = true;
    }
    private function _setValue_arrayElement_setMatrixWorldNeedsUpdate(buffer:Array<Int>, offset:Int) {
        this.resolvedProperty[this.propertyIndex] = buffer[offset];
        this.targetObject.matrixWorldNeedsUpdate = true;
    }
    private function _setValue_fromArray(buffer:Array<Int>, offset:Int) {
        this.resolvedProperty.fromArray(buffer, offset);
    }
    private function _setValue_fromArray_setNeedsUpdate(buffer:Array<Int>, offset:Int) {
        this.resolvedProperty.fromArray(buffer, offset);
        this.targetObject.needsUpdate = true;
    }
    private function _setValue_fromArray_setMatrixWorldNeedsUpdate(buffer:Array<Int>, offset:Int) {
        this.resolvedProperty.fromArray(buffer, offset);
        this.targetObject.matrixWorldNeedsUpdate = true;
    }
    private function _getValue_unbound(targetArray:Array<Int>, offset:Int) {
        this.bind();
        this.getValue(targetArray, offset);
    }
    private function _setValue_unbound(sourceArray:Array<Int>, offset:Int) {
        this.bind();
        this.setValue(sourceArray, offset);
    }
    private function bind() {
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
                        throw new Error("THREE.PropertyBinding: Can not bind to material as node does not have a material.");
                    }
                    if (targetObject.material.materials == null) {
                        throw new Error("THREE.PropertyBinding: Can not bind to material.materials as node.material does not have a materials array.");
                    }
                    targetObject = targetObject.material.materials;
                    break;

                case "bones":
                    if (targetObject.skeleton == null) {
                        throw new Error("THREE.PropertyBinding: Can not bind to bones as node does not have a skeleton.");
                    }
                    targetObject = targetObject.skeleton.bones;
                    break;

                case "map":
                    if ("map" in targetObject) {
                        targetObject = targetObject.map;
                        break;
                    }
                    if (targetObject.material == null) {
                        throw new Error("THREE.PropertyBinding: Can not bind to material as node does not have a material.");
                    }
                    if (targetObject.material.map == null) {
                        throw new Error("THREE.PropertyBinding: Can not bind to material.map as node.material does not have a map.");
                    }
                    targetObject = targetObject.material.map;
                    break;

                default:
                    if (targetObject[objectName] == null) {
                        throw new Error("THREE.PropertyBinding: Can not bind to objectName of node undefined.");
                    }
                    targetObject = targetObject[objectName];
            }

            if (objectIndex != null) {
                if (targetObject[objectIndex] == null) {
                    throw new Error("THREE.PropertyBinding: Trying to bind to objectIndex of objectName, but is undefined.");
                }
                targetObject = targetObject[objectIndex];
            }
        }

        var nodeProperty = targetObject[propertyName];
        if (nodeProperty == null) {
            throw new Error("THREE.PropertyBinding: Trying to update property for track: " + parsedPath.nodeName + "." + propertyName + " but it wasn't found.");
        }

        var versioning = this.Versioning.None;
        this.targetObject = targetObject;

        if ("needsUpdate" in targetObject) {
            versioning = this.Versioning.NeedsUpdate;
        } else if ("matrixWorldNeedsUpdate" in targetObject) {
            versioning = this.Versioning.MatrixWorldNeedsUpdate;
        }

        var bindingType = this.BindingType.Direct;

        if (propertyIndex != null) {
            bindingType = this.BindingType.ArrayElement;
            this.resolvedProperty = nodeProperty;
            this.propertyIndex = propertyIndex;
        } else if ("fromArray" in nodeProperty && "toArray" in nodeProperty) {
            bindingType = this.BindingType.HasFromToArray;
            this.resolvedProperty = nodeProperty;
        } else if (nodeProperty instanceof Array) {
            bindingType = this.BindingType.EntireArray;
            this.resolvedProperty = nodeProperty;
        } else {
            this.propertyName = propertyName;
        }

        this.getValue = this.GetterByBindingType[bindingType];
        this.setValue = this.SetterByBindingTypeAndVersioning[bindingType][versioning];
    }

    private function unbind() {
        this.node = null;
        this.getValue = this._getValue_unbound;
        this.setValue = this._setValue_unbound;
    }
}