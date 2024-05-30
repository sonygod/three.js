import LightingModel from '../core/LightingModel.js';
import F_Schlick from './BSDF/F_Schlick.js';
import BRDF_Lambert from './BSDF/BRDF_Lambert.js';
import { diffuseColor } from '../core/PropertyNode.js';
import { transformedNormalView } from '../accessors/NormalNode.js';
import { materialSpecularStrength } from '../accessors/MaterialNode.js';
import { shininess, specularColor } from '../core/PropertyNode.js';
import { positionViewDirection } from '../accessors/PositionNode.js';
import { tslFn, float } from '../shadernode/ShaderNode.js';

@:final
static function G_BlinnPhong_Implicit():Float {
    return 0.25;
}

static function D_BlinnPhong(dotNH:Float):Float {
    return (shininess * 0.5 + 1.0) * (1 / Math.PI) * Math.pow(dotNH, shininess);
}

static function BRDF_BlinnPhong(lightDirection:Vector3):Float {
    var halfDir:Vector3 = lightDirection + positionViewDirection;
    halfDir.normalize();

    var dotNH:Float = transformedNormalView.dot(halfDir).clamp();
    var dotVH:Float = positionViewDirection.dot(halfDir).clamp();

    var F:Float = F_Schlick(specularColor, 1.0, dotVH);
    var G:Float = G_BlinnPhong_Implicit();
    var D:Float = D_BlinnPhong(dotNH);

    return F * G * D;
}

class PhongLightingModel extends LightingModel {

    var specular:Bool;

    public function new(specular:Bool = true) {
        super();
        this.specular = specular;
    }

    public function direct(lightDirection:Vector3, lightColor:Color, reflectedLight:Light):Void {
        var dotNL:Float = transformedNormalView.dot(lightDirection).clamp();
        var irradiance:Color = dotNL * lightColor;

        reflectedLight.directDiffuse += irradiance * BRDF_Lambert(diffuseColor.rgb);

        if (this.specular) {
            reflectedLight.directSpecular += irradiance * BRDF_BlinnPhong(lightDirection) * materialSpecularStrength;
        }
    }

    public function indirectDiffuse(irradiance:Color, reflectedLight:Light):Void {
        reflectedLight.indirectDiffuse += irradiance * BRDF_Lambert(diffuseColor);
    }
}

typedef Vector3 = {x:Float, y:Float, z:Float};
typedef Color = {r:Float, g:Float, b:Float};
typedef Light = {directDiffuse:Color, directSpecular:Color, indirectDiffuse:Color};