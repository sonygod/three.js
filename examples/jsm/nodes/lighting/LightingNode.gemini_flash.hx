import Node from "../core/Node";

class LightingNode extends Node {

	public function new() {
		super("vec3");
	}

	public function generate(builder: Dynamic): Void {
		Sys.println("Abstract function.");
	}

}

Node.addNodeClass("LightingNode", LightingNode);