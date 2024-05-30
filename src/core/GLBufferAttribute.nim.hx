class GLBufferAttribute {
    public var isGLBufferAttribute:Bool = true;
    public var name:String = '';
    public var buffer:Dynamic;
    public var type:Dynamic;
    public var itemSize:Dynamic;
    public var elementSize:Dynamic;
    public var count:Dynamic;
    public var version:Dynamic = 0;

    public function new(buffer:Dynamic, type:Dynamic, itemSize:Dynamic, elementSize:Dynamic, count:Dynamic) {
        this.buffer = buffer;
        this.type = type;
        this.itemSize = itemSize;
        this.elementSize = elementSize;
        this.count = count;
    }

    public function set needsUpdate(value:Bool) {
        if (value == true) this.version++;
    }

    public function setBuffer(buffer:Dynamic):GLBufferAttribute {
        this.buffer = buffer;
        return this;
    }

    public function setType(type:Dynamic, elementSize:Dynamic):GLBufferAttribute {
        this.type = type;
        this.elementSize = elementSize;
        return this;
    }

    public function setItemSize(itemSize:Dynamic):GLBufferAttribute {
        this.itemSize = itemSize;
        return this;
    }

    public function setCount(count:Dynamic):GLBufferAttribute {
        this.count = count;
        return this;
    }
}