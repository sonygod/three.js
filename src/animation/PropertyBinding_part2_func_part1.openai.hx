class PropertyBinding {

    public var path:String;
    public var parsedPath:Dynamic;
    public var node:Dynamic;
    public var rootNode:Dynamic;

    public function new(rootNode:Dynamic, path:String, parsedPath:Dynamic = null) {
        this.path = path;
        this.parsedPath = parsedPath != null ? parsedPath : PropertyBinding.parseTrackName(path);

        this.node = PropertyBinding.findNode(rootNode, this.parsedPath.nodeName);
        this.rootNode = rootNode;

        // initial state of these methods that calls 'bind'
        this.getValue = this._getValue_unbound;
        this.setValue = this._setValue_unbound;
    }

    public static function create(root:Dynamic, path:String, parsedPath:Dynamic):PropertyBinding {
        if (root != null && Reflect.hasField(root, "isAnimationObjectGroup") && Reflect.field(root, "isAnimationObjectGroup")) {
            return new CompositePropertyBinding(root, path, parsedPath);
        } else {
            return new PropertyBinding(root, path, parsedPath);
        }
    }

    public static function sanitizeNodeName(name:String):String {
        return name.split(" ").join("_").split(_reservedRe).join("");
    }

    public static function parseTrackName(trackName:String):Dynamic {
        var matches = _trackRe.match(trackName);

        if (matches == null) {
            throw "PropertyBinding: Cannot parse trackName: " + trackName;
        }

        var results = {
            nodeName: matches[2],
            objectName: matches[3],
            objectIndex: matches[4],
            propertyName: matches[5],
            propertyIndex: matches[6]
        };

        var lastDot = results.nodeName.lastIndexOf(".");
        if (lastDot >= 0) {
            var objectName = results.nodeName.substr(lastDot + 1);
            if (_supportedObjectNames.indexOf(objectName) >= 0) {
                results.nodeName = results.nodeName.substr(0, lastDot);
                results.objectName = objectName;
            }
        }

        if (results.propertyName == null || results.propertyName.length == 0) {
            throw "PropertyBinding: can not parse propertyName from trackName: " + trackName;
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
            var searchNodeSubtree = function(children:Array<Dynamic>):Dynamic {
                for (i in 0...children.length) {
                    var childNode = children[i];
                    if (childNode.name == nodeName || childNode.uuid == nodeName) {
                        return childNode;
                    }
                    var result = searchNodeSubtree(childNode.children);
                    if (result != null) return result;
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

    private function _getValue_unavailable():Void {}
    private function _setValue_unavailable():Void {}
    private function _getValue_direct(buffer:Array<Float>, offset:Int):Void {
        buffer[offset] = Reflect.field(this.targetObject, this.propertyName);
    }
    private function _getValue_array(buffer:Array<Float>, offset:Int):Void {
        var source = this.resolvedProperty;
        for (i in 0...source.length) {
            buffer[offset++] = source[i];
        }
    }
    private function _getValue_arrayElement(buffer:Array<Float>, offset:Int):Void {
        buffer[offset] = this.resolvedProperty[this.propertyIndex];
    }
    private function _getValue_toArray(buffer:Array<Float>, offset:Int):Void {
        this.resolvedProperty.toArray(buffer, offset);
    }
    private function _setValue_direct(buffer:Array<Float>, offset:Int):Void {
        Reflect.setField(this.targetObject, this.propertyName, buffer[offset]);
    }
    private function _setValue_direct_setNeedsUpdate(buffer:Array<Float>, offset:Int):Void {
        Reflect.setField(this.targetObject, this.propertyName, buffer[offset]);
        this.targetObject.needsUpdate = true;
    }
    private function _setValue_direct_setMatrixWorldNeedsUpdate(buffer:Array<Float>, offset:Int):Void {
        Reflect.setField(this.targetObject, this.propertyName, buffer[offset]);
        this.targetObject.matrixWorldNeedsUpdate = true;
    }
    private function _setValue_array(buffer:Array<Float>, offset:Int):Void {
        var dest = this.resolvedProperty;
        for (i in 0...dest.length) {
            dest[i] = buffer[offset++];
        }
    }
    private function _setValue_array_setNeedsUpdate(buffer:Array<Float>, offset:Int):Void {
        var dest = this.resolvedProperty;
        for (i in 0...dest.length) {
            dest[i] = buffer[offset++];
        }
        this.targetObject.needsUpdate = true;
    }
    private function _setValue_array_setMatrixWorldNeedsUpdate(buffer:Array<Float>, offset:Int):Void {
        var dest = this.resolvedProperty;
        for (i in 0...dest.length) {
            dest[i] = buffer[offset++];
        }
        this.targetObject.matrixWorldNeedsUpdate = true;
    }
    private function _setValue_arrayElement(buffer:Array<Float>, offset:Int):Void {
        this.resolvedProperty[this.propertyIndex] = buffer[offset];
    }
    private function _setValue_arrayElement_setNeedsUpdate(buffer:Array<Float>, offset:Int):Void {
        this.resolvedProperty[this.propertyIndex] = buffer[offset];
        this.targetObject.needsUpdate = true;
    }
    private function _setValue_arrayElement_setMatrixWorldNeedsUpdate(buffer:Array<Float>, offset:Int):Void {
        this.resolvedProperty[this.propertyIndex] = buffer[offset];
        this.targetObject.matrixWorldNeedsUpdate = true;
    }
    private function _setValue_fromArray(buffer:Array<Float>, offset:Int):Void {
        this.resolvedProperty.fromArray(buffer, offset);
    }
    private function _setValue_fromArray_setNeedsUpdate(buffer:Array<Float>, offset:Int):Void {
        this.resolvedProperty.fromArray(buffer, offset);
        this.targetObject.needsUpdate = true;
    }
    private function _setValue_fromArray_setMatrixWorldNeedsUpdate(buffer:Array<Float>, offset:Int):Void {
        this.resolvedProperty.fromArray(buffer, offset);
        this.targetObject.matrixWorldNeedsUpdate = true;
    }
    private function _getValue_unbound(targetArray:Array<Float>, offset:Int):Void {
        this.bind();
        this.getValue(targetArray, offset);
    }
    private function _setValue_unbound(sourceArray:Array<Float>, offset:Int):Void {
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

        // set fail state so we can just 'return' on error
        this.getValue = this._getValue_unavailable;
        this.setValue = this._setValue_unavailable;

        // ensure there is a value node
        if (targetObject == null) {
            trace('PropertyBinding: No target node found for track: ' + this.path + '.');
            return;
        }

        if (objectName != null) {
            if (objectName == "materials") {
                if (targetObject.material == null) {
                    trace('PropertyBinding: Can not bind to material as node does not have a material.');
                    return;
                }

                if (targetObject.material.materials == null) {
                    trace('PropertyBinding: Can not bind to material.materials as node.material does not have a materials array.');
                    return;
                }

                targetObject = targetObject.material.materials;
            } else if (objectName == "bones") {
                if (targetObject.skeleton == null) {
                    trace('PropertyBinding: Can not bind to bones as node does not have a skeleton.');
                    return;
                }

                targetObject = targetObject.skeleton.bones;

                for (i in 0...targetObject.length) {
                    if (targetObject[i].name == objectIndex) {
                        objectIndex = i;
                        break;
                    }
                }
            } else if (objectName == "map") {
                if ("map" in targetObject) {
                    targetObject = targetObject.map;
                } else {
                    if (targetObject.material == null) {
                        trace('PropertyBinding: Can not bind to material as node does not have a material.');
                        return;
                    }

                    if (targetObject.material.map == null) {
                        trace('PropertyBinding: Can not bind to material.map as node.material does not have a map.');
                        return;
                    }

                    targetObject = targetObject.material.map;
                }
            } else {
                if (!Reflect.hasField(targetObject, objectName)) {
                    trace('PropertyBinding: Can not bind to objectName of node undefined.');
                    return;
                }
                targetObject = Reflect.field(targetObject, objectName);
                if (objectIndex != null) {
                    if (!Reflect.hasField(targetObject, objectIndex)) {
                        trace('PropertyBinding: Trying to bind to objectIndex of objectName, but is undefined.');
                        return;
                    }
                    targetObject = Reflect.field(targetObject, objectIndex);
                }
            }
        }

        var nodeProperty = Reflect.field(targetObject, propertyName);
        if (nodeProperty == null) {
            trace('PropertyBinding: Trying to update property for track: ' + parsedPath.nodeName + '.' + propertyName + ' but it wasn\'t found.');
            return;
        }

        var versioning = Versioning.None;
        this.targetObject = targetObject;

        if (Reflect.hasField(targetObject, "needsUpdate")) {
            versioning = Versioning.NeedsUpdate;
        } else if (Reflect.hasField(targetObject, "matrixWorldNeedsUpdate")) {
            versioning = Versioning.MatrixWorldNeedsUpdate;
        }

        var bindingType = BindingType.Direct;
        if (propertyIndex != null) {
            if (propertyName == "morphTargetInfluences") {
                if (targetObject.geometry == null) {
                    trace('PropertyBinding: Can not bind to morphTargetInfluences because node does not have a geometry.');
                    return;
                }

                if (targetObject.geometry.morphAttributes == null) {
                    trace('PropertyBinding: Can not bind to morphTargetInfluences because node does not have a geometry.morphAttributes.');
                    return;
                }

                if (targetObject.morphTargetDictionary != null && targetObject.morphTargetDictionary[propertyIndex] != null) {
                    propertyIndex = targetObject.morphTargetDictionary[propertyIndex];
                }
            }

            bindingType = BindingType.ArrayElement;
            this.resolvedProperty = nodeProperty;
            this.propertyIndex = propertyIndex;
        } else if (Reflect.hasField(nodeProperty, "fromArray") && Reflect.hasField(nodeProperty, "toArray")) {
            bindingType = BindingType.HasFromToArray;
            this.resolvedProperty = nodeProperty;
        } else if (nodeProperty is Array<Float>) {
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
        this.getValue = this._getValue_unbound;
        this.setValue = this._setValue_unbound;
    }

}