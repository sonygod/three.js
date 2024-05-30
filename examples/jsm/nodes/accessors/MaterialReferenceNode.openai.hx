package three.js.examples.jsm.nodes.accessors;

import three.js.examples.jsm.nodes.ReferenceNode;
import three.js.examples.core.Node;
import three.js.examples.shadernode.ShaderNode;

class MaterialReferenceNode extends ReferenceNode {

    var material:Null<Material>;

    public function new(property:String, inputType:String, material:Null<Material> = null) {
        super(property, inputType, material);
        this.material = material;
    }

    override function updateReference(state:Dynamic):Dynamic {
        return this.material != null ? this.material : state.material;
    }

    // Note: I commented out the setNodeType method since it is not used anywhere
    // and renderGroup is not defined in this file. If you need it, you can uncomment
    // and add the necessary imports.
    /*override function setNodeType(node:Node):Void {
        super.setNodeType(node);
        node.groupNode = renderGroup;
    }*/
}

// Register the node class
Node.addNodeClass('MaterialReferenceNode', MaterialReferenceNode);

// Create a shortcut function
inline function materialReference(name:String, type:String, material:Null<Material> = null):ShaderNode {
    return ShaderNode.nodeObject(new MaterialReferenceNode(name, type, material));
}