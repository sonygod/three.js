package three.renderers.shaders.ShaderChunk;

@:glsl VERSION 300 ES

@:ifdef USE_IRIDESCENCE

// XYZ to linear-sRGB color space
const XYZ_TO_REC709:Mat3 = new Mat3(
    3.2404542, -0.9692660,  0.0556434,
    -1.5371385,  1.8760108, -0.2040259,
    -0.4985314,  0.0415560,  1.0572252
);

// Assume air interface for top
// Note: We don't handle the case fresnel0 == 1
function Fresnel0ToIor(fresnel0:Vec3):Vec3 {
    var sqrtF0:Vec3 = sqrt(fresnel0);
    return (vec3(1.0) + sqrtF0) / (vec3(1.0) - sqrtF0);
}

// Conversion FO/IOR
function IorToFresnel0(transmittedIor:Vec3, incidentIor:Float):Vec3 {
    return pow2((transmittedIor - incidentIor) / (transmittedIor + incidentIor));
}

// ior is a value between 1.0 and 3.0. 1.0 is air interface
function IorToFresnel0_single(transmittedIor:Float, incidentIor:Float):Float {
    return pow2((transmittedIor - incidentIor) / (transmittedIor + incidentIor));
}

// Fresnel equations for dielectric/dielectric interfaces.
// Ref: https://belcour.github.io/blog/research/2017/05/01/brdf-thin-film.html
// Evaluation XYZ sensitivity curves in Fourier space
function evalSensitivity(OPD:Float, shift:Vec3):Vec3 {
    var phase:Float = 2.0 * Math.PI * OPD * 1.0e-9;
    var val:Vec3 = new Vec3(5.4856e-13, 4.4201e-13, 5.2481e-13);
    var pos:Vec3 = new Vec3(1.6810e+06, 1.7953e+06, 2.2084e+06);
    var var_:Vec3 = new Vec3(4.3278e+09, 9.3046e+09, 6.6121e+09);

    var xyz:Vec3 = val * Math.sqrt(2.0 * Math.PI * var_) * Math.cos(pos * phase + shift) * Math.exp(-pow2(phase) * var_);
    xyz.x += 9.7470e-14 * Math.sqrt(2.0 * Math.PI * 4.5282e+09) * Math.cos(2.2399e+06 * phase + shift.x) * Math.exp(- 4.5282e+09 * pow2(phase));
    xyz /= 1.0685e-7;

    var rgb:Vec3 = XYZ_TO_REC709.multMatVec(xyz);
    return rgb;
}

function evalIridescence(outsideIOR:Float, eta2:Float, cosTheta1:Float, thinFilmThickness:Float, baseF0:Vec3):Vec3 {
    var I:Vec3;

    // Force iridescenceIOR -> outsideIOR when thinFilmThickness -> 0.0
    var iridescenceIOR:Float = mix(outsideIOR, eta2, smoothstep(0.0, 0.03, thinFilmThickness));
    // Evaluate the cosTheta on the base layer (Snell law)
    var sinTheta2Sq:Float = pow2(outsideIOR / iridescenceIOR) * (1.0 - pow2(cosTheta1));

    // Handle TIR:
    var cosTheta2Sq:Float = 1.0 - sinTheta2Sq;
    if (cosTheta2Sq < 0.0) {
        return vec3(1.0);
    }

    var cosTheta2:Float = Math.sqrt(cosTheta2Sq);

    // First interface
    var R0:Float = IorToFresnel0_single(iridescenceIOR, outsideIOR);
    var R12:Float = F_Schlick(R0, 1.0, cosTheta1);
    var T121:Float = 1.0 - R12;
    var phi12:Float = 0.0;
    if (iridescenceIOR < outsideIOR) phi12 = Math.PI;
    var phi21:Float = Math.PI - phi12;

    // Second interface
    var baseIOR:Vec3 = Fresnel0ToIor(clamp(baseF0, 0.0, 0.9999)); // guard against 1.0
    var R1:Vec3 = IorToFresnel0(baseIOR, iridescenceIOR);
    var R23:Vec3 = F_Schlick(R1, 1.0, cosTheta2);
    var phi23:Vec3 = new Vec3(0.0);
    if (baseIOR.x < iridescenceIOR) phi23.x = Math.PI;
    if (baseIOR.y < iridescenceIOR) phi23.y = Math.PI;
    if (baseIOR.z < iridescenceIOR) phi23.z = Math.PI;

    // Phase shift
    var OPD:Float = 2.0 * iridescenceIOR * thinFilmThickness * cosTheta2;
    var phi:Vec3 = new Vec3(phi21) + phi23;

    // Compound terms
    var R123:Vec3 = clamp(R12 * R23, 1e-5, 0.9999);
    var r123:Vec3 = sqrt(R123);
    var Rs:Vec3 = pow2(T121) * R23 / (vec3(1.0) - R123);

    // Reflectance term for m = 0 (DC term amplitude)
    var C0:Vec3 = R12 + Rs;
    I = C0;

    // Reflectance term for m > 0 (pairs of diracs)
    var Cm:Vec3 = Rs - T121;
    for (i in 1...3) {
        Cm *= r123;
        var Sm:Vec3 = 2.0 * evalSensitivity(float(i) * OPD, float(i) * phi);
        I += Cm * Sm;
    }

    // Since out of gamut colors might be produced, negative color values are clamped to 0.
    return max(I, vec3(0.0));
}

@end