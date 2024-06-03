class NodeFunction {
    public var type: String;
    public var inputs: Array<Dynamic>;
    public var name: String;
    public var precision: String;

    public function new(type: String, inputs: Array<Dynamic>, ?name: String, ?precision: String) {
        this.type = type;
        this.inputs = inputs;
        this.name = name != null ? name : '';
        this.precision = precision != null ? precision : '';
    }

    public function getCode(): Void {
        trace('Abstract function.');
    }
}

NodeFunction.isNodeFunction = true;