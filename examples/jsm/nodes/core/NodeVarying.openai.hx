package three.js.nodes.core;

import three.js.nodes.core.NodeVar;

class NodeVarying extends NodeVar {

	public function new(name:String, type:String) {
		super(name, type);
		needsInterpolation = false;
		isNodeVarying = true;
	}

}