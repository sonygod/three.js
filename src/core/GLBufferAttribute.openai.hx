package three.js.src.core;

class GLBufferAttribute {

    public var isGLBufferAttribute:Bool = true;

    public var name:String = '';

    public var buffer:Dynamic;
    public var type:Dynamic;
    public var itemSize:Int;
    public var elementSize:Int;
    public var count:Int;

    public var version:Int = 0;

    public function new(buffer:Dynamic, type:Dynamic, itemSize:Int, elementSize:Int, count:Int) {
        this.buffer = buffer;
        this.type = type;
        this.itemSize = itemSize;
        this.elementSize = elementSize;
        this.count = count;
    }

    public function set_needsUpdate(value:Bool) {
        if (value) {
            version++;
        }
    }

    public function setBuffer(buffer:Dynamic):GLBufferAttribute {
        this.buffer = buffer;
        return this;
    }

    public function setType(type:Dynamic, elementSize:Int):GLBufferAttribute {
        this.type = type;
        this.elementSize = elementSize;
        return this;
    }

    public function setItemSize(itemSize:Int):GLBufferAttribute {
        this.itemSize = itemSize;
        return this;
    }

    public function setCount(count:Int):GLBufferAttribute {
        this.count = count;
        return this;
    }
}