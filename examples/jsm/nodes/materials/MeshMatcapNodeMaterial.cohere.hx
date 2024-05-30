import NodeMaterial from './NodeMaterial.hx';
import { materialReference } from '../accessors/MaterialReferenceNode.hx';
import { diffuseColor } from '../core/PropertyNode.hx';
import { vec3 } from '../shadernode/ShaderNode.hx';
import { MeshMatcapMaterial } from 'three';
import { mix } from '../math/MathNode.hx';
import { matcapUV } from '../utils/MatcapUVNode.hx';

class MeshMatcapNodeMaterial extends NodeMaterial {
    public var isMeshMatcapNodeMaterial: Bool = true;
    public var lights: Bool = false;

    public function new(parameters: Dynamic = null) {
        super();
        this.setDefaultValues(new MeshMatcapMaterial());
        if (parameters != null) this.setValues(parameters);
    }

    public function setupVariants(builder: { material: { matcap: Bool } }): Void {
        var uv = matcapUV;
        var matcapColor: { context: { getUV: { (): { y: Float } -> { x: Float, y: Float } } } };
        if (builder.material.matcap) {
            matcapColor = materialReference('matcap', 'texture').context({ getUV: function(): { y: Float } -> { x: Float, y: Float } { return uv; } });
        } else {
            matcapColor = vec3(mix(0.2, 0.8, uv.y)); // default if matcap is missing
        }
        diffuseColor.rgb.mulAssign(matcapColor.rgb);
    }
}

class haxe_export_default {
    public static var __default__: MeshMatcapNodeMaterial = MeshMatcapNodeMaterial;
}

class haxe_export_addNodeMaterial {
    public static function addNodeMaterial(name: String, material: MeshMatcapNodeMaterial): Void {
        // add node material logic here
    }
}

haxe_export_addNodeMaterial.addNodeMaterial('MeshMatcapNodeMaterial', MeshMatcapNodeMaterial);