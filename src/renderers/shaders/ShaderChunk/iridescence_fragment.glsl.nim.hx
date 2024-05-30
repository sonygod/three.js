package three.js.src.renderers.shaders.ShaderChunk;

#if USE_IRIDESCENCE

// XYZ to linear-sRGB color space
var XYZ_TO_REC709:Float32Array = [
	3.2404542, -0.9692660, 0.0556434,
	-1.5371385, 1.8760108, -0.2040259,
	-0.4985314, 0.0415560, 1.0572252
];

// Assume air interface for top
// Note: We don't handle the case fresnel0 == 1
function Fresnel0ToIor(fresnel0:Float32Array):Float32Array {

	var sqrtF0:Float32Array = Math.sqrt(fresnel0);
	return (1.0 - sqrtF0) / (1.0 + sqrtF0);

}

// Conversion FO/IOR
function IorToFresnel0(transmittedIor:Float32Array, incidentIor:Float):Float32Array {

	return Math.pow((transmittedIor - incidentIor) / (transmittedIor + incidentIor), 2.0);

}

// ior is a value between 1.0 and 3.0. 1.0 is air interface
function IorToFresnel0(transmittedIor:Float, incidentIor:Float):Float {

	return Math.pow((transmittedIor - incidentIor) / (transmittedIor + incidentIor), 2.0);

}

// Fresnel equations for dielectric/dielectric interfaces.
// Ref: https://belcour.github.io/blog/research/2017/05/01/brdf-thin-film.html
// Evaluation XYZ sensitivity curves in Fourier space
function evalSensitivity(OPD:Float, shift:Float32Array):Float32Array {

	var phase:Float = 2.0 * Math.PI * OPD * 1.0e-9;
	var val:Float32Array = [5.4856e-13, 4.4201e-13, 5.2481e-13];
	var pos:Float32Array = [1.6810e+06, 1.7953e+06, 2.2084e+06];
	var var:Float32Array = [4.3278e+09, 9.3046e+09, 6.6121e+09];

	var xyz:Float32Array = val * Math.sqrt(2.0 * Math.PI * var) * Math.cos(pos * phase + shift) * Math.exp(-Math.pow(phase, 2.0) * var);
	xyz[0] += 9.7470e-14 * Math.sqrt(2.0 * Math.PI * 4.5282e+09) * Math.cos(2.2399e+06 * phase + shift[0]) * Math.exp(-4.5282e+09 * Math.pow(phase, 2.0));
	xyz /= 1.0685e-7;

	var rgb:Float32Array = XYZ_TO_REC709 * xyz;
	return rgb;

}

function evalIridescence(outsideIOR:Float, eta2:Float, cosTheta1:Float, thinFilmThickness:Float, baseF0:Float32Array):Float32Array {

	var I:Float32Array;

	// Force iridescenceIOR -> outsideIOR when thinFilmThickness -> 0.0
	var iridescenceIOR:Float = Math.mix(outsideIOR, eta2, Math.smoothstep(0.0, 0.03, thinFilmThickness));
	// Evaluate the cosTheta on the base layer (Snell law)
	var sinTheta2Sq:Float = Math.pow(outsideIOR / iridescenceIOR, 2.0) * (1.0 - Math.pow(cosTheta1, 2.0));

	// Handle TIR:
	var cosTheta2Sq:Float = 1.0 - sinTheta2Sq;
	if (cosTheta2Sq < 0.0) {

		return [1.0, 1.0, 1.0];

	}

	var cosTheta2:Float = Math.sqrt(cosTheta2Sq);

	// First interface
	var R0:Float = IorToFresnel0(iridescenceIOR, outsideIOR);
	var R12:Float = F_Schlick(R0, 1.0, cosTheta1);
	var T121:Float = 1.0 - R12;
	var phi12:Float = 0.0;
	if (iridescenceIOR < outsideIOR) phi12 = Math.PI;
	var phi21:Float = Math.PI - phi12;

	// Second interface
	var baseIOR:Float32Array = Fresnel0ToIor(Math.clamp(baseF0, 0.0, 0.9999)); // guard against 1.0
	var R1:Float32Array = IorToFresnel0(baseIOR, iridescenceIOR);
	var R23:Float32Array = F_Schlick(R1, 1.0, cosTheta2);
	var phi23:Float32Array = [0.0, 0.0, 0.0];
	if (baseIOR[0] < iridescenceIOR) phi23[0] = Math.PI;
	if (baseIOR[1] < iridescenceIOR) phi23[1] = Math.PI;
	if (baseIOR[2] < iridescenceIOR) phi23[2] = Math.PI;

	// Phase shift
	var OPD:Float = 2.0 * iridescenceIOR * thinFilmThickness * cosTheta2;
	var phi:Float32Array = [phi21] + phi23;

	// Compound terms
	var R123:Float32Array = Math.clamp(R12 * R23, 1e-5, 0.9999);
	var r123:Float32Array = Math.sqrt(R123);
	var Rs:Float32Array = Math.pow(T121, 2.0) * R23 / (1.0 - R123);

	// Reflectance term for m = 0 (DC term amplitude)
	var C0:Float32Array = R12 + Rs;
	I = C0;

	// Reflectance term for m > 0 (pairs of diracs)
	var Cm:Float32Array = Rs - T121;
	for (var m:Int = 1; m <= 2; ++m) {

		Cm *= r123;
		var Sm:Float32Array = 2.0 * evalSensitivity(m * OPD, m * phi);
		I += Cm * Sm;

	}

	// Since out of gamut colors might be produced, negative color values are clamped to 0.
	return Math.max(I, [0.0, 0.0, 0.0]);

}

#end