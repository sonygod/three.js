package three.js.nodes.accessors;

import three.js.nodes.core.Node;
import three.js.nodes.core.ReferenceNode;
import three.js.nodes.shadernode.ShaderNode;

class RendererReferenceNode extends ReferenceNode {
    
    public var renderer:Dynamic;

    public function new(property:String, inputType:Dynamic, renderer:Dynamic = null) {
        super(property, inputType, renderer);
        this.renderer = renderer;
    }

    public function updateReference(state:Dynamic):Dynamic {
        this.reference = (renderer != null) ? renderer : state.renderer;
        return reference;
    }
}

// Export the class
extern class RendererReferenceNode {
    public function new(property:String, inputType:Dynamic, renderer:Dynamic = null);
    public function updateReference(state:Dynamic):Dynamic;
}

// Add node class to Node.js registry
Node.addNodeClass("RendererReferenceNode", RendererReferenceNode);

// Create a node object factory function
inline function rendererReference(name:String, type:Dynamic, renderer:Dynamic = null):ShaderNode {
    return nodeObject(new RendererReferenceNode(name, type, renderer));
}