class GlslUtils {
  public static function bumpMap():String {
    return /* glsl */@"#ifdef USE_BUMPMAP

      uniform sampler2D bumpMap;
      uniform float bumpScale;

      // Bump Mapping Unparametrized Surfaces on the GPU by Morten S. Mikkelsen
      // https://mmikk.github.io/papers3d/mm_sfgrad_bump.pdf

      // Evaluate the derivative of the height w.r.t. screen-space using forward differencing (listing 2)

      vec2 dHdxy_fwd() {

        vec2 dSTdx = dFdx( vBumpMapUv );
        vec2 dSTdy = dFdy( vBumpMapUv );

        float Hll = bumpScale * texture2D( bumpMap, vBumpMapUv ).x;
        float dBx = bumpScale * texture2D( bumpMap, vBumpMapUv + dSTdx ).x - Hll;
        float dBy = bumpScale * texture2D( bumpMap, vBumpMapUv + dSTdy ).x - Hll;

        return vec2( dBx, dBy );

      }

      vec3 perturbNormalArb( vec3 surf_pos, vec3 surf_norm, vec2 dHdxy, float faceDirection ) {

        // normalize is done to ensure that the bump map looks the same regardless of the texture's scale
        vec3 vSigmaX = normalize( dFdx( surf_pos.xyz ) );
        vec3 vSigmaY = normalize( dFdy( surf_pos.xyz ) );
        vec3 vN = surf_norm; // normalized

        vec3 R1 = cross( vSigmaY, vN );
        vec3 R2 = cross( vN, vSigmaX );

        float fDet = dot( vSigmaX, R1 ) * faceDirection;

        vec3 vGrad = sign( fDet ) * ( dHdxy.x * R1 + dHdxy.y * R2 );
        return normalize( abs( fDet ) * surf_norm - vGrad );

      }

    #endif";
  }
}


**Explanation:**

1. **Class Creation:**  We encapsulate the GLSL code within a Haxe class named `GlslUtils` for better organization and potential reusability.
2. **Static Function:** We define a static function `bumpMap()` within the class to hold and return the GLSL code snippet.
3. **String Literal:** The GLSL code is stored as a multi-line string literal using the `/* glsl */@` syntax. This instructs the Haxe compiler to treat the content as raw GLSL code.

Now, you can access the GLSL code by calling the static function:


var bumpMapShaderCode:String = GlslUtils.bumpMap();