class ClippingPlaneFragmentShader {

  public static function main():String {
    return """
      #if NUM_CLIPPING_PLANES > 0

        vec4 plane;

        #ifdef ALPHA_TO_COVERAGE

          float distanceToPlane, distanceGradient;
          float clipOpacity = 1.0;

          #pragma unroll_loop_start
          for ( int i = 0; i < UNION_CLIPPING_PLANES; i ++ ) {

            plane = clippingPlanes[ i ];
            distanceToPlane = - dot( vClipPosition, plane.xyz ) + plane.w;
            distanceGradient = fwidth( distanceToPlane ) / 2.0;
            clipOpacity *= smoothstep( - distanceGradient, distanceGradient, distanceToPlane );

            if ( clipOpacity == 0.0 ) discard;

          }
          #pragma unroll_loop_end

          #if UNION_CLIPPING_PLANES < NUM_CLIPPING_PLANES

            float unionClipOpacity = 1.0;

            #pragma unroll_loop_start
            for ( int i = UNION_CLIPPING_PLANES; i < NUM_CLIPPING_PLANES; i ++ ) {

              plane = clippingPlanes[ i ];
              distanceToPlane = - dot( vClipPosition, plane.xyz ) + plane.w;
              distanceGradient = fwidth( distanceToPlane ) / 2.0;
              unionClipOpacity *= 1.0 - smoothstep( - distanceGradient, distanceGradient, distanceToPlane );

            }
            #pragma unroll_loop_end

            clipOpacity *= 1.0 - unionClipOpacity;

          #endif

          diffuseColor.a *= clipOpacity;

          if ( diffuseColor.a == 0.0 ) discard;

        #else

          #pragma unroll_loop_start
          for ( int i = 0; i < UNION_CLIPPING_PLANES; i ++ ) {

            plane = clippingPlanes[ i ];
            if ( dot( vClipPosition, plane.xyz ) > plane.w ) discard;

          }
          #pragma unroll_loop_end

          #if UNION_CLIPPING_PLANES < NUM_CLIPPING_PLANES

            bool clipped = true;

            #pragma unroll_loop_start
            for ( int i = UNION_CLIPPING_PLANES; i < NUM_CLIPPING_PLANES; i ++ ) {

              plane = clippingPlanes[ i ];
              clipped = ( dot( vClipPosition, plane.xyz ) > plane.w ) && clipped;

            }
            #pragma unroll_loop_end

            if ( clipped ) discard;

          #endif

        #endif

      #endif
    """;
  }
}


**Explanation of Changes:**

* **Class Structure:** Haxe doesn't have the concept of default exports like JavaScript. We create a class `ClippingPlaneFragmentShader` to encapsulate the GLSL code.
* **`main` Function:** The GLSL code is now within a `main` function. This function returns the GLSL string as a `String`.
* **String Interpolation:** Haxe uses triple-quoted strings (`"""..."""`) for multi-line string literals.
* **`#if` and `#ifdef`:** These directives are the same in both languages.

**Usage:**

You can now access the GLSL code as follows:


var glslCode = ClippingPlaneFragmentShader.main();