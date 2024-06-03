import js.three.nodes.Nodes.vec4;
import js.three.nodes.Nodes.NodeMaterial;
import js.three.objects.QuadMesh;
import js.three.renderers.Renderer;

class PostProcessing {
    private var quadMesh:QuadMesh = new QuadMesh(new NodeMaterial());
    private var renderer:Renderer;
    private var outputNode:vec4;

    public function new(renderer:Renderer, outputNode:vec4 = vec4(0, 0, 1, 1)) {
        this.renderer = renderer;
        this.outputNode = outputNode;
    }

    public function render():Void {
        quadMesh.material.fragmentNode = this.outputNode;
        quadMesh.render(this.renderer);
    }

    public function renderAsync():Dynamic {
        quadMesh.material.fragmentNode = this.outputNode;
        return quadMesh.renderAsync(this.renderer);
    }
}