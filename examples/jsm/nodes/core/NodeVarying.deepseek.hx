import NodeVar from './NodeVar.hx';

class NodeVarying extends NodeVar {

	public function new(name:String, type:String) {

		super(name, type);

		this.needsInterpolation = false;

		this.isNodeVarying = true;

	}

}

typedef NodeVarying_hx = NodeVarying;