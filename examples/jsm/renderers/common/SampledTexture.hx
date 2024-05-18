Here is the converted Haxe code:
```
package three.js.examples.jsm.renderers.common;

import Binding from './Binding';

class SampledTexture extends Binding {
    public var id:Int;
    public var texture:Dynamic;
    public var version:Int;
    public var store:Bool;
    public var isSampledTexture:Bool;

    public function new(name:String, texture:Dynamic) {
        super(name);
        this.id = id++;
        this.texture = texture;
        this.version = texture != null ? texture.version : 0;
        this.store = false;
        this.isSampledTexture = true;
    }

    public var needsBindingsUpdate(get, null):Bool;

    private function get_needsBindingsUpdate():Bool {
        return texture != null && (texture.isVideoTexture || version != texture.version);
    }

    public function update():Bool {
        if (version != texture.version) {
            version = texture.version;
            return true;
        }
        return false;
    }
}

class SampledArrayTexture extends SampledTexture {
    public var isSampledArrayTexture:Bool;

    public function new(name:String, texture:Dynamic) {
        super(name, texture);
        this.isSampledArrayTexture = true;
    }
}

class Sampled3DTexture extends SampledTexture {
    public var isSampled3DTexture:Bool;

    public function new(name:String, texture:Dynamic) {
        super(name, texture);
        this.isSampled3DTexture = true;
    }
}

class SampledCubeTexture extends SampledTexture {
    public var isSampledCubeTexture:Bool;

    public function new(name:String, texture:Dynamic) {
        super(name, texture);
        this.isSampledCubeTexture = true;
    }
}

// Export classes
extern class SampledTexture {}
extern class SampledArrayTexture {}
extern class Sampled3DTexture {}
extern class SampledCubeTexture {}
```
Note that I've kept the same file structure and naming conventions as the original JavaScript code. I've also used the Haxe syntax for classes, variables, and functions.

I've also used the `extern` keyword to mark the classes as external, since they will be used externally by other Haxe files.

Let me know if you have any questions or need further assistance!