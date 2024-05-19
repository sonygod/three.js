package three.js.src.renderers.webgl;

class PureArrayUniform {
    public var id:String;
    public var addr:Int;
    public var cache:Array<Dynamic>;
    public var type:String;
    public var size:Int;
    public var setValue:Dynamic->Void;

    public function new(id:String, activeInfo:Dynamic, addr:Int) {
        this.id = id;
        this.addr = addr;
        this.cache = [];
        this.type = activeInfo.type;
        this.size = activeInfo.size;
        this.setValue = getPureArraySetter(activeInfo.type);
        // this.path = activeInfo.name; // DEBUG
    }
}