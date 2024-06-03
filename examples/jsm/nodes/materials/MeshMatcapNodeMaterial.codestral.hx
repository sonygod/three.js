import NodeMaterial;
import NodeMaterial.addNodeMaterial;
import MaterialReferenceNode.materialReference;
import PropertyNode.diffuseColor;
import ShaderNode.vec3;
import three.MeshMatcapMaterial;
import MathNode.mix;
import MatcapUVNode.matcapUV;

class MeshMatcapNodeMaterial extends NodeMaterial {

    public function new(parameters:Dynamic) {
        super();

        this.isMeshMatcapNodeMaterial = true;
        this.lights = false;

        var defaultValues = MeshMatcapMaterial.new();
        this.setDefaultValues(defaultValues);
        this.setValues(parameters);
    }

    public function setupVariants(builder:NodeBuilder) {
        var uv = matcapUV;

        var matcapColor:ShaderNode;

        if (builder.material.matcap != null) {
            matcapColor = materialReference('matcap', 'texture').context({
                getUV: function() {
                    return uv;
                }
            });
        } else {
            matcapColor = vec3(mix(0.2, 0.8, uv.y)); // default if matcap is missing
        }

        diffuseColor.rgb.mulAssign(matcapColor.rgb);
    }
}

addNodeMaterial('MeshMatcapNodeMaterial', MeshMatcapNodeMaterial);