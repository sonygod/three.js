package three.js.examples.jm.nodes.functions;

import three.js.core.LightingModel;
import three.js.nodes.BSDF.F_Schlick;
import three.js.nodes.BSDF.BRDF_Lambert;
import three.js.core.PropertyNode;
import three.js.accessors.NormalNode;
import three.js.accessors.MaterialNode;
import three.js.accessors.PositionNode;
import three.js.shadernode.ShaderNode;

class PhongLightingModel extends LightingModel {
    public var specular:Bool;

    public function new(specular:Bool = true) {
        super();
        this.specular = specular;
    }

    public function direct(data:{ lightDirection:Vector3, lightColor:Vector3, reflectedLight:ReflectedLight }) {
        var dotNL:Float = transformedNormalView.dot(data.lightDirection).clamp();
        var irradiance:Vector3 = dotNL * data.lightColor;

        data.reflectedLight.directDiffuse += irradiance * BRDF_Lambert(diffuseColor.rgb);

        if (this.specular) {
            data.reflectedLight.directSpecular += irradiance * BRDF_BlinnPhong(data.lightDirection) * materialSpecularStrength;
        }
    }

    public function indirectDiffuse(data:{ irradiance:Vector3, reflectedLight:ReflectedLight }) {
        data.reflectedLight.indirectDiffuse += data.irradiance * BRDF_Lambert(diffuseColor);
    }
}

// Functions
private function G_BlinnPhong_Implicit():Float {
    return 0.25;
}

private function D_BlinnPhong(data:{ dotNH:Float }):Float {
    return shininess * 0.5 + 1.0 * Math.PI * Math.pow(data.dotNH, shininess);
}

private function BRDF_BlinnPhong(data:{ lightDirection:Vector3 }):Float {
    var halfDir:Vector3 = data.lightDirection.add(positionViewDirection).normalize();
    var dotNH:Float = transformedNormalView.dot(halfDir).clamp();
    var dotVH:Float = positionViewDirection.dot(halfDir).clamp();

    var F:Float = F_Schlick({ f0: specularColor, f90: 1.0, dotVH: dotVH });
    var G:Float = G_BlinnPhong_Implicit();
    var D:Float = D_BlinnPhong({ dotNH: dotNH });

    return F * G * D;
}