package three.js.examples.jm.renderers.common;

import three.js.examples.jm.Buffer;

class StorageBuffer extends Buffer {
    public var attribute:Dynamic;
    public var isStorageBuffer:Bool;

    public function new(name:String, attribute:Dynamic = null) {
        super(name, attribute != null ? attribute.array : null);
        this.attribute = attribute;
        this.isStorageBuffer = true;
    }
}