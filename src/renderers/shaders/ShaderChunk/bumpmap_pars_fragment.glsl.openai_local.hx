@:glsl
extern class BumpMapParsFragment {
	#if USE_BUMPMAP

		uniform sampler2D bumpMap;
		uniform float bumpScale;

		// Bump Mapping Unparametrized Surfaces on the GPU by Morten S. Mikkelsen
		// https://mmikk.github.io/papers3d/mm_sfgrad_bump.pdf

		// Evaluate the derivative of the height w.r.t. screen-space using forward differencing (listing 2)
		
		inline vec2 dHdxy_fwd() {
			var dSTdx:vec2 = dFdx(vBumpMapUv);
			var dSTdy:vec2 = dFdy(vBumpMapUv);

			var Hll:Float = bumpScale * texture2D(bumpMap, vBumpMapUv).x;
			var dBx:Float = bumpScale * texture2D(bumpMap, vBumpMapUv + dSTdx).x - Hll;
			var dBy:Float = bumpScale * texture2D(bumpMap, vBumpMapUv + dSTdy).x - Hll;

			return vec2(dBx, dBy);
		}

		inline vec3 perturbNormalArb(vec3 surf_pos, vec3 surf_norm, vec2 dHdxy, float faceDirection) {
			// normalize is done to ensure that the bump map looks the same regardless of the texture's scale
			var vSigmaX:vec3 = normalize(dFdx(surf_pos.xyz));
			var vSigmaY:vec3 = normalize(dFdy(surf_pos.xyz));
			var vN:vec3 = surf_norm; // normalized

			var R1:vec3 = cross(vSigmaY, vN);
			var R2:vec3 = cross(vN, vSigmaX);

			var fDet:Float = dot(vSigmaX, R1) * faceDirection;

			var vGrad:vec3 = sign(fDet) * (dHdxy.x * R1 + dHdxy.y * R2);
			return normalize(abs(fDet) * surf_norm - vGrad);
		}

	#end
}