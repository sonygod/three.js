class GLBufferAttribute {

    public var isGLBufferAttribute: Bool;
    public var name: String;
    public var buffer: ByteBuffer;
    public var type: String;
    public var itemSize: Int;
    public var elementSize: Int;
    public var count: Int;
    public var version: Int;

    public function new(buffer: ByteBuffer, type: String, itemSize: Int, elementSize: Int, count: Int) {
        this.isGLBufferAttribute = true;
        this.name = "";
        this.buffer = buffer;
        this.type = type;
        this.itemSize = itemSize;
        this.elementSize = elementSize;
        this.count = count;
        this.version = 0;
    }

    public function set needsUpdate(value:Bool): Void {
        if (value == true) this.version++;
    }

    public function setBuffer(buffer: ByteBuffer): GLBufferAttribute {
        this.buffer = buffer;
        return this;
    }

    public function setType(type: String, elementSize: Int): GLBufferAttribute {
        this.type = type;
        this.elementSize = elementSize;
        return this;
    }

    public function setItemSize(itemSize: Int): GLBufferAttribute {
        this.itemSize = itemSize;
        return this;
    }

    public function setCount(count: Int): GLBufferAttribute {
        this.count = count;
        return this;
    }
}
typedef GLBufferAttribute = GLBufferAttribute;