package three.js.src.renderers.shaders.ShaderChunk.lights_physical_pars_fragment;

import three[js.Three];
import three.math.Vector3;

class PhysicalMaterial {
    public var diffuseColor:Vector3;
    public var roughness:Float;
    public var specularColor:Vector3;
    public var specularF90:Float;
    public var dispersion:Float;

    #if USE_CLEARCOAT
    public var clearcoat:Float;
    public var clearcoatRoughness:Float;
    public var clearcoatF0:Vector3;
    public var clearcoatF90:Float;
    #end

    #if USE_IRIDESCENCE
    public var iridescence:Float;
    public var iridescenceIOR:Float;
    public var iridescenceThickness:Float;
    public var iridescenceFresnel:Vector3;
    public var iridescenceF0:Vector3;
    #end

    #if USE_SHEEN
    public var sheenColor:Vector3;
    public var sheenRoughness:Float;
    #end

    #if IOR
    public var ior:Float;
    #end

    #if USE_TRANSMISSION
    public var transmission:Float;
    public var transmissionAlpha:Float;
    public var thickness:Float;
    public var attenuationDistance:Float;
    public var attenuationColor:Vector3;
    #end

    #if USE_ANISOTROPY
    public var anisotropy:Float;
    public var alphaT:Float;
    public var anisotropyT:Vector3;
    public var anisotropyB:Vector3;
    #end
}

class ShaderChunk {
    static function Schlick_to_F0(f:Vector3, f90:Float, dotVH:Float):Vector3 {
        var x = Math.max(0.0, 1.0 - dotVH);
        var x2 = x * x;
        var x5 = Math.max(x * x2 * x2, 0.0);
        return (f - f90 * x5) / (1.0 - x5);
    }

    static function V_GGX_SmithCorrelated(alpha:Float, dotNL:Float, dotNV:Float):Float {
        var a2 = alpha * alpha;
        var gv = dotNL * Math.sqrt(a2 + (1.0 - a2) * dotNV * dotNV);
        var gl = dotNV * Math.sqrt(a2 + (1.0 - a2) * dotNL * dotNL);
        return 0.5 / Math.max(gv + gl, 1e-4);
    }

    static function D_GGX(alpha:Float, dotNH:Float):Float {
        var a2 = alpha * alpha;
        var denom = dotNH * dotNH * (a2 - 1.0) + 1.0;
        return RECIPROCAL_PI * a2 / (denom * denom);
    }

    #if USE_ANISOTROPY
    static function V_GGX_SmithCorrelated_Anisotropic(alphaT:Float, alphaB:Float, dotTV:Float, dotBV:Float, dotTL:Float, dotBL:Float, dotNV:Float, dotNL:Float):Float {
        var gv = dotNL * Math.sqrt(alphaT * dotTV * dotTV + alphaB * dotBV * dotBV + dotNV * dotNV);
        var gl = dotNV * Math.sqrt(alphaT * dotTL * dotTL + alphaB * dotBL * dotBL + dotNL * dotNL);
        var v = 0.5 / Math.max(gv + gl, 1e-4);
        return Math.max(v, 0.0);
    }

    static function D_GGX_Anisotropic(alphaT:Float, alphaB:Float, dotNH:Float, dotTH:Float, dotBH:Float):Float {
        var a2 = alphaT * alphaB;
        var v = new Vector3(alphaB * dotTH, alphaT * dotBH, a2 * dotNH);
        var v2 = v.dot(v);
        var w2 = a2 / v2;
        return RECIPROCAL_PI * a2 * w2 * w2;
    }
    #end

    static function BRDF_GGX(lightDir:Vector3, viewDir:Vector3, normal:Vector3, material:PhysicalMaterial):Vector3 {
        var f0 = material.specularColor;
        var f90 = material.specularF90;
        var roughness = material.roughness;

        var alpha = roughness * roughness;
        var halfDir = (lightDir + viewDir).normalize();

        var dotNL = Math.max(0.0, normal.dot(lightDir));
        var dotNV = Math.max(0.0, normal.dot(viewDir));
        var dotNH = Math.max(0.0, normal.dot(halfDir));
        var dotVH = Math.max(0.0, viewDir.dot(halfDir));

        var F = Schlick_to_F0(f0, f90, dotVH);

        #if USE_ANISOTROPY
        var dotTL = material.anisotropyT.dot(lightDir);
        var dotTV = material.anisotropyT.dot(viewDir);
        var dotTH = material.anisotropyT.dot(halfDir);
        var dotBL = material.anisotropyB.dot(lightDir);
        var dotBV = material.anisotropyB.dot(viewDir);
        var dotBH = material.anisotropyB.dot(halfDir);

        var V = V_GGX_SmithCorrelated_Anisotropic(material.alphaT, roughness, dotTV, dotBV, dotTL, dotBL, dotNV, dotNL);
        var D = D_GGX_Anisotropic(material.alphaT, roughness, dotNH, dotTH, dotBH);
        #else
        var V = V_GGX_SmithCorrelated(alpha, dotNL, dotNV);
        var D = D_GGX(alpha, dotNH);
        #end

        return F * (V * D);
    }

    static function LTC_Uv(normal:Vector3, viewDir:Vector3, roughness:Float):Vector2 {
        var dotNV = Math.max(0.0, normal.dot(viewDir));
        var LUT_SIZE:Float = 64.0;
        var LUT_SCALE:Float = (LUT_SIZE - 1.0) / LUT_SIZE;
        var LUT_BIAS:Float = 0.5 / LUT_SIZE;

        var uv:Vector2 = new Vector2(roughness, Math.sqrt(1.0 - dotNV));
        uv = uv * LUT_SCALE + LUT_BIAS;
        return uv;
    }

    static function LTC_ClippedSphereFormFactor(f:Vector3):Float {
        var len = f.length();
        var z = f.z / len;
        return Math.max((len * len + f.z) / (len + 1.0), 0.0);
    }

    static function LTC_Evaluate(normal:Vector3, viewDir:Vector3, position:Vector3, mInv:Mat3, rectCoords:Array<Vector3>):Vector3 {
        // todo: implement LTC_Evaluate
        return new Vector3(0.0);
    }

    #if USE_SHEEN
    static function BRDF_Sheen(lightDir:Vector3, viewDir:Vector3, normal:Vector3, sheenColor:Vector3, sheenRoughness:Float):Vector3 {
        var halfDir = (lightDir + viewDir).normalize();
        var dotNL = Math.max(0.0, normal.dot(lightDir));
        var dotNV = Math.max(0.0, normal.dot(viewDir));
        var dotNH = Math.max(0.0, normal.dot(halfDir));

        var D = D_Charlie(sheenRoughness, dotNH);
        var V = V_Neubelt(dotNV, dotNL);

        return sheenColor * (D * V);
    }
    #end

    #if USE_IRIDESCENCE
    static function computeMultiscatteringIridescence(normal:Vector3, viewDir:Vector3, specularColor:Vector3, specularF90:Float, iridescence:Float, iridescenceFresnel:Vector3, roughness:Float, singleScattering:Vector3, multiScattering:Vector3) {
        // todo: implement computeMultiscatteringIridescence
    }
    #else
    static function computeMultiscattering(normal:Vector3, viewDir:Vector3, specularColor:Vector3, specularF90:Float, roughness:Float, singleScattering:Vector3, multiScattering:Vector3) {
        // todo: implement computeMultiscattering
    }
    #end
}