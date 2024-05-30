import three.nodes.Nodes;
import three.objects.QuadMesh;

class PostProcessing {

    var renderer:Dynamic;
    var outputNode:Dynamic;

    public function new(renderer:Dynamic, outputNode:Dynamic = vec4(0, 0, 1, 1)) {
        this.renderer = renderer;
        this.outputNode = outputNode;
    }

    public function render() {
        var quadMesh = new QuadMesh(new NodeMaterial());
        quadMesh.material.fragmentNode = this.outputNode;
        quadMesh.render(this.renderer);
    }

    public function renderAsync() {
        var quadMesh = new QuadMesh(new NodeMaterial());
        quadMesh.material.fragmentNode = this.outputNode;
        return quadMesh.renderAsync(this.renderer);
    }
}