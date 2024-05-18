package three.js.examples.jm.renderers.common;

import three.js.examples.jm.renderers.common.Buffer;

class UniformBuffer extends Buffer {

    public var isUniformBuffer:Bool;

    public function new(name:String, ?buffer:Dynamic) {
        super(name, buffer);
        this.isUniformBuffer = true;
    }

}

// Note: In Haxe, we don't need to use the "export default" syntax,
// as Haxe modules are self-contained and can be imported directly.