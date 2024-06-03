import js.Browser.document;
import js.Browser.console;
import js.Browser.window;

class PropertyBinding {
    public var path:String;
    public var parsedPath:Dynamic;
    public var node:Dynamic;
    public var rootNode:Dynamic;
    public var getValue:Function;
    public var setValue:Function;

    public function new(rootNode:Dynamic, path:String, parsedPath:Dynamic = null) {
        this.path = path;
        this.parsedPath = parsedPath == null ? PropertyBinding.parseTrackName(path) : parsedPath;
        this.node = PropertyBinding.findNode(rootNode, this.parsedPath.nodeName);
        this.rootNode = rootNode;
        this.getValue = this._getValue_unbound;
        this.setValue = this._setValue_unbound;
    }

    static public function create(root:Dynamic, path:String, parsedPath:Dynamic = null):PropertyBinding {
        if (root == null || !Std.is(root, Dynamic).resolve("isAnimationObjectGroup")) {
            return new PropertyBinding(root, path, parsedPath);
        } else {
            return new Composite(root, path, parsedPath);
        }
    }

    static public function sanitizeNodeName(name:String):String {
        return name.replace(new EReg("\\s", "g"), "_").replace(_reservedRe, "");
    }

    static public function parseTrackName(trackName:String):Dynamic {
        var matches = _trackRe.exec(trackName);
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

        var lastDot = results.nodeName != null && results.nodeName.lastIndexOf(".");
        if (lastDot != null && lastDot != -1) {
            var objectName = results.nodeName.substring(lastDot + 1);
            if (_supportedObjectNames.indexOf(objectName) != -1) {
                results.nodeName = results.nodeName.substring(0, lastDot);
                results.objectName = objectName;
            }
        }

        if (results.propertyName == null || results.propertyName.length == 0) {
            throw "PropertyBinding: can not parse propertyName from trackName: " + trackName;
        }

        return results;
    }

    static public function findNode(root:Dynamic, nodeName:String):Dynamic {
        // Implementation...
    }

    // Other methods...
}

class Composite {
    // Implementation...
}

var _RESERVED_CHARS_RE = '\\[\\]\\.:\\/';
var _reservedRe = new EReg('[' + _RESERVED_CHARS_RE + ']', 'g');
var _wordChar = '[^' + _RESERVED_CHARS_RE + ']';
var _wordCharOrDot = '[^' + _RESERVED_CHARS_RE.replace('\\.', '') + ']';
var _directoryRe = new EReg("((?:WC+[\/:])*)".source.replace('WC', _wordChar), ['g']);
var _nodeRe = new EReg("(WCOD+)?".source.replace('WCOD', _wordCharOrDot), ['g']);
var _objectRe = new EReg("(?:\\.(WC+)(?:\\[(.+)\\])?)?".source.replace('WC', _wordChar), ['g']);
var _propertyRe = new EReg("\\.(WC+)(?:\\[(.+)\\])?".source.replace('WC', _wordChar), ['g']);
var _trackRe = new EReg(""
    + '^'
    + _directoryRe.source
    + _nodeRe.source
    + _objectRe.source
    + _propertyRe.source
    + '$'
);
var _supportedObjectNames = [ 'material', 'materials', 'bones', 'map' ];