class SingleUniform {

    public var id:String;
    public var addr:Int;
    public var cache:Array<Dynamic>;
    public var type:String;
    public var setValue:Dynamic;

    public function new(id:String, activeInfo:Dynamic, addr:Int) {

        this.id = id;
        this.addr = addr;
        this.cache = [];
        this.type = activeInfo.type;
        this.setValue = getSingularSetter(activeInfo.type);

        // this.path = activeInfo.name; // DEBUG

    }

}