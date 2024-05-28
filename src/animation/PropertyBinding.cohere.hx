// Characters [].:/ are reserved for track binding syntax.
private static var _RESERVED_CHARS_RE = '\\[\\]\\.:\\/';
private static var _reservedRe = EReg(_RESERVED_CHARS_RE, 'g');

// Attempts to allow node names from any language. ES5's `\w` regexp matches
// only latin characters, and the unicode \p{L} is not yet supported. So
// instead, we exclude reserved characters and match everything else.
private static var _wordChar = '[^' + _RESERVED_CHARS_RE + ']';
private static var _wordCharOrDot = '[^' + _RESERVED_CHARS_RE.replace("\\.", "") + ']';

// Parent directories, delimited by '/' or ':'. Currently unused, but must
// be matched to parse the rest of the track name.
private static var _directoryRe = '/(?:' + _wordChar + '+)[' + _wordChar + ':]*/';

// Target node. May contain word characters (a-zA-Z0-9_) and '.' or '-'.
private static var _nodeRe = '(' + _wordCharOrDot + ')+';

// Object on target node, and accessor. May not contain reserved
// characters. Accessor may contain any character except closing bracket.
private static var _objectRe = '(?:\\.(?:' + _wordChar + '+)(?:\\[(.*?)\\])?)?';

// Property and accessor. May not contain reserved characters. Accessor may
// contain any non-bracket characters.
private static var _propertyRe = '\\.(?:' + _wordChar + '+)(?:\\[(.*?)\\])?';

private static var _trackRe = EReg('^' + _directoryRe + _nodeRe + _objectRe + _propertyRe + '$');

private static var _supportedObjectNames = ['material', 'materials', 'bones', 'map'];

class Composite {
    public function new(targetGroup:Dynamic, path:String, ?optionalParsedPath:Dynamic) {
        var parsedPath = optionalParsedPath != null ? optionalParsedPath : PropertyBinding.parseTrackName(path);

        _targetGroup = targetGroup;
        _bindings = targetGroup.subscribe_(path, parsedPath);
    }

    public function getValue(array:Array<Int>, offset:Int):Void {
        bind(); // bind all binding

        var firstValidIndex = _targetGroup.nCachedObjects_;
        var binding = _bindings[firstValidIndex];

        // and only call .getValue on the first
        if (binding != null) binding.getValue(array, offset);
    }

    public function setValue(array:Array<Int>, offset:Int):Void {
        var bindings = _bindings;

        for (i in bindings) {
            if (i >= _targetGroup.nCachedObjects_) {
                bindings[i].setValue(array, offset);
            }
        }
    }

    public function bind():Void {
        var bindings = _bindings;

        for (i in bindings) {
            if (i >= _targetGroup.nCachedObjects_) {
                bindings[i].bind();
            }
        }
    }

    public function unbind():Void {
        var bindings = _bindings;

        for (i in bindings) {
            if (i >= _targetGroup.nCachedObjects_) {
                bindings[i].unbind();
            }
        }
    }

    private var _targetGroup:Dynamic;
    private var _bindings:Array<Dynamic>;
}

// Note: This class uses a State pattern on a per-method basis:
// 'bind' sets 'this.getValue' / 'setValue' and shadows the
// prototype version of these methods with one that represents
// the bound state. When the property is not found, the methods
// become no-ops.
class PropertyBinding {
    public function new(rootNode:Dynamic, path:String, ?parsedPath:Dynamic) {
        this.path = path;
        this.parsedPath = parsedPath != null ? parsedPath : PropertyBinding.parseTrackName(path);

        this.node = PropertyBinding.findNode(rootNode, parsedPath.nodeName);

        this.rootNode = rootNode;

        // initial state of these methods that calls 'bind'
        this.getValue = _getValue_unbound;
        this.setValue = _setValue_unbound;
    }

    public static function create(root:Dynamic, path:String, ?parsedPath:Dynamic):PropertyBinding {
        if (!root || !Reflect.hasField(root, 'isAnimationObjectGroup')) {
            return PropertyBinding(root, path, parsedPath);
        } else {
            return PropertyBinding.Composite(root, path, parsedPath);
        }
    }

