package three.js.examples.jsm.renderers.common;

import js.html.Buffer;

class UniformBuffer extends Buffer {

    public function new(name:String, ?buffer:Buffer) {
        super(name, buffer);
        isUniformBuffer = true;
    }

}