package three.js.examples.jm.nodes.materials;

import three.js.NodeMaterial;
import three.js.accessors.MaterialReferenceNode;
import three.js.core.PropertyNode;
import three.js.shadernode.ShaderNode;
import three.js.math.MathNode;
import three.js.utils.MatcapUVNode;
import three.MeshMatcapMaterial;

class MeshMatcapNodeMaterial extends NodeMaterial {

    public var isMeshMatcapNodeMaterial:Bool = true;
    public var lights:Bool = false;

    public function new(parameters:Dynamic) {
        super();
        setDefaultValues(new MeshMatcapMaterial());
        setValues(parameters);
    }

    public function setupVariants(builder:Dynamic) {
        var uv:MatcapUVNode = MatcapUVNode.create();
        var matcapColor:Vec3;

        if (builder.material.matcap != null) {
            matcapColor = MaterialReferenceNode.create('matcap', 'texture', { getUV: uv.getUV });
        } else {
            matcapColor = new Vec3(MathNode.mix(0.2, 0.8, uv.y));
        }

        diffuseColor.rgb.multiplyAssign(matcapColor.rgb);
    }
}

package three.js.examples.jm.nodes.materials;

private function addNodeMaterial(name:String, material:NodeMaterial) {
    // implementation omitted
}

addNodeMaterial('MeshMatcapNodeMaterial', MeshMatcapNodeMaterial);