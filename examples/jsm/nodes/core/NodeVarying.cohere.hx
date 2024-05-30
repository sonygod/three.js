import NodeVar from './NodeVar.hx';

class NodeVarying extends NodeVar {
	public function new(name:String, type:Int) {
		super(name, type);
		this.needsInterpolation = false;
		this.isNodeVarying = true;
	}
}

export default NodeVarying;