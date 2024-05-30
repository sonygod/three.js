import vec4.NodeMaterial;
import QuadMesh;

var quadMesh = new QuadMesh(new NodeMaterial());

class PostProcessing {

    var renderer:Renderer;
    var outputNode:Vec4;

    public function new(renderer:Renderer, outputNode:Vec4 = vec4(0, 0, 1, 1)) {

        this.renderer = renderer;
        this.outputNode = outputNode;

    }

    public function render() {

        quadMesh.material.fragmentNode = this.outputNode;

        quadMesh.render(this.renderer);

    }

    public function renderAsync() {

        quadMesh.material.fragmentNode = this.outputNode;

        return quadMesh.renderAsync(this.renderer);

    }

}

export default PostProcessing;