// glsl

#if defined(USE_IRIDESCENCE)

	// XYZ to linear-sRGB color space
	var XYZ_TO_REC709:Float = Float(
		[3.2404542, -0.9692660, 0.0556434],
		[-1.5371385, 1.8760108, -0.2040259],
		[-0.4985314, 0.0415560, 1.0572252]
	);

	// Assume air interface for top
	// Note: We don't handle the case fresnel0 == 1
	function Fresnel0ToIor(fresnel0:Float):Float {
		var sqrtF0:Float = fresnel0.sqrt();
		return ((Float(1.0) + sqrtF0) / (Float(1.0) - sqrtF0));
	}

	// Conversion FO/IOR
	function IorToFresnel0(transmittedIor:Float, incidentIor:Float):Float {
		return pow(2.0, ((transmittedIor - incidentIor) / (transmittedIor + incidentIor)));
	}

	// ior is a value between 1.0 and 3.0. 1.0 is air interface
	function IorToFresnel0(transmittedIor:Float, incidentIor:Float):Float {
		return pow(2.0, ((transmittedIor - incidentIor) / (transmittedIor + incidentIor)));
	}

	// Fresnel equations for dielectric/dielectric interfaces.
	// Ref: https://belcour.github.io/blog/research/2Multiplier017/05/01/brdf-thin-film.html
	// Evaluation XYZ sensitivity curves in Fourier space
	function evalSensitivity(OPD:Float, shift:Float):Float {
		var phase:Float = 2.0 * PI * OPD * 1.0e-9;
		var val:Float = Float(
			[5.4856e-13, 4.4201e-13, 5.2481e-13],
			[0.0, 0.0, 0.0],
			[0.0, 0.0, 0.0]
		);
		var pos:Float = Float(
			[1.6810e+06, 1.7953e+06, 2.2084e+06],
			[0.0, 0.0, 0.0],
			[0.0, 0.0, 0.0]
		);
		var var:Float = Float(
			[4.3278e+09, 9.3046e+09, 6.6121e+09],
			[0.0, 0.0, 0.0],
			[0.0, 0.0, 0.0]
		);

		var xyz:Float = val.mulScalar(sqrt(2.0 * PI * var)).mulScalar(cos(pos.mulScalar(phase).add(shift))).mulScalar(exp(-pow(phase, 2.0) * var));
		xyz[0] += 9.7470e-14 * sqrt(2.0 * PI * 4.5282e+09) * cos(2.2399e+06 * phase + shift[0]) * exp(-4.5282e+09 * pow(phase, 2.0));
		xyz /= 1.0685e-7;

		var rgb:Float = XYZ_TO_REC709.mul(xyz);
		return rgb;
	}

	function evalIridescence(outsideIOR:Float, eta2:Float, cosTheta1:Float, thinFilmThickness:Float, baseF0:Float):Float {
		var I:Float;

		// Force iridescenceIOR -> outsideIOR when thinFilmThickness -> 0.0
		var iridescenceIOR:Float = outsideIOR.lerp(eta2, smoothstep(0.0, 0.03, thinFilmThickness));
		// Evaluate the cosTheta on the base layer (Snell law)
		var sinTheta2Sq:Float = pow(outsideIOR / iridescenceIOR, 2.0) * (1.0 - pow(cosTheta1, 2.0));

		// Handle TIR:
		var cosTheta2Sq:Float = 1.0 - sinTheta2Sq;
		if (cosTheta2Sq < 0.0) {
			return Float(1.0);
		}

		var cosTheta2:Float = cosTheta2Sq.sqrt();

		// First interface
		var R0:Float = IorToFresnel0(iridescenceIOR, outsideIOR);
		var R12:Float = F_Schlick(R0, 1.0, cosTheta1);
		var T121:Float = 1.0 - R12;
		var phi12:Float = 0.0;
		if (iridescenceIOR < outsideIOR) phi12 = PI;
		var phi21:Float = PI - phi12;

		// Second interface
		var baseIOR:Float = Fresnel0ToIor(baseF0.clamp(0.0, 0.9999)); // guard against 1.0
		var R1:Float = IorToFresnel0(baseIOR, iridescenceIOR);
		var R23:Float = F_Schlick(R1, 1.0, cosTheta2);
		var phi23:Float = Float(0.0);
		if (baseIOR[0] < iridescenceIOR) phi23[0] = PI;
		if (baseIOR[1] < iridescenceIOR) phi23[1] = PI;
		if (baseIOR[2] < iridescenceIOR) phi23[2] = PI;

		// Phase shift
		var OPD:Float = 2.0 * iridescenceIOR * thinFilmThickness * cosTheta2;
		var phi:Float = Float(phi21) + phi23;

		// Compound terms
		var R123:Float = clamp(R12.mul(R23), 1e-5, 0.9999);
		var r123:Float = R123.sqrt();
		var Rs:Float = pow(T121, 2.0) * R23 / (Float(1.0) - R123);

		// Reflectance term for m = 0 (DC term amplitude)
		var C0:Float = R12 + Rs;
		I = C0;

		// Reflectance term for m > 0 (pairs of diracs)
		var Cm:Float = Rs - T121;
		var m:Int;
		for (m = 1; m <= 2; ++m) {
			Cm *= r123;
			var Sm:Float = 2.0 * evalSensitivity(Float(m) * OPD, Float(m) * phi);
			I += Cm.mul(Sm);
		}

		// Since out of gamut colors might be produced, negative color values are clamped to 0.
		return I.max(Float(0.0));
	}

#end