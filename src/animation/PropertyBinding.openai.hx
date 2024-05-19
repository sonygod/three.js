class Composite {
    var _targetGroup: Dynamic;
    var _bindings: Dynamic;

    public function new(targetGroup: Dynamic, path: String, optionalParsedPath: Dynamic = null) {
        this._targetGroup = targetGroup;
        this._bindings = targetGroup.subscribe_(path, optionalParsedPath);
    }

    public function getValue(array: Array<Float>, offset: Int): Void {
        this.bind();
        
        var firstValidIndex = this._targetGroup.nCachedObjects_;
        var binding = this._bindings[firstValidIndex];
        
        if(binding != null) {
            binding.getValue(array, offset);
        }
    }

    public function setValue(array: Array<Float>, offset: Int): Void {
        var bindings = this._bindings;
        
        for(i in this._targetGroup.nCachedObjects_...bindings.length) {
            bindings[i].setValue(array, offset);
        }
    }

    public function bind(): Void {
        var bindings = this._bindings;
        
        for(i in this._targetGroup.nCachedObjects_...bindings.length) {
            bindings[i].bind();
        }
    }

    public function unbind(): Void {
        var bindings = this._bindings;
        
        for(i in this._targetGroup.nCachedObjects_...bindings.length) {
            bindings[i].unbind();
        }
    }
}

class PropertyBinding {
    public static var _RESERVED_CHARS_RE = "\\[\\]\\.:\\/";
    public static var _reservedRe: EReg = new EReg("[" + _RESERVED_CHARS_RE + "]", "g");
    
    public static var _wordChar: String = "[^" + _RESERVED_CHARS_RE + "]";
    public static var _wordCharOrDot: String = "[^" + _RESERVED_CHARS_RE.replace("\\.", "") + "]";
    
    public static var _directoryRe: EReg = new EReg("((?:WC+[\/:])*)".replace("WC", _wordChar), "");
    public static var _nodeRe: EReg = new EReg("(WCOD+)?".replace("WCOD", _wordCharOrDot), "");
    public static var _objectRe: EReg = new EReg("(?:\\.(WC+)(?:\\[(.+)\\])?)?".replace("WC", _wordChar), "");
    public static var _propertyRe: EReg = new EReg("\\.(WC+)(?:\\[(.+)\\])?".replace("WC", _wordChar), "");
    
    public static var _trackRe: EReg = new EReg("^" + _directoryRe.getSource() + _nodeRe.getSource() + _objectRe.getSource() + _propertyRe.getSource() + "$", "");
    
    public static var _supportedObjectNames: Array<String> = ["material", "materials", "bones", "map"];
    
    public var path: String;
    public var parsedPath: Dynamic;
    public var node: Dynamic;
    public var rootNode: Dynamic;
    
    public var getValue: Dynamic;
    public var setValue: Dynamic;
    
    public function new(rootNode: Dynamic, path: String, parsedPath: Dynamic = null) {
        this.path = path;
        this.parsedPath = parsedPath != null ? parsedPath : PropertyBinding.parseTrackName(path);
        this.node = PropertyBinding.findNode(rootNode, this.parsedPath.nodeName);
        this.rootNode = rootNode;
        
        this.getValue = this._getValue_unbound;
        this.setValue = this._setValue_unbound;
    }
    
    public static function create(root: Dynamic, path: String, parsedPath: Dynamic = null): PropertyBinding {
        if(root != null && Std.is(root, AnimationObjectGroup)) {
            return new Composite(root, path, parsedPath);
        } else {
            return new PropertyBinding(root, path, parsedPath);
        }
    }

    // Other methods and properties can be translated similarly
}