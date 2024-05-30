class NodeVar {

    public var isNodeVar:Bool;
    public var name:String;
    public var type:String;

    public function new(name:String, type:String) {
        this.isNodeVar = true;
        this.name = name;
        this.type = type;
    }

}