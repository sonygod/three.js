package three.js.src.renderers.shaders.ShaderChunk;

typedef PhysicalMaterial = {
    diffuseColor:Float3,
    roughness:Float,
    specularColor:Float3,
    specularF90:Float,
    dispersion:Float,
    clearcoat:Float,
    clearcoatRoughness:Float,
    clearcoatF0:Float3,
    clearcoatF90:Float,
    iridescence:Float,
    iridescenceIOR:Float,
    iridescenceThickness:Float,
    iridescenceFresnel:Float3,
    iridescenceF0:Float3,
    sheenColor:Float3,
    sheenRoughness:Float,
    ior:Float,
    transmission:Float,
    transmissionAlpha:Float,
    thickness:Float,
    attenuationDistance:Float,
    attenuationColor:Float3,
    anisotropy:Float,
    alphaT:Float,
    anisotropyT:Float3,
    anisotropyB:Float3
}

class ShaderChunk {
    static var clearcoatSpecularDirect:Float3 = vec3(0.0);
    static var clearcoatSpecularIndirect:Float3 = vec3(0.0);
    static var sheenSpecularDirect:Float3 = vec3(0.0);
    static var sheenSpecularIndirect:Float3 = vec3(0.0);

    static function Schlick_to_F0(f:Float3, f90:Float, dotVH:Float):Float3 {
        var x = Math.max(1.0 - dotVH, 0.0, 1.0);
        var x2 = x * x;
        var x5 = Math.max(x * x2 * x2, 0.0, 0.9999);

        return (f - vec3(f90) * x5) / (1.0 - x5);
    }

    static function V_GGX_SmithCorrelated(alpha:Float, dotNL:Float, dotNV:Float):Float {
        var a2 = Math.pow(alpha, 2);

        var gv = dotNL * Math.sqrt(a2 + (1.0 - a2) * Math.pow(dotNV, 2));
        var gl = dotNV * Math.sqrt(a2 + (1.0 - a2) * Math.pow(dotNL, 2));

        return 0.5 / Math.max(gv + gl, EPSILON);
    }

    static function D_GGX(alpha:Float, dotNH:Float):Float {
        var a2 = Math.pow(alpha, 2);

        var denom = Math.pow(dotNH, 2) * (a2 - 1.0) + 1.0; // avoid alpha = 0 with dotNH = 1

        return RECIPROCAL_PI * a2 / Math.pow(denom, 2);
    }

    static function V_GGX_SmithCorrelated_Anisotropic(alphaT:Float, alphaB:Float, dotTV:Float, dotBV:Float, dotTL:Float, dotBL:Float, dotNV:Float, dotNL:Float):Float {
        var gv = dotNL * length(vec3(alphaT * dotTV, alphaB * dotBV, dotNV));
        var gl = dotNV * length(vec3(alphaT * dotTL, alphaB * dotBL, dotNL));
        var v = 0.5 / (gv + gl);

        return Math.max(v, 0.0);
    }

    static function D_GGX_Anisotropic(alphaT:Float, alphaB:Float, dotNH:Float, dotTH:Float, dotBH:Float):Float {
        var a2 = alphaT * alphaB;
        var v = vec3(alphaB * dotTH, alphaT * dotBH, a2 * dotNH);
        var v2 = dot(v, v);
        var w2 = a2 / v2;

        return RECIPROCAL_PI * a2 * Math.pow(w2, 2);
    }

    static function BRDF_GGX_Clearcoat(lightDir:Float3, viewDir:Float3, normal:Float3, material:PhysicalMaterial):Float3 {
        var f0 = material.clearcoatF0;
        var f90 = material.clearcoatF90;
        var roughness = material.clearcoatRoughness;

        var alpha = Math.pow(roughness, 2); // UE4's roughness

        var halfDir = normalize(lightDir + viewDir);

        var dotNL = Math.max(dot(normal, lightDir), 0.0);
        var dotNV = Math.max(dot(normal, viewDir), 0.0);
        var dotNH = Math.max(dot(normal, halfDir), 0.0);
        var dotVH = Math.max(dot(viewDir, halfDir), 0.0);

        var F = F_Schlick(f0, f90, dotVH);

        var V = V_GGX_SmithCorrelated(alpha, dotNL, dotNV);

        var D = D_GGX(alpha, dotNH);

        return F * (V * D);
    }

