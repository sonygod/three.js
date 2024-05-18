package three.js.examples.jsm.nodes.core;

import three.js.examples.jsm.nodes.core.NodeVar;

class NodeVarying extends NodeVar {
    public function new(name:String, type:String) {
        super(name, type);
        this.needsInterpolation = false;
        this.isNodeVarying = true;
    }
}