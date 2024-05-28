package three.animation;

import haxe.Regex;

class PropertyBinding {
    static var _RESERVED_CHARS_RE:EReg = ~/[\\[\\]\\.:\/]/;
    static var _reservedRe:EReg = new EReg('[' + _RESERVED_CHARS_RE.pattern + ']', 'g');

    static var _wordChar:EReg = ~/[^${_RESERVED_CHARS_RE.pattern}]/;
    static var _wordCharOrDot:EReg = ~/[^${_RESERVED_CHARS_RE.pattern.replace('.', '')}]/;

    static var _directoryRe:EReg = ~/((?:WC+[\/:])*)/.source.replace('WC', _wordChar.pattern);
    static var _nodeRe:EReg = ~/WCOD+/.source.replace('WCOD', _wordCharOrDot.pattern);
    static var _objectRe:EReg = ~/(?:\.(WC+)(?:\[(.+)\])?)?/.source.replace('WC', _wordChar.pattern);
    static var _propertyRe:EReg = ~/\.WC+(?:\[(.+)\])?/.source.replace('WC', _wordChar.pattern);

    static var _trackRe:EReg = new EReg('^' + _directoryRe.pattern + _nodeRe.pattern + _objectRe.pattern + _propertyRe.pattern + '$');

    static var _supportedObjectNames:Array<String> = ['material', 'materials', 'bones', 'map'];

    public function new(rootNode:Node, path:String, parsedPath:ParsedPath) {
        this.path = path;
        this.parsedPath = parsedPath != null ? parsedPath : parseTrackName(path);

        this.node = findNode(rootNode, parsedPath.nodeName);

        this.rootNode = rootNode;

        this.getValue = _getValue_unbound;
        this.setValue = _setValue_unbound;
    }

    static function create(root:Node, path:String, parsedPath:ParsedPath):PropertyBinding {
        if (!(root != null && root.isAnimationObjectGroup)) {
            return new PropertyBinding(root, path, parsedPath);
        } else {
            return new Composite(root, path, parsedPath);
        }
    }

    static function sanitizeNodeName(name:String):String {
        return name.replace(/\s+/g, '_').replace(_reservedRe, '');
    }

    static function parseTrackName(trackName:String):ParsedPath {
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

        var lastDot:Int = results.nodeName.lastIndexOf('.');
        if (lastDot != -1) {
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

    static function findNode(root:Node, nodeName:String):Node {
        if (nodeName == null || nodeName == '' || nodeName == '.' || nodeName == root.name || nodeName == root.uuid) {
            return root;
        }

        if (root.skeleton != null) {
            var bone:Bone = root.skeleton.getBoneByName(nodeName);
            if (bone != null) {
                return bone;
            }
        }

        if (root.children != null) {
            for (child in root.children) {
                if (child.name == nodeName || child.uuid == nodeName) {
                    return child;
                }

                var subTreeNode:Node = searchNodeSubtree(child.children);
                if (subTreeNode != null) {
                    return subTreeNode;
                }
            }
        }

        return null;
    }

    function _getValue_unavailable(buffer:Array<Float>, offset:Int) {}

    function _setValue_unavailable(buffer:Array<Float>, offset:Int) {}

    // getters
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

    // setters
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

    function _setValue_arrayElement_setNeedsUpdate(buffer:Array<Float>, offset:Int):Void {
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

    function bind():Void {
        var targetObject:Node = node;
        var parsedPath:ParsedPath = this.parsedPath;

        var objectName:String = parsedPath.objectName;
        var propertyName:String = parsedPath.propertyName;
        var propertyIndex:Int = parsedPath.propertyIndex;

        if (!targetObject) {
            targetObject = findNode(rootNode, parsedPath.nodeName);
            node = targetObject;
        }

        // set fail state so we can just 'return' on error
        getValue = _getValue_unavailable;
        setValue = _setValue_unavailable;

        if (!targetObject) {
            console.warn('THREE.PropertyBinding: No target node found for track: ' + path + '.');
            return;
        }

        if (objectName != null) {
            var objectIndex:Int = parsedPath.objectIndex;

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

                case 'bones':
                    if (!targetObject.skeleton) {
                        console.error('THREE.PropertyBinding: Can not bind to bones as node does not have a skeleton.', this);
                        return;
                    }

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
                    } else if (!targetObject.material) {
                        console.error('THREE.PropertyBinding: Can not bind to material as node does not have a material.', this);
                        return;
                    }

                    if (!targetObject.material.map) {
                        console.error('THREE.PropertyBinding: Can not bind to material.map as node.material does not have a map.', this);
                        return;
                    }

                    targetObject = targetObject.material.map;
            }

            if (objectIndex != null) {
                if (!targetObject[objectIndex]) {
                    console.error('THREE.PropertyBinding: Can not bind to objectIndex of objectName, but is undefined.', this, targetObject);
                    return;
                }

                targetObject = targetObject[objectIndex];
            }
        }

        var nodeProperty:Dynamic = targetObject[propertyName];

        if (nodeProperty == null) {
            console.error('THREE.PropertyBinding: Trying to update property for track: ' + parsedPath.nodeName + '.' + propertyName + ' but it wasn\'t found.', targetObject);
            return;
        }

        targetObject = targetObject;

        var versioning:Int = Versioning.None;

        if (targetObject.needsUpdate != null) { // material
            versioning = Versioning.NeedsUpdate;
        } else if (targetObject.matrixWorldNeedsUpdate != null) { // node transform
            versioning = Versioning.MatrixWorldNeedsUpdate;
        }

        var bindingType:Int = BindingType.Direct;

        if (propertyIndex != null) {
            bindingType = BindingType.ArrayElement;

            resolvedProperty = nodeProperty;
            this.propertyIndex = propertyIndex;
        } else if (nodeProperty.fromArray != null && nodeProperty.toArray != null) {
            bindingType = BindingType.HasFromToArray;

            resolvedProperty = nodeProperty;
        } else if (Std.isOfType(nodeProperty, Array)) {
            bindingType = BindingType.EntireArray;

            resolvedProperty = nodeProperty;
        } else {
            propertyName = propertyName;
        }

        // select getter / setter
        getValue = GetterByBindingType[bindingType];
        setValue = SetterByBindingTypeAndVersioning[bindingType][versioning];
    }

    function unbind():Void {
        node = null;

        // back to the prototype version of getValue / setValue
        getValue = _getValue_unbound;
        setValue = _setValue_unbound;
    }
}

class Composite {
    public function new(targetGroup:Node, path:String, parsedPath:ParsedPath) {
        targetGroup.subscribe_(path, parsedPath);
    }

    public function getValue(array:Array<Float>, offset:Int):Void {
        bind(); // bind all binding
        getValue(array, offset);
    }

    public function setValue(array:Array<Float>, offset:Int):Void {
        bind(); // bind all binding
        setValue(array, offset);
    }

    public function bind():Void {
        var bindings:Array<PropertyBinding> = targetGroup.subscribe_(path, parsedPath);

        for (i in 0...bindings.length) {
            bindings[i].bind();
        }
    }

    public function unbind():Void {
        var bindings:Array<PropertyBinding> = targetGroup.subscribe_(path, parsedPath);

        for (i in 0...bindings.length) {
            bindings[i].unbind();
        }
    }
}