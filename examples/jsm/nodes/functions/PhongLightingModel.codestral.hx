import three.js.nodes.core.LightingModel;
import three.js.nodes.functions.BSDF.F_Schlick;
import three.js.nodes.functions.BSDF.BRDF_Lambert;
import three.js.nodes.core.PropertyNode;
import three.js.nodes.accessors.NormalNode;
import three.js.nodes.accessors.MaterialNode;
import three.js.nodes.core.PropertyNode;
import three.js.nodes.accessors.PositionNode;
import three.js.shadernode.ShaderNode;

class G_BlinnPhong_Implicit {
    public static function call(): Float {
        return 0.25;
    }
}

class D_BlinnPhong {
    public static function call(dotNH: Float): Float {
        return (PropertyNode.shininess * 0.5 + 1.0) * (1.0 / Math.PI) * Math.pow(dotNH, PropertyNode.shininess);
    }
}

class BRDF_BlinnPhong {
    public static function call(lightDirection: Vector3): Float {
        var halfDir: Vector3 = lightDirection.add(PositionNode.positionViewDirection).normalize();
        var dotNH: Float = NormalNode.transformedNormalView.dot(halfDir).clamp();
        var dotVH: Float = PositionNode.positionViewDirection.dot(halfDir).clamp();
        var F: Float = F_Schlick.call({f0: PropertyNode.specularColor, f90: 1.0, dotVH: dotVH});
        var G: Float = G_BlinnPhong_Implicit.call();
        var D: Float = D_BlinnPhong.call(dotNH);
        return F * G * D;
    }
}

class PhongLightingModel extends LightingModel {
    public var specular: Bool;

    public function new(specular: Bool = true) {
        super();
        this.specular = specular;
    }

    public function direct(lightDirection: Vector3, lightColor: Color, reflectedLight: ReflectedLight) {
        var dotNL: Float = NormalNode.transformedNormalView.dot(lightDirection).clamp();
        var irradiance: Color = lightColor.multiplyScalar(dotNL);
        reflectedLight.directDiffuse.add(irradiance.multiply(BRDF_Lambert.call({diffuseColor: PropertyNode.diffuseColor.rgb})));
        if (this.specular) {
            reflectedLight.directSpecular.add(irradiance.multiply(BRDF_BlinnPhong.call(lightDirection)).multiplyScalar(MaterialNode.materialSpecularStrength));
        }
    }

    public function indirectDiffuse(irradiance: Color, reflectedLight: ReflectedLight) {
        reflectedLight.indirectDiffuse.add(irradiance.multiply(BRDF_Lambert.call({diffuseColor: PropertyNode.diffuseColor})));
    }
}