    static function BRDF_GGX(lightDir:Float3, viewDir:Float3, normal:Float3, material:PhysicalMaterial):Float3 {
        var f0 = material.specularColor;
        var f90 = material.specularF90;
        var roughness = material.roughness;

        var alpha = Math.pow(roughness, 2); // UE4's roughness

        var halfDir = normalize(lightDir + viewDir);

        var dotNL = Math.max(dot(normal, lightDir), 0.0);
        var dotNV = Math.max(dot(normal, viewDir), 0.0);
        var dotNH = Math.max(dot(normal, halfDir), 0.0);
        var dotVH = Math.max(dot(viewDir, halfDir), 0.0);

        var F = F_Schlick(f0, f90, dotVH);

        if (material.iridescence > 0.0) {
            F = mix(F, material.iridescenceFresnel, material.iridescence);
        }

        if (material.anisotropy > 0.0) {
            var dotTL = dot(material.anisotropyT, lightDir);
            var dotTV = dot(material.anisotropyT, viewDir);
            var dotTH = dot(material.anisotropyT, halfDir);
            var dotBL = dot(material.anisotropyB, lightDir);
            var dotBV = dot(material.anisotropyB, viewDir);
            var dotBH = dot(material.anisotropyB, halfDir);

            var V = V_GGX_SmithCorrelated_Anisotropic(material.alphaT, alpha, dotTV, dotBV, dotTL, dotBL, dotNV, dotNL);

            var D = D_GGX_Anisotropic(material.alphaT, alpha, dotNH, dotTH, dotBH);
        } else {
            var V = V_GGX_SmithCorrelated(alpha, dotNL, dotNV);

            var D = D_GGX(alpha, dotNH);
        }

        return F * (V * D);
    }

    static function LTC_Uv(normal:Float3, viewDir:Float3, roughness:Float):Float2 {
        var LUT_SIZE = 64.0;
        var LUT_SCALE = (LUT_SIZE - 1.0) / LUT_SIZE;
        var LUT_BIAS = 0.5 / LUT_SIZE;

        var dotNV = Math.max(dot(normal, viewDir), 0.0);

        var uv = vec2(roughness, Math.sqrt(1.0 - dotNV));

        uv = uv * LUT_SCALE + LUT_BIAS;

        return uv;
    }

    static function LTC_ClippedSphereFormFactor(f:Float3):Float {
        var l = length(f);

        return Math.max((l * l + f.z) / (l + 1.0), 0.0);
    }

    static function LTC_EdgeVectorFormFactor(v1:Float3, v2:Float3):Float3 {
        var x = dot(v1, v2);

        var y = Math.abs(x);

        var a = 0.8543985 + (0.4965155 + 0.0145206 * y) * y;
        var b = 3.4175940 + (4.1616724 + y) * y;
        var v = a / b;

        var theta_sintheta = (x > 0.0) ? v : 0.5 * Math.inversesqrt(Math.max(1.0 - x * x, 1e-7)) - v;

        return cross(v1, v2) * theta_sintheta;
    }

    static function LTC_Evaluate(normal:Float3, viewDir:Float3, P:Float3, mInv:Float3x3, rectCoords:Array<Float3>):Float3 {
        var lightDir = rectCoords[0] - P;

        var dotNL = Math.max(dot(normal, lightDir), 0.0);
        var dotNV = Math.max(dot(normal, viewDir), 0.0);

        var f0 = F_Schlick(vec3(0.04), 1.0, dotNV);

        var F = F_Schlick(f0, 1.0, dotNV);

        var V = V_GGX_SmithCorrelated(0.25, dotNL, dotNV);

        var D = D_GGX(0.25, dotNV);

        return F * (V * D);
    }

