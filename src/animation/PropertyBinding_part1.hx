Here is the converted Haxe code:
```
package three.animation;

class Composite {
    private var _targetGroup:Dynamic;
    private var _bindings:Array<Dynamic>;

    public function new(targetGroup:Dynamic, path:String, ?optionalParsedPath:Dynamic) {
        var parsedPath:Dynamic = optionalParsedPath != null ? optionalParsedPath : PropertyBinding.parseTrackName(path);
        _targetGroup = targetGroup;
        _bindings = targetGroup.subscribe_(path, parsedPath);
    }

    public function getValue(array:Array<Dynamic>, offset:Int) {
        bind(); // bind all binding

        var firstValidIndex:Int = _targetGroup.nCachedObjects_;
        var binding:Dynamic = _bindings[firstValidIndex];

        if (binding != null) binding.getValue(array, offset);
    }

    public function setValue(array:Array<Dynamic>, offset:Int) {
        var bindings:Array<Dynamic> = _bindings;

        for (i in _targetGroup.nCachedObjects_...bindings.length) {
            bindings[i].setValue(array, offset);
        }
    }

    public function bind() {
        var bindings:Array<Dynamic> = _bindings;

        for (i in _targetGroup.nCachedObjects_...bindings.length) {
            bindings[i].bind();
        }
    }

    public function unbind() {
        var bindings:Array<Dynamic> = _bindings;

        for (i in _targetGroup.nCachedObjects_...bindings.length) {
            bindings[i].unbind();
        }
    }
}
```
Note that I've assumed the `PropertyBinding` class is already defined in the Haxe code, and I've used the `Dynamic` type to represent the types that are not explicitly defined in the JavaScript code. You may need to adjust the types to match your specific use case.