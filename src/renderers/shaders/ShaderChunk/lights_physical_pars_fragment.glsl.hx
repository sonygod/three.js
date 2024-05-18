struct PhysicalMaterial {
    public var diffuseColor:Vector3;
    public var roughness:Float;
    public var specularColor:Vector3;
    public var specularF90:Float;
    public var dispersion:Float;

    #ifdef USE_CLEARCOAT
    public var clearcoat:Float;
    public var clearcoatRoughness:Float;
    public var clearcoatF0:Vector3;
    public var clearcoatF90:Float;
    #end

    #ifdef USE_IRIDESCENCE
    public var iridescence:Float;
    public var iridescenceIOR:Float;
    public var iridescenceThickness:Float;
    public var iridescenceFresnel:Vector3;
    public var iridescenceF0:Vector3;
    #end

    #ifdef USE_SHEEN
    public var sheenColor:Vector3;
    public var sheenRoughness:Float;
    #end

    #ifdef IOR
    public var ior:Float;
    #end

    #ifdef USE_TRANSMISSION
    public var transmission:Float;
    public var transmissionAlpha:Float;
    public var thickness:Float;
    public var attenuationDistance:Float;
    public var attenuationColor:Vector3;
    #end

    #ifdef USE_ANISOTROPY
    public var anisotropy:Float;
    public var alphaT:Float;
    public var anisotropyT:Vector3;
    public var anisotropyB:Vector3;
    #end
}

// temporary
var clearcoatSpecularDirect:Vector3 = Vector3.Zero;
var clearcoatSpecularIndirect:Vector3 = Vector3.Zero;
var sheenSpecularDirect:Vector3 = Vector3.Zero;
var sheenSpecularIndirect:Vector3 = Vector3.Zero;

function Schlick_to_F0(f:Vector3, f90:Float, dotVH:Float):Vector3 {
    var x = clamp(1.0 - dotVH, 0.0, 1.0);
    var x2 = x * x;
    var x5 = clamp(x * x2 * x2, 0.0, 0.9999);

    return (f - Vector3.UnitW * f90 * x5) / (1.0 - x5);
}

// Moving Frostbite to Physically Based Rendering 3.0 - page 12, listing 2
// https://seblagarde.files.wordpress.com/2015/07/course_notes_moving_frostbite_to_pbr_v32.pdf
function V_GGX_SmithCorrelated(alpha:Float, dotNL:Float, dotNV:Float):Float {
    var a2 = pow2(alpha);

    var gv = dotNL * sqrt(a2 + (1.0 - a2) * pow2(dotNV));
    var gl = dotNV * sqrt(a2 + (1.0 - a2) * pow2(dotNL));

    return 0.5 / max(gv + gl, EPSILON);
}

// Microfacet Models for Refraction through Rough Surfaces - equation (33)
// http://graphicrants.blogspot.com/2013/08/specular-brdf-reference.html
// alpha is "roughness squared" in Disney’s reparameterization
function D_GGX(alpha:Float, dotNH:Float):Float {
    var a2 = pow2(alpha);

    var denom = pow2(dotNH) * (a2 - 1.0) + 1.0; // avoid alpha = 0 with dotNH = 1

    return RECIPROCAL_PI * a2 / pow2(denom);
}

// https://google.github.io/filament/Filament.md.html#materialsystem/anisotropicmodel/anisotropicspecularbrdf
#ifdef USE_ANISOTROPY

    function V_GGX_SmithCorrelated_Anisotropic(alphaT:Float, alphaB:Float, dotTV:Float, dotBV:Float, dotTL:Float, dotBL:Float, dotNV:Float, dotNL:Float):Float {
        var gv = dotNL * length(Vector3.UnitW * alphaT * dotTV, alphaB * dotBV, dotNV);
        var gl = dotNV * length(Vector3.UnitW * alphaT * dotTL, alphaB * dotBL, dotNL);
        var v = 0.5 / (gv + gl);

        return saturate(v);
    }

    function D_GGX_Anisotropic(alphaT:Float, alphaB:Float, dotNH:Float, dotTH:Float, dotBH:Float):Float {
        var a2 = alphaT * alphaB;
        var v = Vector3.UnitW * alphaB * dotTH, alphaT * dotBH, a2 * dotNH;
        var v2 = dot(v, v);
        var w2 = a2 / v2;

        return RECIPROCAL_PI * a2 * pow2(w2);
    }