    /**
     * Replaces spaces with underscores and removes unsupported characters from
     * node names, to ensure compatibility with parseTrackName().
     *
     * @param {string} name Node name to be sanitized.
     * @return {string}
     */
    public static function sanitizeNodeName(name:String):String {
        return name.replace(/\s/g, '_').replace(_reservedRe, '');
    }

    public static function parseTrackName(trackName:String):Dynamic {
        var matches = _trackRe.match(trackName);

        if (matches == null) {
            throw "PropertyBinding: Cannot parse trackName: $trackName";
        }

        var results = {
            // directoryName: matches[ 1 ], // (tschw) currently unused
            nodeName: matches[2],
            objectName: matches[3],
            objectIndex: matches[4],
            propertyName: matches[5], // required
            propertyIndex: matches[6]
        };

        var lastDot = results.nodeName.lastIndexOf('.');

        if (lastDot != -1) {
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

        if (results.propertyName == null || results.propertyName == "") {
            throw "PropertyBinding: can not parse propertyName from trackName: $trackName";
        }

        return results;
    }

    public static function findNode(root:Dynamic, nodeName:String):Dynamic {
        if (nodeName == null || nodeName == "" || nodeName == "." || nodeName == "-1" || nodeName == root.name || nodeName == root.uuid) {
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
            function searchNodeSubtree(children:Array<Dynamic>):Dynamic {
                for (child in children) {
                    if (child.name == nodeName || child.uuid == nodeName) {
                        return child;
                    }

                    var result = searchNodeSubtree(child.children);

                    if (result != null) return result;
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

    // these are used to "bind" a nonexistent property
    private function _getValue_unavailable(targetArray:Array<Int>, offset:Int):Void {}
    private function _setValue_unavailable(sourceArray:Array<Int>, offset:Int):Void {}

    // Getters

    private function _getValue_direct(buffer:Array<Int>, offset:Int):Void {
        buffer[offset] = targetObject[propertyName];
    }

    private function _getValue_array(buffer:Array<Int>, offset:Int):Void {
        var source = resolvedProperty;

        for (i in source) {
            buffer[offset++] = source[i];
        }
    }

    private function _getValue_arrayElement(buffer:Array<Int>, offset:Int):Void {
        buffer[offset] = resolvedProperty[propertyIndex];
    }

    private function _getValue_toArray(buffer:Array<Int>, offset:Int):Void {
        resolvedProperty.toArray(buffer, offset);
    }

    // Direct

    private function _setValue_direct(buffer:Array<Int>, offset:Int):Void {
        targetObject[propertyName] = buffer[offset];
    }

    private function _setValue_direct_setNeedsUpdate(buffer:Array<Int>, offset:Int):Void {
        targetObject[propertyName] = buffer[offset];
        targetObject.needsUpdate = true;
    }

    private function _setValue_direct_setMatrixWorldNeedsUpdate(buffer:Array<Int>, offset:Int):Void {
        targetObject[propertyName] = buffer[offset];
        targetObject.matrixWorldNeedsUpdate = true;
    }

    // EntireArray

    private function _setValue_array(buffer:Array<Int>, offset:Int):Void {
        var dest = resolvedProperty;

        for (i in dest) {
            dest[i] = buffer[offset++];
        }
    }

    private function _setValue_array_setNeedsUpdate(buffer:Array<Int>, offset:Int):Void {
        var dest = resolvedProperty;

        for (i in dest) {
            dest[i] = buffer[offset++];
        }

        targetObject.needsUpdate = true;
    }

    private function _setValue_array_setMatrixWorldNeedsUpdate(buffer:Array<Int>, offset:Int):Void {
        var dest = resolvedProperty;

        for (i in dest) {
            dest[i] = buffer[offset++];
        }

        targetObject.matrixWorldNeedsUpdate = true;
    }

    // ArrayElement

    private function _setValue_arrayElement(buffer:Array<Int>, offset:Int):Void {
        resolvedProperty[propertyIndex] = buffer[offset];
    }

    private function _setValue_arrayElement_setNeedsUpdate(buffer:Array<Int>, offset:Int):Void {
        resolvedProperty[propertyIndex] = buffer[offset];
        targetObject.needsUpdate = true;
    }

    private function _setValue_arrayElement_setMatrixWorldNeedsUpdate(buffer:Array<Int>, offset:Int):Void {
        resolvedProperty[propertyIndex] = buffer[offset];
        targetObject.matrixWorldNeedsUpdate = true;
    }

    // HasToFromArray

    private function _setValue_fromArray(buffer:Array<Int>, offset:Int):Void {
        resolvedProperty.fromArray(buffer, offset);
    }

    private function _setValue_fromArray_setNeedsUpdate(buffer:Array<Int>, offset:Int):Void {
        resolvedProperty.fromArray(buffer, offset);
        targetObject.needsUpdate = true;
    }

    private function _setValue_fromArray_setMatrixWorldNeedsUpdate(buffer:Array<Int>, offset:Int):Void {
        resolvedProperty.fromArray(buffer, offset);
        targetObject.matrixWorldNeedsUpdate = true;
    }

    private function _getValue_unbound(targetArray:Array<Int>, offset:Int):Void {
        bind();
        getValue(targetArray, offset);
    }

    private function _setValue_unbound(sourceArray:Array<Int>, offset:Int):Void {
        bind();
        setValue(sourceArray, offset);
    }

    // create getter / setter pair for a property in the scene graph
    public function bind():Void {
        var targetObject = node;
        var parsedPath = this.parsedPath;

        var objectName = parsedPath.objectName;
        var propertyName = parsedPath.propertyName;
        var propertyIndex = parsedPath.propertyIndex;

        if (targetObject == null) {
            targetObject = PropertyBinding.findNode(rootNode, parsedPath.nodeName);

            this.node = targetObject;
        }

        // set fail state so we can just 'return' on error
        getValue = _getValue_unavailable;
        setValue = _setValue_unavailable;

        // ensure there is a value node
        if (targetObject == null) {
            trace("THREE.PropertyBinding: No target node found for track: $path.");
            return;
        }

        if (objectName != null) {
            var objectIndex = parsedPath.objectIndex;

            // special cases were we need to reach deeper into the hierarchy to get the face materials....
            switch (objectName) {
                case 'materials':
                    if (targetObject.material == null) {
                        throw "THREE.PropertyBinding: Can not bind to material as node does not have a material.";
                    }

                    if (targetObject.material.materials == null) {
                        throw "THREE.PropertyBinding: Can not bind to material.materials as node.material does not have a materials array.";
                    }

                    targetObject = targetObject.material.materials;
                    break;

                case 'bones':
                    if (targetObject.skeleton == null) {
                        throw "THREE.PropertyBinding: Can not bind to bones as node does not have a skeleton.";
                    }

                    // potential future optimization: skip this if propertyIndex is already an integer
                    // and convert the integer string to a true integer.

                    targetObject = targetObject.skeleton.bones;

                    // support resolving morphTarget names into indices.
                    for (i in targetObject) {
                        if (targetObject[i].name == objectIndex) {
                            objectIndex = i;
                            break;
                        }
                    }

                    break;

                case 'map':
                    if (Reflect.hasField(targetObject, 'map')) {
                        targetObject = targetObject.map;
                        break;
                    }

                    if (targetObject.material == null) {
                        throw "THREE.PropertyBinding: Can not bind to material as node does not have a material.";
                    }

                    if (targetObject.material.map == null) {
                        throw "THREE.PropertyBinding: Can not bind to material.map as node.material does not have a map.";
                    }

                    targetObject = targetObject.material.map;
                    break;

                default:
                    if (targetObject[objectName] == null) {
                        throw "THREE.PropertyBinding: Can not bind to objectName of node undefined.";
                    }

                    targetObject = targetObject[objectName];
            }


            if (objectIndex != null) {
                if (targetObject[objectIndex] == null) {
                    throw "THREE.PropertyBinding: Trying to bind to objectIndex of objectName, but is undefined.";
                }

                targetObject = targetObject[objectIndex];
            }
        }

        // resolve property
        var nodeProperty = targetObject[propertyName];

        if (nodeProperty == null) {
            var nodeName = parsedPath.nodeName;

            throw "THREE.PropertyBinding: Trying to update property for track: $nodeName.$propertyName but it wasn't found.";
        }

        // determine versioning scheme
        var versioning = Versioning.None;

        this.targetObject = targetObject;

        if (Reflect.hasField(targetObject, 'needsUpdate')) { // material
            versioning = Versioning.NeedsUpdate;
        } else if (Reflect.hasField(targetObject, 'matrixWorldNeedsUpdate')) { // node transform
            versioning = Versioning.MatrixWorldNeedsUpdate;
        }

        // determine how the property gets bound
        var bindingType = BindingType.Direct;

        if (propertyIndex != null) {
            // access a sub element of the property array (only primitives are supported right now)

            if (propertyName == 'morphTargetInfluences') {
                // potential optimization, skip this if propertyIndex is already an integer, and convert the integer string to a true integer.

                // support resolving morphTarget names into indices.
                if (targetObject.geometry == null) {
                    throw "THREE.PropertyBinding: Can not bind to morphTargetInfluences because node does not have a geometry.";
                }

                if (targetObject.geometry.morphAttributes == null) {
                    throw "THREE.PropertyBinding: Can not bind to morphTargetInfluences because node does not have a geometry.morphAttributes.";
                }

                if (targetObject.morphTargetDictionary[propertyIndex] != null) {
                    propertyIndex = targetObject.morphTargetDictionary[propertyIndex];
                }
            }

            bindingType = BindingType.ArrayElement;

            this.resolvedProperty = nodeProperty;
            this.propertyIndex = propertyIndex;
        } else if (Reflect.hasField(nodeProperty, 'fromArray') && Reflect.hasField(nodeProperty, 'toArray')) {
            // must use copy for Object3D.Euler/Quaternion

            bindingType = BindingType.HasFromToArray;

            this.resolvedProperty = nodeProperty;
        } else if (nodeProperty instanceof Array) {
            bindingType = BindingType.EntireArray;

            this.resolvedProperty = nodeProperty;
        } else {
            this.propertyName = propertyName;
        }

        // select getter / setter
        getValue = GetterByBindingType[bindingType];
        setValue = SetterByBindingTypeAndVersioning[bindingType][versioning];
    }

    public function unbind():Void {
        node = null;

        // back to the prototype version of getValue / setValue
        // note: avoiding to mutate the shape of 'this' via 'delete'
        getValue = _getValue_unbound;
        setValue = _setValue_unbound;
    }

    private var path:String;
    private var parsedPath:Dynamic;
    private var node:Dynamic;
    private var rootNode:Dynamic;
    private var targetObject:Dynamic;
    private var propertyName:String;
    private var resolvedProperty:Dynamic;
    private var propertyIndex:Int;

    private static var Versioning = {
        None: 0,
        NeedsUpdate: 1,
        MatrixWorldNeedsUpdate: 2
    };

    private static var BindingType = {
        Direct: 0,
        EntireArray: 1,
        ArrayElement: 2,
        HasFromToArray: 3
    };

    private static var GetterByBindingType = [
        _getValue_direct,
        _getValue_array,
        _getValue_arrayElement,
        _getValue_toArray,
    ];

    private static var SetterByBindingTypeAndVersioning = [
        [
            // Direct
            _setValue_direct,
            _setValue_direct_setNeedsUpdate,
            _setValue_
            _setValue_direct_setMatrixWorldNeedsUpdate,
        ],
        [
            // EntireArray

            _setValue_array,
            _setValue_array_setNeedsUpdate,
            _setValue_array_setMatrixWorldNeedsUpdate,
        ],
        [
            // ArrayElement
            _setValue_arrayElement,
            _setValue_arrayElement_setNeedsUpdate,
            _setValue_arrayElement_setMatrixWorldNeedsUpdate,
        ],
        [
            // HasToFromArray
            _setValue_fromArray,
            _setValue_fromArray_setNeedsUpdate,
            _setValue_fromArray_setMatrixWorldNeedsUpdate,
        ]
    ];
}

class PropertyBindingComposite extends PropertyBinding {
    public function new(targetGroup:Dynamic, path:String, ?optionalParsedPath:Dynamic) {
        super(targetGroup, path, optionalParsedPath);
    }
}

class haxe_export {
    public static var PropertyBinding = PropertyBinding;
}