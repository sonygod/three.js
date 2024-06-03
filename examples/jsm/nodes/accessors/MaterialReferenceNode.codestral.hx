import ReferenceNode from 'jsm.nodes.accessors.ReferenceNode';
//import renderGroup from 'jsm.core.UniformGroupNode.renderGroup';
//import NodeUpdateType from 'jsm.core.constants.NodeUpdateType';
import Node from 'jsm.core.Node';
import { nodeObject } from 'jsm.shadernode.ShaderNode';

class MaterialReferenceNode extends ReferenceNode {

    public var material:Dynamic;

    public function new(property:String, inputType:String, material:Dynamic = null) {
        super(property, inputType, material);
        this.material = material;
        //this.updateType = NodeUpdateType.RENDER;
    }

    /*public function setNodeType(node:Dynamic):Void {
        super.setNodeType(node);
        node.groupNode = renderGroup;
    }*/

    public function updateReference(state:Dynamic):Dynamic {
        this.reference = this.material != null ? this.material : state.material;
        return this.reference;
    }

}

export default MaterialReferenceNode;

function materialReference(name:String, type:String, material:Dynamic):Dynamic {
    return nodeObject(new MaterialReferenceNode(name, type, material));
}

Node.addNodeClass('MaterialReferenceNode', MaterialReferenceNode);