import haxe.ds.StringMap;

class SampledTexture extends Binding {
    public var id:Int;
    public var texture:Texture;
    public var version:Int;
    public var store:Bool;
    public var isSampledTexture:Bool;

    public function new(name:String, texture:Texture) {
        super(name);
        $id = 0;
        $texture = texture;
        $version = if (texture != null) texture.version else 0;
        $store = false;
        $isSampledTexture = true;
    }

    public function get needsBindingsUpdate():Bool {
        if (texture.isVideoTexture)
            return true;
        return version != texture.version;
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

    public function new(name:String, texture:Texture) {
        super(name, texture);
        $isSampledArrayTexture = true;
    }
}

class Sampled3DTexture extends SampledTexture {
    public var isSampled3DTexture:Bool;

    public function new(name:String, texture:Texture) {
        super(name, texture);
        $isSampled3DTexture = true;
    }
}

class SampledCubeTexture extends SampledTexture {
    public var isSampledCubeTexture:Bool;

    public function new(name:String, texture:Texture) {
        super(name, texture);
        $isSampledCubeTexture = true;
    }
}

class Binding {
    public var name:String;

    public function new(name:String) {
        $name = name;
    }
}