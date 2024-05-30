import h3d.impl.Mesh from h3d.impl.Mesh;
import h3d.NodeMaterial from h3d.NodeMaterial;
import h3d.impl.QuadMesh from h3d.impl.QuadMesh;

class PostProcessing {
    public var renderer:Renderer;
    public var outputNode:Float4;

    public function new(renderer:Renderer, ?outputNode:Float4) {
        this.renderer = renderer;
        this.outputNode = outputNode ?? new Float4(0., 0., 1., 1.);
    }

    public function render():Void {
        var quadMesh = new QuadMesh(new NodeMaterial());
        quadMesh.material.fragmentNode = this.outputNode;
        quadMesh.render(this.renderer);
    }

    public function renderAsync():Future<Void> {
        var quadMesh = new QuadMesh(new NodeMaterial());
        quadMesh.material.fragmentNode = this.outputNode;
        return quadMesh.renderAsync(this.renderer);
    }
}