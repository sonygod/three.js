package three.js.examples.jsm.nodes.functions;

import three.js.examples.jsm.nodes.BRDF.BRDF_Lambert;
import three.js.examples.jsm.nodes.BRDF.BRDF_GGX;
import three.js.examples.jsm.nodes.BRDF.DFGApprox;
import three.js.examples.jsm.nodes.BRDF.EnvironmentBRDF;
import three.js.examples.jsm.nodes.BRDF.F_Schlick;
import three.js.examples.jsm.nodes.BRDF.Schlick_to_F0;
import three.js.examples.jsm.nodes.BRDF.BRDF_Sheen;
import three.js.examples.jsm.nodes.LightingModel;
import three.js.examples.jsm.nodes.PropertyNode;
import three.js.examples.jsm.accessors.NormalNode;
import three.js.examples.jsm.accessors.PositionNode;
import three.js.examples.jsm.accessors.CameraNode;
import three.js.examples.jsm.accessors.ModelNode;
import three.js.examples.jsm.display.ViewportNode;
import three.js.examples.jsm.display.ViewportTextureNode;
import three.js.examples.jsm.math.CondNode;
import three.js.examples.jsm.math.MathNode;
import three.js.examples.jsm.shadernode.ShaderNode;

class PhysicalLightingModel extends LightingModel {
    public var clearcoat:Bool;
    public var sheen:Bool;
    public var iridescence:Bool;
    public var anisotropy:Bool;
    public var transmission:Bool;

    public var clearcoatRadiance:Vec3;
    public var clearcoatSpecularDirect:Vec3;
    public var clearcoatSpecularIndirect:Vec3;
    public var sheenSpecularDirect:Vec3;
    public var sheenSpecularIndirect:Vec3;
    public var iridescenceFresnel:Vec3;
    public var iridescenceF0:Vec3;

    public function new(clearcoat:Bool = false, sheen:Bool = false, iridescence:Bool = false, anisotropy:Bool = false, transmission:Bool = false) {
        super();
        this.clearcoat = clearcoat;
        this.sheen = sheen;
        this.iridescence = iridescence;
        this.anisotropy = anisotropy;
        this.transmission = transmission;

        if (clearcoat) {
            clearcoatRadiance = new Vec3().temp('clearcoatRadiance');
            clearcoatSpecularDirect = new Vec3().temp('clearcoatSpecularDirect');
            clearcoatSpecularIndirect = new Vec3().temp('clearcoatSpecularIndirect');
        }

        if (sheen) {
            sheenSpecularDirect = new Vec3().temp('sheenSpecularDirect');
            sheenSpecularIndirect = new Vec3().temp('sheenSpecularIndirect');
        }

        if (iridescence) {
            // ...
        }
    }

    public function start(context:Dynamic) {
        // ...
    }

    public function computeMultiscattering(singleScatter:Vec3, multiScatter:Vec3, specularF90:Float) {
        // ...
    }

    public function direct(context:Dynamic) {
        // ...
    }

    public function indirectDiffuse(context:Dynamic) {
        // ...
    }

    public function indirectSpecular(context:Dynamic) {
        // ...
    }

    public function ambientOcclusion(context:Dynamic) {
        // ...
    }

    public function finish(context:Dynamic) {
        // ...
    }
}