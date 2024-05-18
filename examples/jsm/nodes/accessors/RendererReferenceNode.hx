package three.js.examples.jsm.nodes.accessors;

import three.js.examples.jsm.nodes.ReferenceNode;
import three.js.core.Node;
import three.js.shadernode.ShaderNode;

class RendererReferenceNode extends ReferenceNode {
    public var renderer:Dynamic;

    public function new(property:Dynamic, inputType:Dynamic, ?renderer:Dynamic) {
        super(property, inputType, renderer);
        this.renderer = renderer;
    }

    public function updateReference(state:Dynamic):Dynamic {
        this.reference = (this.renderer != null) ? this.renderer : state.renderer;
        return this.reference;
    }
}

@:export
var rendererReference = function(name:Dynamic, type:Dynamic, ?renderer:Dynamic) {
    return ShaderNode.nodeObject(new RendererReferenceNode(name, type, renderer));
}

@:init
three.js.core.Node.addNodeClass("RendererReferenceNode", RendererReferenceNode);