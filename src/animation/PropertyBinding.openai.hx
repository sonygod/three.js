package three.js.src.animation;

import haxe.Constraints;

class PropertyBinding {
    public static var RESERVED_CHARS_RE:EReg = ~/[\[\].:\/]/;
    public static var _reservedRe:EReg = new EReg(escapeRegExp(RESERVED_CHARS_RE.pattern), 'g');

    public static var _wordChar:EReg = ~/[^${RESERVED_CHARS_RE.pattern}]/;
    public static var _wordCharOrDot:EReg = ~/[^${RESERVED_CHARS_RE.pattern.replace('.', '')}]/;

    public static var _directoryRe:EReg = ~/((?:WC+[\/:])*)/.source.replace('WC', _wordChar.pattern);
    public static var _nodeRe:EReg = ~/WCOD+/.source.replace('WCOD', _wordCharOrDot.pattern);
    public static var _objectRe:EReg = ~/(?:\.(WC+)(?:\[(.+)\])?)?/.source.replace('WC', _wordChar.pattern);
    public static var _propertyRe:EReg = ~/\.WC+(?:\[(.+)\])?/.source.replace('WC', _wordChar.pattern);

    public static var _trackRe:EReg = new EReg('^' + _directoryRe.pattern + _nodeRe.pattern + _objectRe.pattern + _propertyRe.pattern + '$');

    public static var _supportedObjectNames:Array<String> = ['material', 'materials', 'bones', 'map'];

    public var targetGroup:Dynamic;
    public var path:String;
    public var parsedPath:Dynamic;
    public var node:Dynamic;
    public var rootNode:Dynamic;
    public var getValue:Void->Void;
    public var setValue:Void->Void;

    public function new(rootNode:Dynamic, path:String, parsedPath:Dynamic) {
        this.rootNode = rootNode;
        this.path = path;
        this.parsedPath = parsedPath;
        this.node = findNode(rootNode, parsedPath.nodeName);
        this.getValue = _getValue_unbound;
        this.setValue = _setValue_unbound;
    }

    public static function create(root:Dynamic, path:String, parsedPath:Dynamic):PropertyBinding {
        if (!root || !root.isAnimationObjectGroup) {
            return new PropertyBinding(root, path, parsedPath);
        } else {
            return new Composite(root, path, parsedPath);
        }
    }

    public static function sanitizeNodeName(name:String):String {
        return name.replace(/\s+/g, '_').replace(_reservedRe, '');
    }

    public static function parseTrackName(trackName:String):Dynamic {
        if (!_trackRe.match(trackName)) {
            throw new Error('PropertyBinding: Cannot parse trackName: ' + trackName);
        }
        var parsedPath:Dynamic = {
            nodeName: _trackRe.matched(2),
            objectName: _trackRe.matched(3),
            objectIndex: _trackRe.matched(4),
            propertyName: _trackRe.matched(5), // required
            propertyIndex: _trackRe.matched(6)
        };
        if (parsedPath.nodeName != null) {
            var lastDot:Int = parsedPath.nodeName.lastIndexOf('.');
            if (lastDot != -1) {
                var objectName:String = parsedPath.nodeName.substring(lastDot + 1);
                if (_supportedObjectNames.indexOf(objectName) != -1) {
                    parsedPath.nodeName = parsedPath.nodeName.substring(0, lastDot);
                    parsedPath.objectName = objectName;
                }
            }
        }
        if (parsedPath.propertyName == null || parsedPath.propertyName.length == 0) {
            throw new Error('PropertyBinding: can not parse propertyName from trackName: ' + trackName);
        }
        return parsedPath;
    }

    public static function findNode(root:Dynamic, nodeName:String):Dynamic {
        if (nodeName == null || nodeName == '' || nodeName == '.' || nodeName == root.name || nodeName == root.uuid) {
            return root;
        }
        if (root.skeleton) {
            var bone:Dynamic = root.skeleton.getBoneByName(nodeName);
            if (bone != null) {
                return bone;
            }
        }
        if (root.children) {
            for (child in root.children) {
                if (child.name == nodeName || child.uuid == nodeName) {
                    return child;
                }
                var subTreeNode:Dynamic = findNode(child, nodeName);
                if (subTreeNode != null) {
                    return subTreeNode;
                }
            }
        }
        return null;
    }

    // ...

    public function bind():Void {
        // ...
    }

    public function unbind():Void {
        // ...
    }
}

class Composite {
    public var targetGroup:Dynamic;
    public var path:String;
    public var parsedPath:Dynamic;
    public var _bindings:Array<PropertyBinding>;

    public function new(targetGroup:Dynamic, path:String, parsedPath:Dynamic) {
        this.targetGroup = targetGroup;
        this.path = path;
        this.parsedPath = parsedPath;
        this._bindings = targetGroup.subscribe_(path, parsedPath);
    }

    public function getValue(array:Array<Dynamic>, offset:Int):Void {
        bind();
        getValue(array, offset);
    }

    public function setValue(array:Array<Dynamic>, offset:Int):Void {
        for (binding in _bindings) {
            binding.setValue(array, offset);
        }
    }

    public function bind():Void {
        for (binding in _bindings) {
            binding.bind();
        }
    }

    public function unbind():Void {
        for (binding in _bindings) {
            binding.unbind();
        }
    }
}