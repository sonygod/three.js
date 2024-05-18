package three.js.examples.jm.renderers.common;

import js.html.WebGLRenderingContext;
import three.nodes Nodes;
import three.objects.QuadMesh;

class PostProcessing {
	
	var renderer: WebGLRenderingContext;
	var outputNode: Vec4;
	var quadMesh: QuadMesh;

	public function new(renderer: WebGLRenderingContext, ?outputNode: Vec4) {
		this.renderer = renderer;
		this.outputNode = if (outputNode != null) outputNode else new Vec4(0, 0, 1, 1);
		this.quadMesh = new QuadMesh(new NodeMaterial());
	}

	public function render(): Void {
		quadMesh.material.fragmentNode = outputNode;
		quadMesh.render(renderer);
	}

	public function renderAsync(): Promise<Void> {
		quadMesh.material.fragmentNode = outputNode;
		return quadMesh.renderAsync(renderer);
	}
}