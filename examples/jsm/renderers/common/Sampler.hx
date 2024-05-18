package three.js.examples.jm.renderers.common;

import three.js.examples.jm.renderers.common.Binding;

class Sampler extends Binding {
    public var texture:Dynamic;
    public var version:Int;
    public var isSampler:Bool;

    public function new(name:String, texture:Dynamic) {
        super(name);
        this.texture = texture;
        this.version = if (texture != null) texture.version else 0;
        this.isSampler = true;
    }
}