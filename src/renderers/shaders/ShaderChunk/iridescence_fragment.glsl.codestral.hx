#if USE_IRIDESCENCE

import js.Browser.document;
import js.html.WebGLRenderingContext;

class IridescenceFragment {
    static var gl: WebGLRenderingContext = document.createElement("canvas").getContext("webgl", {});

    static var XYZ_TO_REC709: Float32Array = new Float32Array([
        3.2404542, -0.9692660,  0.0556434,
        -1.5371385,  1.8760108, -0.2040259,
        -0.4985314,  0.0415560,  1.0572252
    ]);

    static function Fresnel0ToIor(fresnel0: Float32Array): Float32Array {
        var sqrtF0: Float32Array = new Float32Array(3);
        for (var i: Int = 0; i < 3; i++) {
            sqrtF0[i] = Math.sqrt(fresnel0[i]);
        }
        var result: Float32Array = new Float32Array(3);
        for (var i: Int = 0; i < 3; i++) {
            result[i] = (1.0 + sqrtF0[i]) / (1.0 - sqrtF0[i]);
        }
        return result;
    }

    static function IorToFresnel0(transmittedIor: Float32Array, incidentIor: Float): Float32Array {
        var result: Float32Array = new Float32Array(3);
        for (var i: Int = 0; i < 3; i++) {
            result[i] = Math.pow((transmittedIor[i] - incidentIor) / (transmittedIor[i] + incidentIor), 2);
        }
        return result;
    }

    static function IorToFresnel0(transmittedIor: Float, incidentIor: Float): Float {
        return Math.pow((transmittedIor - incidentIor) / (transmittedIor + incidentIor), 2);
    }

    static function evalSensitivity(OPD: Float, shift: Float32Array): Float32Array {
        var phase: Float = 2.0 * Math.PI * OPD * 1.0e-9;
        var val: Float32Array = new Float32Array([5.4856e-13, 4.4201e-13, 5.2481e-13]);
        var pos: Float32Array = new Float32Array([1.6810e+06, 1.7953e+06, 2.2084e+06]);
        var var: Float32Array = new Float32Array([4.3278e+09, 9.3046e+09, 6.6121e+09]);

        var xyz: Float32Array = new Float32Array(3);
        for (var i: Int = 0; i < 3; i++) {
            xyz[i] = val[i] * Math.sqrt(2.0 * Math.PI * var[i]) * Math.cos(pos[i] * phase + shift[i]) * Math.exp(-Math.pow(phase, 2) * var[i]);
        }
        xyz[0] += 9.7470e-14 * Math.sqrt(2.0 * Math.PI * 4.5282e+09) * Math.cos(2.2399e+06 * phase + shift[0]) * Math.exp(-4.5282e+09 * Math.pow(phase, 2));
        xyz = xyz.map(function(x) { return x / 1.0685e-7; });

        var rgb: Float32Array = new Float32Array(3);
        for (var i: Int = 0; i < 3; i++) {
            rgb[i] = XYZ_TO_REC709.slice(i * 3, i * 3 + 3).reduce(function(sum, a, j) { return sum + a * xyz[j]; }, 0);
        }
        return rgb;
    }

    static function evalIridescence(outsideIOR: Float, eta2: Float, cosTheta1: Float, thinFilmThickness: Float, baseF0: Float32Array): Float32Array {
        var I: Float32Array = new Float32Array(3);

        var iridescenceIOR: Float = outsideIOR * (1.0 - thinFilmThickness / 0.03) + eta2 * (thinFilmThickness / 0.03);
        var sinTheta2Sq: Float = Math.pow(outsideIOR / iridescenceIOR, 2) * (1.0 - Math.pow(cosTheta1, 2));

        var cosTheta2Sq: Float = 1.0 - sinTheta2Sq;
        if (cosTheta2Sq < 0.0) {
            return new Float32Array([1.0, 1.0, 1.0]);
        }

        var cosTheta2: Float = Math.sqrt(cosTheta2Sq);

        var R0: Float = IorToFresnel0(iridescenceIOR, outsideIOR);
        var R12: Float = F_Schlick(R0, 1.0, cosTheta1);
        var T121: Float = 1.0 - R12;
        var phi12: Float = iridescenceIOR < outsideIOR ? Math.PI : 0.0;
        var phi21: Float = Math.PI - phi12;

        var baseIOR: Float32Array = Fresnel0ToIor(baseF0.map(function(x) { return Math.min(x, 0.9999); }));
        var R1: Float32Array = IorToFresnel0(baseIOR, iridescenceIOR);
        var R23: Float32Array = new Float32Array(3);
        var phi23: Float32Array = new Float32Array(3);
        for (var i: Int = 0; i < 3; i++) {
            R23[i] = F_Schlick(R1[i], 1.0, cosTheta2);
            phi23[i] = baseIOR[i] < iridescenceIOR ? Math.PI : 0.0;
        }

        var OPD: Float = 2.0 * iridescenceIOR * thinFilmThickness * cosTheta2;
        var phi: Float32Array = new Float32Array(3);
        for (var i: Int = 0; i < 3; i++) {
            phi[i] = phi21 + phi23[i];
        }

        var R123: Float32Array = new Float32Array(3);
        var r123: Float32Array = new Float32Array(3);
        var Rs: Float32Array = new Float32Array(3);
        for (var i: Int = 0; i < 3; i++) {
            R123[i] = Math.min(Math.max(R12 * R23[i], 1e-5), 0.9999);
            r123[i] = Math.sqrt(R123[i]);
            Rs[i] = Math.pow(T121, 2) * R23[i] / (1.0 - R123[i]);
        }

        var C0: Float32Array = new Float32Array(3);
        for (var i: Int = 0; i < 3; i++) {
            C0[i] = R12 + Rs[i];
        }
        I = C0;

        var Cm: Float32Array = new Float32Array(3);
        for (var i: Int = 0; i < 3; i++) {
            Cm[i] = Rs[i] - T121;
        }
        for (var m: Int = 1; m <= 2; m++) {
            var Sm: Float32Array = evalSensitivity(m * OPD, new Float32Array(3).map(function(x, i) { return m * phi[i]; }));
            for (var i: Int = 0; i < 3; i++) {
                Cm[i] *= r123[i];
                I[i] += Cm[i] * Sm[i];
            }
        }

        return I.map(function(x) { return Math.max(x, 0.0); });
    }
}

#end