package three.js.examples.jm.nodes.accessors;

import three.js.examples.jm.nodes.ReferenceNode;
//import three.js.examples.core.UniformGroupNode;
//import three.js.examples.core.constants.NodeUpdateType;
import three.js.examples.core.Node;
import three.js.examples.shadernode.ShaderNode;

class MaterialReferenceNode extends ReferenceNode {
    
    public var material:Dynamic;

    public function new(property:String, inputType:Dynamic, material:Dynamic = null) {
        super(property, inputType, material);
        this.material = material;
        //this.updateType = NodeUpdateType.RENDER;
    }

    /*override public function setNodeType(node:Dynamic) {
        super.setNodeType(node);
        node.groupNode = renderGroup;
    }*/

    public function updateReference(state:Dynamic) {
        this.reference = this.material != null ? this.material : state.material;
        return this.reference;
    }
}

//export
var materialReference = function(name:String, type:Dynamic, material:Dynamic) {
    return ShaderNode.nodeObject(new MaterialReferenceNode(name, type, material));
}

Node.addNodeClass('MaterialReferenceNode', MaterialReferenceNode);