#end

#ifdef USE_CLEARCOAT

    function BRDF_GGX_Clearcoat(lightDir:Vector3, viewDir:Vector3, normal:Vector3, material:PhysicalMaterial):Vector3 {
        var f0 = material.clearcoatF0;
        var f90 = material.clearcoatF90;
        var roughness = material.clearcoatRoughness;

        var alpha = pow2(roughness); // UE4's roughness

        var halfDir = normalize(lightDir + viewDir);

        var dotNL = saturate(dot(normal, lightDir));
        var dotNV = saturate(dot(normal, viewDir));
        var dotNH = saturate(dot(normal, halfDir));
        var dotVH = saturate(dot(viewDir, halfDir));

        var F = F_Schlick(f0, f90, dotVH);

        var V = V_GGX_SmithCorrelated(alpha, dotNL, dotNV);

        var D = D_GGX(alpha, dotNH);

        return F * (V * D);
    }

#end

function BRDF_GGX(lightDir:Vector3, viewDir:Vector3, normal:Vector3, material:PhysicalMaterial):Vector3 {
    var f0 = material.specularColor;
    var f90 = material.specularF90;
    var roughness = material.roughness;

    var alpha = pow2(roughness); // UE4's roughness

    var halfDir = normalize(lightDir + viewDir);

    var dotNL = saturate(dot(normal, lightDir));
    var dotNV = saturate(dot(normal, viewDir));
    var dotNH = saturate(dot(normal, halfDir));
    var dotVH = saturate(dot(viewDir, halfDir));

    var F = F_Schlick(f0, f90, dotVH);

    #ifdef USE_IRIDESCENCE

        F = mix(F, material.iridescenceFresnel, material.iridescence);

    #end

    #ifdef USE_ANISOTROPY

        var dotTL = dot(material.anisotropyT, lightDir);
        var dotTV = dot(material.anisotropyT, viewDir);
        var dotTH = dot(material.anisotropyT, halfDir);
        var dotBL = dot(material.anisotropyB, lightDir);
        var dotBV = dot(material.anisotropyB, viewDir);
        var dotBH = dot(material.anisotropyB, halfDir);

        var V = V_GGX_SmithCorrelated_Anisotropic(material.alphaT, alpha, dotTV, dotBV, dotTL, dotBL, dotNV, dotNL);

        var D = D_GGX_Anisotropic(material.alphaT, alpha, dotNH, dotTH, dotBH);

    #else

        var V = V_GGX_SmithCorrelated(alpha, dotNL, dotNV);

        var D = D_GGX(alpha, dotNH);

    #end

    return F * (V * D);
}

// Rect Area Light

// Real-Time Polygonal-Light Shading with Linearly Transformed Cosines
// by Eric Heitz, Jonathan Dupuy, Stephen Hill and David Neubelt
// code: https://github.com/selfshadow/ltc_code/

function LTC_Uv(N:Vector3, V:Vector3, roughness:Float):Vector2 {

    const LUT_SIZE = 64.0;
    const LUT_SCALE = (LUT_SIZE - 1.0) / LUT_SIZE;
    const LUT_BIAS = 0.5 / LUT_SIZE;

    var dotNV = saturate(dot(N, V));

    // texture parameterized by sqrt( GGX alpha ) and sqrt( 1 - cos( theta ) )
    var uv = Vector2.Zero;
    uv.x = roughness;
    uv.y = sqrt(1.0 - dotNV);

    uv = uv * LUT_SCALE + LUT_BIAS;

    return uv;

}

function LTC_ClippedSphereFormFactor(f:Vector3):Float {

    // Real-Time Area Lighting: a Journey from Research to Production (p.102)
    // An approximation of the form factor of a horizon-clipped rectangle.

    var l = length(f);

    return max((l * l + f.z) / (l + 1.0), 0.0);

}

function LTC_EdgeVectorFormFactor(v1:Vector3, v2:Vector3):Vector3 {

    var x = dot(v1, v2);

    var y = abs(x);

    // rational polynomial approximation to theta / sin( theta ) / 2PI
    var a = 0.8543985 + (0.4965155 + 0.0145206 * y) * y;
    var b = 3.4175940 + (4.1616724 + y) * y;
    var v = a / b;

    var theta_sintheta = (x > 0.0) ? v : 0.5 *