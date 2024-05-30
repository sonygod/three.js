import three.NodeMaterial;
import three.addNodeMaterial;
import three.materialReference;
import three.diffuseColor;
import three.vec3;
import three.MeshMatcapMaterial;
import three.mix;
import three.matcapUV;

class MeshMatcapNodeMaterial extends NodeMaterial {

    public function new(parameters:Dynamic) {

        super();

        this.isMeshMatcapNodeMaterial = true;

        this.lights = false;

        this.setDefaultValues(new MeshMatcapMaterial());

        this.setValues(parameters);

    }

    public function setupVariants(builder:Dynamic) {

        var uv = matcapUV;

        var matcapColor:Dynamic;

        if (builder.material.matcap) {

            matcapColor = materialReference('matcap', 'texture').context({getUV: () -> uv});

        } else {

            matcapColor = vec3(mix(0.2, 0.8, uv.y)); // default if matcap is missing

        }

        diffuseColor.rgb.mulAssign(matcapColor.rgb);

    }

}

addNodeMaterial('MeshMatcapNodeMaterial', MeshMatcapNodeMaterial);