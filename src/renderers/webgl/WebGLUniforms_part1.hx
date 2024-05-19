package three.renderers.webgl;

class SingleUniform {
    public var id:String;
    public var addr:Int;
    public var cache:Array<Dynamic>;
    public var type:Int;
    public var setValue:Dynamic->Void;

    public function new(id:String, activeInfo:Dynamic, addr:Int) {
        this.id = id;
        this.addr = addr;
        cache = new Array<Dynamic>();
        type = activeInfo.type;
        setValue = getSingularSetter(activeInfo.type);
        // this.path = activeInfo.name; // DEBUG
    }
}