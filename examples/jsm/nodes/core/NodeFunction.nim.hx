class NodeFunction {
    public var type:String;
    public var inputs:Dynamic;
    public var name:String;
    public var presicion:String;

    public function new(type:String, inputs:Dynamic, name:String = "", presicion:String = "") {
        this.type = type;
        this.inputs = inputs;
        this.name = name;
        this.presicion = presicion;
    }

    public function getCode():Void {
        trace.warn("Abstract function.");
    }

    public static var isNodeFunction(default, null):Bool = true;
}