import NodeVar.NodeVar;

class NodeVarying extends NodeVar {

    public var needsInterpolation:Bool;
    public var isNodeVarying:Bool;

    public function new(name:String, type:String) {
        super(name, type);

        this.needsInterpolation = false;
        this.isNodeVarying = true;
    }

}