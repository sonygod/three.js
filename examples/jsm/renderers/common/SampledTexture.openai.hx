package three.js.examples.jsm.renderers.common;

import Binding;

class SampledTexture extends Binding {
    public var id:Int;
    public var texture:Dynamic;
    public var version:Int;
    public var store:Bool;
    public var isSampledTexture:Bool;

    public function new(name:String, texture:Dynamic) {
        super(name);
        id = ++idCount;
        this.texture = texture;
        this.version = texture != null ? texture.version : 0;
        this.store = false;
        this.isSampledTexture = true;
    }

    public function get_needsBindingsUpdate():Bool {
        return texture.isVideoTexture || version != texture.version; // @TODO: version === 0 && texture.version > 0 ( add it just to External Textures like PNG,JPG )
    }

    public function update():Bool {
        if (version != texture.version) {
            version = texture.version;
            return true;
        }
        return false;
    }

    static var idCount:Int = 0;
}

class SampledArrayTexture extends SampledTexture {
    public var isSampledArrayTexture:Bool;

    public function new(name:String, texture:Dynamic) {
        super(name, texture);
        isSampledArrayTexture = true;
    }
}

class Sampled3DTexture extends SampledTexture {
    public var isSampled3DTexture:Bool;

    public function new(name:String, texture:Dynamic) {
        super(name, texture);
        isSampled3DTexture = true;
    }
}

class SampledCubeTexture extends SampledTexture {
    public var isSampledCubeTexture:Bool;

    public function new(name:String, texture:Dynamic) {
        super(name, texture);
        isSampledCubeTexture = true;
    }
}