package three.js.nodes.materials;

import three.js.nodes.NodeMaterial;
import three.js.accessors.MaterialReferenceNode;
import three.js.core.PropertyNode;
import three.js.shadernode.ShaderNode;
import three.js.math.MathNode;
import three.js.utils.MatcapUVNode;
import three.js.Material;

class MeshMatcapNodeMaterial extends NodeMaterial {
    public var isMeshMatcapNodeMaterial:Bool;

    public function new(parameters:Dynamic) {
        super();
        isMeshMatcapNodeMaterial = true;
        lights = false;
        setDefaultValues(new MeshMatcapMaterial());
        setValues(parameters);
    }

    override public function setupVariants(builder:Dynamic) {
        var uv:MatcapUVNode = MatcapUVNode.getInstance();
        var matcapColor:ShaderNode;

        if (builder.material.matcap != null) {
            matcapColor = MaterialReferenceNode.materialReference('matcap', 'texture').context({ getUV: uv.getUV });
        } else {
            matcapColor = vec3(MathNode.mix(0.2, 0.8, uv.getUV().y)); // default if matcap is missing
        }

        diffuseColor.rgb.mulAssign(matcapColor.rgb);
    }
}

// Initialize and register the material
var meshMatcapNodeMaterial:MeshMatcapNodeMaterial = new MeshMatcapNodeMaterial({});
NodeMaterial.addNodeMaterial('MeshMatcapNodeMaterial', meshMatcapNodeMaterial);