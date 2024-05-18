package three.animation;

import haxe.ds.StringMap;

class PropertyBinding {
    static var _RESERVED_CHARS_RE = ~/[\\[\\].:\/]/;
    static var _reservedRe = new EReg(_RESERVED_CHARS_RE, 'g');

    static var _wordChar = '[^' + _RESERVED_CHARS_RE + ']';
    static var _wordCharOrDot = '[^' + _RESERVED_CHARS_RE.replace('.', '') + ']';

    static var _directoryRe = ~/((?:WC+[\/:])*)/.source.replace('WC', _wordChar);
    static var _nodeRe = ~/WCOD+/.source.replace('WCOD', _wordCharOrDot);
    static var _objectRe = ~/(?:\.(WC+)(?:\[(.+)\])?/.source.replace('WC', _wordChar);
    static var _propertyRe = ~/\.WC+(?:\[(.+)\])?/.source.replace('WC', _wordChar);

    static var _trackRe = new EReg('^' + _directoryRe + _nodeRe + _objectRe + _propertyRe + '$');

    static var _supportedObjectNames = ['material', 'materials', 'bones', 'map'];

    var targetGroup:Dynamic;
    var _bindings:Array<Dynamic>;

    public function new(targetGroup:Dynamic, path:String, ?optionalParsedPath:Dynamic) {
        var parsedPath = optionalParsedPath != null ? optionalParsedPath : parseTrackName(path);
        this.targetGroup = targetGroup;
        this._bindings = targetGroup.subscribe_(path, parsedPath);
    }

    public function getValue(array:Array<Dynamic>, offset:Int) {
        bind(); // bind all binding
        var firstValidIndex = targetGroup.nCachedObjects_;
        var binding = _bindings[firstValidIndex];
        if (binding != null) binding.getValue(array, offset);
    }

    public function setValue(array:Array<Dynamic>, offset:Int) {
        var bindings = _bindings;
        for (i in targetGroup.nCachedObjects_...bindings.length) {
            bindings[i].setValue(array, offset);
        }
    }

    public function bind() {
        var bindings = _bindings;
        for (i in targetGroup.nCachedObjects_...bindings.length) {
            bindings[i].bind();
        }
    }

    public function unbind() {
        var bindings = _bindings;
        for (i in targetGroup.nCachedObjects_...bindings.length) {
            bindings[i].unbind();
        }
    }

    static function create(root:Dynamic, path:String, ?parsedPath:Dynamic) {
        if (!(root != null && root.isAnimationObjectGroup)) {
            return new PropertyBinding(root, path, parsedPath);
        } else {
            return new Composite(root, path, parsedPath);
        }
    }

    static function sanitizeNodeName(name:String) {
        return name.replace(/\s/g, '_').replace(_reservedRe, '');
    }

    static function parseTrackName(trackName:String) {
        var matches = _trackRe.exec(trackName);
        if (matches == null) {
            throw new Error('PropertyBinding: Cannot parse trackName: ' + trackName);
        }
        var results = {
            nodeName: matches[2],
            objectName: matches[3],
            objectIndex: matches[4],
            propertyName: matches[5], // required
            propertyIndex: matches[6]
        };
        var lastDot = results.nodeName.lastIndexOf('.');
        if (lastDot != -1) {
            var objectName = results.nodeName.substring(lastDot + 1);
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

    static function findNode(root:Dynamic, nodeName:String) {
        if (nodeName == null || nodeName == '' || nodeName == '.' || nodeName == root.name || nodeName == root.uuid) {
            return root;
        }
        if (root.skeleton != null) {
            var bone = root.skeleton.getBoneByName(nodeName);
            if (bone != null) return bone;
        }
        if (root.children != null) {
            function searchNodeSubtree(children:Array<Dynamic>) {
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
            if (subTreeNode != null) return subTreeNode;
        }
        return null;
    }

    // ...
}