#if USE_BUMPMAP

import js.html.WebGLRenderingContext;

class BumpmapParsFragment {
    public var bumpMap: WebGLRenderingContext.Texture;
    public var bumpScale: Float;

    // Bump Mapping Unparametrized Surfaces on the GPU by Morten S. Mikkelsen
    // https://mmikk.github.io/papers3d/mm_sfgrad_bump.pdf

    // Evaluate the derivative of the height w.r.t. screen-space using forward differencing (listing 2)
    public function dHdxy_fwd(dSTdx: js.html.ArrayLike<Float>, dSTdy: js.html.ArrayLike<Float>, vBumpMapUv: js.html.ArrayLike<Float>): js.html.ArrayLike<Float> {
        var Hll = bumpScale * WebGLRenderingContext.instance.texImage2D(bumpMap, 0, vBumpMapUv[0], vBumpMapUv[1], 0).data[0] / 255;
        var dBx = bumpScale * WebGLRenderingContext.instance.texImage2D(bumpMap, 0, vBumpMapUv[0] + dSTdx[0], vBumpMapUv[1] + dSTdx[1], 0).data[0] / 255 - Hll;
        var dBy = bumpScale * WebGLRenderingContext.instance.texImage2D(bumpMap, 0, vBumpMapUv[0] + dSTdy[0], vBumpMapUv[1] + dSTdy[1], 0).data[0] / 255 - Hll;

        return js.html.ArrayBuffer.slice([dBx, dBy]);
    }

    public function perturbNormalArb(surf_pos: js.html.ArrayLike<Float>, surf_norm: js.html.ArrayLike<Float>, dHdxy: js.html.ArrayLike<Float>, faceDirection: Float): js.html.ArrayLike<Float> {
        // normalize is done to ensure that the bump map looks the same regardless of the texture's scale
        var vSigmaX = normalize(dFdx(surf_pos));
        var vSigmaY = normalize(dFdy(surf_pos));
        var vN = surf_norm; // normalized

        var R1 = cross(vSigmaY, vN);
        var R2 = cross(vN, vSigmaX);

        var fDet = dot(vSigmaX, R1) * faceDirection;

        var vGrad = sign(fDet) * (dHdxy[0] * R1 + dHdxy[1] * R2);
        return normalize(abs(fDet) * surf_norm - vGrad);
    }

    private function normalize(v: js.html.ArrayLike<Float>): js.html.ArrayLike<Float> {
        var length = Math.sqrt(v[0] * v[0] + v[1] * v[1] + v[2] * v[2]);
        return js.html.ArrayBuffer.slice([v[0] / length, v[1] / length, v[2] / length]);
    }

    private function dot(v1: js.html.ArrayLike<Float>, v2: js.html.ArrayLike<Float>): Float {
        return v1[0] * v2[0] + v1[1] * v2[1] + v1[2] * v2[2];
    }

    private function cross(v1: js.html.ArrayLike<Float>, v2: js.html.ArrayLike<Float>): js.html.ArrayLike<Float> {
        return js.html.ArrayBuffer.slice([v1[1] * v2[2] - v1[2] * v2[1], v1[2] * v2[0] - v1[0] * v2[2], v1[0] * v2[1] - v1[1] * v2[0]]);
    }

    private function sign(f: Float): Float {
        return f < 0.0 ? -1.0 : 1.0;
    }

    private function abs(f: Float): Float {
        return f < 0.0 ? -f : f;
    }
}

#end