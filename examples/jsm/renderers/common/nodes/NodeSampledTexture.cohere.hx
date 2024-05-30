import js.Browser.Window;

class NodeSampledTexture extends SampledTexture {
    var textureNode:Dynamic;

    public function new(name:String, textureNode:Dynamic) {
        super(name, textureNode != null ? textureNode.value : null);
        this.textureNode = textureNode;
    }

    public function get_needsBindingsUpdate():Bool {
        return textureNode.value != texture || super.get_needsBindingsUpdate();
    }

    public function update():Bool {
        if (texture != textureNode.value) {
            texture = textureNode.value;
            return true;
        }
        return super.update();
    }
}

class NodeSampledCubeTexture extends NodeSampledTexture {
    public function new(name:String, textureNode:Dynamic) {
        super(name, textureNode);
        isSampledCubeTexture = true;
    }
}

@:jsRequire("NodeSampledTexture")
extern class NodeSampledTextureNative(js.Native) { }

@:jsRequire("NodeSampledCubeTexture")
extern class NodeSampledCubeTextureNative(js.Native) { }

@:jsRequire(NodeSampledTextureNative)
extern var NodeSampledTexture_proto:Dynamic;

@:jsRequire(NodeSampledCubeTextureNative)
extern var NodeSampledCubeTexture_proto:Dynamic;

class NodeSampledTexture_NodeSampledTexture extends NodeSampledTexture {
    public function new(name:String, textureNode:Dynamic) {
        super();
        __new(name, textureNode);
    }

    function __new(name:String, textureNode:Dynamic) {
        __new_native(name, textureNode);
    }

    @:jsExternal
    static function __new_native(name:String, textureNode:Dynamic):Void {
        Window.instance.js_global.NodeSampledTexture_proto.call(this, name, textureNode);
    }
}

class NodeSampledCubeTexture_NodeSampledCubeTexture extends NodeSampledCubeTexture {
    public function new(name:String, textureNode:Dynamic) {
        super();
        __new(name, textureNode);
    }

    function __new(name:String, textureNode:Dynamic) {
        __new_native(name, textureNode);
    }

    @:jsExternal
    static function __new_native(name:String, textureNode:Dynamic):Void {
        Window.instance.js_global.NodeSampledCubeTexture_proto.call(this, name, textureNode);
    }
}

@:jsRequire(NodeSampledTextureNative)
extern function NodeSampledTexture_Reflect(o:Dynamic):Dynamic {
    return o;
}

@:jsRequire(NodeSampledCubeTextureNative)
extern function NodeSampledCubeTexture_Reflect(o:Dynamic):Dynamic {
    return o;
}

class NodeSampledTexture_Reflect {
    public static function getInstance(obj:NodeSampledTexture):NodeSampledTexture_Reflect {
        return NodeSampledTexture_Reflect(obj);
    }
}

class NodeSampledCubeTexture_Reflect {
    public static function getInstance(obj:NodeSampledCubeTexture):NodeSampledCubeTexture_Reflect {
        return NodeSampledCubeTexture_Reflect(obj);
    }
}

@:jsRequire(NodeSampledTextureNative)
extern function NodeSampledTexture_Construct(name:String, textureNode:Dynamic):NodeSampledTexture {
    return new NodeSampledTexture_NodeSampledTexture(name, textureNode);
}

@:jsRequire(NodeSampledCubeTextureNative)
extern function NodeSampledCubeTexture_Construct(name:String, textureNode:Dynamic):NodeSampledCubeTexture {
    return new NodeSampledCubeTexture_NodeSampledCubeTexture(name, textureNode);
}

class NodeSampledTexture {
    public static function Reflect(obj:NodeSampledTexture):NodeSampledTexture_Reflect {
        return NodeSampledTexture_Reflect(obj);
    }

    public static function Construct(name:String, textureNode:Dynamic):NodeSampledTexture {
        return NodeSampledTexture_Construct(name, textureNode);
    }
}

class NodeSampledCubeTexture {
    public static function Reflect(obj:NodeSampledCubeTexture):NodeSampledCubeTexture_Reflect {
        return NodeSampledCubeTexture_Reflect(obj);
    }

    public static function Construct(name:String, textureNode:Dynamic):NodeSampledCubeTexture {
        return NodeSampledCubeTexture_Construct(name, textureNode);
    }
}