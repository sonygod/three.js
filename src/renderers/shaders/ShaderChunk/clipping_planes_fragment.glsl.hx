package three.shader;

import openfl.display.ShaderInput;
import openfl.display.ShaderParameter;

class ClippingPlanesFragmentShader {
    @:glsl("
#if NUM_CLIPPING_PLANES > 0

	vec4 plane;

	#ifdef ALPHA_TO_COVERAGE

		float distanceToPlane, distanceGradient;
		float clipOpacity = 1.0;

		for (i in 0...UNION_CLIPPING_PLANES) {
			plane = clippingPlanes[i];
			distanceToPlane = - dot(vClipPosition, plane.xyz) + plane.w;
			distanceGradient = fwidth(distanceToPlane) / 2.0;
			clipOpacity *= smoothstep(-distanceGradient, distanceGradient, distanceToPlane);

			if (clipOpacity == 0.0) discard;

		}

		#if UNION_CLIPPING_PLANES < NUM_CLIPPING_PLANES

			var unionClipOpacity:Float = 1.0;

			for (i in UNION_CLIPPING_PLANES...NUM_CLIPPING_PLANES) {
				plane = clippingPlanes[i];
				distanceToPlane = - dot(vClipPosition, plane.xyz) + plane.w;
				distanceGradient = fwidth(distanceToPlane) / 2.0;
				unionClipOpacity *= 1.0 - smoothstep(-distanceGradient, distanceGradient, distanceToPlane);
			}

			clipOpacity *= 1.0 - unionClipOpacity;

		#endif

		diffuseColor.a *= clipOpacity;

		if (diffuseColor.a == 0.0) discard;

	#else

		for (i in 0...UNION_CLIPPING_PLANES) {
			plane = clippingPlanes[i];
			if (dot(vClipPosition, plane.xyz) > plane.w) discard;
		}

		#if UNION_CLIPPING_PLANES < NUM_CLIPPING_PLANES

			var clipped:Bool = true;

			for (i in UNION_CLIPPING_PLANES...NUM_CLIPPING_PLANES) {
				plane = clippingPlanes[i];
				clipped = (dot(vClipPosition, plane.xyz) > plane.w) && clipped;
			}

			if (clipped) discard;

		#endif

	#endif

#endif
");
}