    static function D_Charlie(roughness:Float, dotNH:Float):Float {
        var alpha = Math.pow(roughness, 2);

        var a2 = alpha * alpha;

        var denom = Math.pow(dotNH, 2) * (a2 - 1.0) + 1.0;

        return RECIPROCAL_PI * a2 / Math.pow(denom, 2);
    }

    static function V_Neubelt(dotNV:Float, dotNL:Float):Float {
        var k = Math.sqrt(1.0 - dotNV * dotNV);

        return dotNL / (dotNL * (1.0 - k) + k);
    }

    static function BRDF_Sheen(lightDir:Float3, viewDir:Float3, normal:Float3, sheenColor:Float3, sheenRoughness:Float):Float3 {
        var halfDir = normalize(lightDir + viewDir);

        var dotNL = Math.max(dot(normal, lightDir), 0.0);
        var dotNV = Math.max(dot(normal, viewDir), 0.0);
        var dotNH = Math.max(dot(normal, halfDir), 0.0);

        var F = F_Schlick(vec3(0.04), 1.0, dotNH);

        var V = V_Neubelt(dotNV, dotNL);

        var D = D_Charlie(sheenRoughness, dotNH);

        return F * (V * D);
    }

    static function IBLSheenBRDF(normal:Float3, viewDir:Float3, roughness:Float):Float {
        var dotNV = Math.max(dot(normal, viewDir), 0.0);

        var r2 = roughness * roughness;

        var a = (roughness < 0.25) ? -339.2 * r2 + 161.4 * roughness - 25.9 : -8.48 * r2 + 14.3 * roughness - 9.95;

        var b = (roughness < 0.25) ? 44.0 * r2 - 23.7 * roughness + 3.26 : 1.97 * r2 - 3.27 * roughness + 0.72;

        var DG = Math.exp(a * dotNV + b) + ((roughness < 0.25) ? 0.0 : 0.1 * (roughness - 0.25));

        return Math.max(DG * RECIPROCAL_PI, 0.0);
    }

    static function DFGApprox(normal:Float3, viewDir:Float3, roughness:Float):Float2 {
        var dotNV = Math.max(dot(normal, viewDir), 0.0);

        var r2 = roughness * roughness;

        var a = (roughness < 0.25) ? -339.2 * r2 + 161.4 * roughness - 25.9 : -8.48 * r2 + 14.3 * roughness - 9.95;

        var b = (roughness < 0.25) ? 44.0 * r2 - 23.7 * roughness + 3.26 : 1.97 * r2 - 3.27 * roughness + 0.72;

        var DG = Math.exp(a * dotNV + b) + ((roughness < 0.25) ? 0.0 : 0.1 * (roughness - 0.25));

        var Fd = saturate(1.0 / (DG + 1.0));

        var Fss = Math.pow(1.0 - dotNV, 5.0);

        var FssEss = Fss * (1.0 - Fd);

        var Ess = Fss + Fd;

        return vec2(FssEss, Ess);
    }

    static function EnvironmentBRDF(normal:Float3, viewDir:Float3, specularColor:Float3, specularF90:Float, roughness:Float):Float3 {
        var fab = DFGApprox(normal, viewDir, roughness);

        return specularColor * fab.x + specularF90 * fab.y;
    }

    static function computeMultiscattering(normal:Float3, viewDir:Float3, specularColor:Float3, specularF90:Float, roughness:Float, singleScatter:Float3, multiScatter:Float3):Void {
        var fab = DFGApprox(normal, viewDir, roughness);

        var FssEss = specularColor * fab.x;

        var Ess = fab.x + fab.y;
        var Ems = 1.0 - Ess;

        var Favg = specularColor + (1.0 - specularColor) * 0.047619; // 1/21
        var Fms = FssEss * Favg / (1.0 - Ems * Favg);

        singleScatter += FssEss;
        multiScatter += Fms * Ems;
    }

    static function computeSpecularOcclusion(dotNV:Float, ambientOcclusion:Float, roughness:Float):Float {
        return Math.max(Math.pow(dotNV + ambientOcclusion, Math.exp2(-16.0 * roughness - 1.0)) - 1.0 + ambientOcclusion, 0.0);
    }
}