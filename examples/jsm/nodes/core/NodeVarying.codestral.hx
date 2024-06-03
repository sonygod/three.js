import NodeVar from 'three.js.examples.jsm.nodes.core.NodeVar';

class NodeVarying extends NodeVar {

    public function new(name:String, type:Dynamic) {
        super(name, type);
        this.needsInterpolation = false;
        this.isNodeVarying = true;
    }

}