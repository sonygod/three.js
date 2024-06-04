import nodes.Nodes;
import objects.QuadMesh;

class PostProcessing {

	public var renderer:Dynamic;
	public var outputNode:Nodes.vec4;

	public function new(renderer:Dynamic, outputNode:Nodes.vec4 = Nodes.vec4(0, 0, 1, 1)) {
		this.renderer = renderer;
		this.outputNode = outputNode;
	}

	public function render() {
		QuadMesh.material.fragmentNode = this.outputNode;
		QuadMesh.render(this.renderer);
	}

	public function renderAsync():Dynamic {
		QuadMesh.material.fragmentNode = this.outputNode;
		return QuadMesh.renderAsync(this.renderer);
	}

}