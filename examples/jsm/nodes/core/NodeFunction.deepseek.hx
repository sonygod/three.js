class NodeFunction {

    public var type:String;
    public var inputs:Array<Dynamic>;
    public var name:String;
    public var presicion:String;

    public function new(type:String, inputs:Array<Dynamic>, name:String = '', presicion:String = '') {
        this.type = type;
        this.inputs = inputs;
        this.name = name;
        this.presicion = presicion;
    }

    public function getCode(name:String = this.name):Void {
        trace('Abstract function.');
    }

    static public var isNodeFunction:Bool = true;

}