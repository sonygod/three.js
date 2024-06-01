import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.ComplexType;
import haxe.macro.ComplexType.ComplexField;
import haxe.macro.ComplexType.ComplexEnumField;

class Glsl {
  static function convert(ctx: Context, expr: Expr): Expr {
    var code = expr.toString();
    code = code.replace(/\/\* glsl \*\/`/g, '');
    code = code.replace(/export const /g, 'static public var ');

    // Replace vec2/vec3 with Vector2/Vector3
    code = code.replace(/vec2/g, 'Vector2');
    code = code.replace(/vec3/g, 'Vector3');

    // Replace uniform with var
    code = code.replace(/uniform /g, 'var ');

    // Replace #include with the actual code
    code = code.replace(/#include <(.*?)>/g, (match, includeName) => {
      switch (includeName) {
        case 'common':
          return `#if defined( GL_ES )
  precision mediump float;
#endif

#define saturate(a) clamp( a, 0.0, 1.0 )
#define linearToGamma(a) pow( a, 1.0 / 2.2 )
#define gammaToLinear(a) pow( a, 2.2 )
#define min3(a, b, c) min(min(a,b),c)
#define max3(a, b, c) max(max(a,b),c)
#define lerp(a, b, t) mix(a,b,t)
#define abs(a) max(a,-a)
#define ceil(a) ceil(a)
#define floor(a) floor(a)
#define mod(x, y) mod(x, y)
#define exp2(a) exp2(a)
#define sign(a) sign(a)
#define smoothstep(a, b, t) smoothstep(a,b,t)
#define fract(a) fract(a)
#define clamp(a, min, max) clamp(a, min, max)
#define min(a, b) min(a, b)
#define max(a, b) max(a, b)
#define mix(a, b, t) mix(a, b, t)
#define step(edge, x) step(edge, x)
#define length(a) length(a)
#define normalize(a) normalize(a)
#define dot(a, b) dot(a, b)
#define cross(a, b) cross(a, b)
#define distance(a, b) distance(a, b)
#define faceforward(n, i, nref) faceforward(n, i, nref)
#define reflect(i, n) reflect(i, n)
#define refract(i, n, eta) refract(i, n, eta)
#define pow(a, b) pow(a, b)
#define exp(a) exp(a)
#define log(a) log(a)
#define log2(a) log2(a)
#define sqrt(a) sqrt(a)
#define inversesqrt(a) inversesqrt(a)
#define acos(a) acos(a)
#define asin(a) asin(a)
#define atan(a) atan(a)
#define atan2(a, b) atan2(a, b)
#define sin(a) sin(a)
#define cos(a) cos(a)
#define tan(a) tan(a)
#define radians(a) radians(a)
#define degrees(a) degrees(a)
#define inverse(m) inverse(m)
#define transpose(m) transpose(m)
#define determinant(m) determinant(m)
#define mat3(m) mat3(m)
#define mat4(m) mat4(m)
#define vec2(a, b) vec2(a, b)
#define vec3(a, b, c) vec3(a, b, c)
#define vec4(a, b, c, d) vec4(a, b, c, d)
#define ivec2(a, b) ivec2(a, b)
#define ivec3(a, b, c) ivec3(a, b, c)
#define ivec4(a, b, c, d) ivec4(a, b, c, d)
#define bvec2(a, b) bvec2(a, b)
#define bvec3(a, b, c) bvec3(a, b, c)
#define bvec4(a, b, c, d) bvec4(a, b, c, d)
#define uint(a) uint(a)
#define int(a) int(a)
#define bool(a) bool(a)
#define float(a) float(a)
#define texture2D(sampler, uv) texture2D(sampler, uv)
#define textureCube(sampler, uv) textureCube(sampler, uv)
#define texture2DProj(sampler, uv) texture2DProj(sampler, uv)
#define textureCubeLodEXT(sampler, uv, lod) textureCubeLodEXT(sampler, uv, lod)
#define texture2DLodEXT(sampler, uv, lod) texture2DLodEXT(sampler, uv, lod)
#define texture2DGradEXT(sampler, uv, ddx, ddy) texture2DGradEXT(sampler, uv, ddx, ddy)
#define texture2DProjLodEXT(sampler, uv, lod) texture2DProjLodEXT(sampler, uv, lod)
#define texture2DProjGradEXT(sampler, uv, ddx, ddy) texture2DProjGradEXT(sampler, uv, ddx, ddy)
`;
        case 'uv_pars_vertex':
          return `#ifdef USE_UV
	attribute vec2 uv;
#endif`;
        case 'fog_pars_vertex':
          return `#ifdef USE_FOG
	uniform vec3 fogColor;
	varying float fogDepth;
#endif`;
        case 'logdepthbuf_pars_vertex':
          return `#ifdef USE_LOGDEPTHBUF
	uniform float logDepthBufFC;
#endif`;
        case 'clipping_planes_pars_vertex':
          return `#ifdef USE_CLIPPING
	uniform vec4 clippingPlanes[ NUM_CLIPPING_PLANES ];
#endif`;
        case 'uv_vertex':
          return `#ifdef USE_UV
		vUv = uv;
	#endif`;
        case 'logdepthbuf_vertex':
          return `#ifdef USE_LOGDEPTHBUF
		gl_Position.z = log2( max( 0.000001, gl_Position.w + 1.0 ) ) * logDepthBufFC - 1.0;
	#endif`;
        case 'clipping_planes_vertex':
          return `#ifdef USE_CLIPPING
		if ( clippingPlanes[ 0 ].a * mvPosition.x + clippingPlanes[ 0 ].b * mvPosition.y + clippingPlanes[ 0 ].c * mvPosition.z + clippingPlanes[ 0 ].d < 0.0 ) discard;
		#if NUM_CLIPPING_PLANES > 1
			if ( clippingPlanes[ 1 ].a * mvPosition.x + clippingPlanes[ 1 ].b * mvPosition.y + clippingPlanes[ 1 ].c * mvPosition.z + clippingPlanes[ 1 ].d < 0.0 ) discard;
		#endif
		#if NUM_CLIPPING_PLANES > 2
			if ( clippingPlanes[ 2 ].a * mvPosition.x + clippingPlanes[ 2 ].b * mvPosition.y + clippingPlanes[ 2 ].c * mvPosition.z + clippingPlanes[ 2 ].d < 0.0 ) discard;
		#endif
		#if NUM_CLIPPING_PLANES > 3
			if ( clippingPlanes[ 3 ].a * mvPosition.x + clippingPlanes[ 3 ].b * mvPosition.y + clippingPlanes[ 3 ].c * mvPosition.z + clippingPlanes[ 3 ].d < 0.0 ) discard;
		#endif
		#if NUM_CLIPPING_PLANES > 4
			if ( clippingPlanes[ 4 ].a * mvPosition.x + clippingPlanes[ 4 ].b * mvPosition.y + clippingPlanes[ 4 ].c * mvPosition.z + clippingPlanes[ 4 ].d < 0.0 ) discard;
		#endif
		#if NUM_CLIPPING_PLANES > 5
			if ( clippingPlanes[ 5 ].a * mvPosition.x + clippingPlanes[ 5 ].b * mvPosition.y + clippingPlanes[ 5 ].c * mvPosition.z + clippingPlanes[ 5 ].d < 0.0 ) discard;
		#endif
		#if NUM_CLIPPING_PLANES > 6
			if ( clippingPlanes[ 6 ].a * mvPosition.x + clippingPlanes[ 6 ].b * mvPosition.y + clippingPlanes[ 6 ].c * mvPosition.z + clippingPlanes[ 6 ].d < 0.0 ) discard;
		#endif
		#if NUM_CLIPPING_PLANES > 7
			if ( clippingPlanes[ 7 ].a * mvPosition.x + clippingPlanes[ 7 ].b * mvPosition.y + clippingPlanes[ 7 ].c * mvPosition.z + clippingPlanes[ 7 ].d < 0.0 ) discard;
		#endif
	#endif`;
        case 'fog_vertex':
          return `#ifdef USE_FOG
		fogDepth = - mvPosition.z;
	#endif`;
        case 'common':
          return `#if defined( GL_ES )
  precision mediump float;
#endif

#define saturate(a) clamp( a, 0.0, 1.0 )
#define linearToGamma(a) pow( a, 1.0 / 2.2 )
#define gammaToLinear(a) pow( a, 2.2 )
#define min3(a, b, c) min(min(a,b),c)
#define max3(a, b, c) max(max(a,b),c)
#define lerp(a, b, t) mix(a,b,t)
#define abs(a) max(a,-a)
#define ceil(a) ceil(a)
#define floor(a) floor(a)
#define mod(x, y) mod(x, y)
#define exp2(a) exp2(a)
#define sign(a) sign(a)
#define smoothstep(a, b, t) smoothstep(a,b,t)
#define fract(a) fract(a)
#define clamp(a, min, max) clamp(a, min, max)
#define min(a, b) min(a, b)
#define max(a, b) max(a, b)
#define mix(a, b, t) mix(a, b, t)
#define step(edge, x) step(edge, x)
#define length(a) length(a)
#define normalize(a) normalize(a)
#define dot(a, b) dot(a, b)
#define cross(a, b) cross(a, b)
#define distance(a, b) distance(a, b)
#define faceforward(n, i, nref) faceforward(n, i, nref)
#define reflect(i, n) reflect(i, n)
#define refract(i, n, eta) refract(i, n, eta)
#define pow(a, b) pow(a, b)
#define exp(a) exp(a)
#define log(a) log(a)
#define log2(a) log2(a)
#define sqrt(a) sqrt(a)
#define inversesqrt(a) inversesqrt(a)
#define acos(a) acos(a)
#define asin(a) asin(a)
#define atan(a) atan(a)
#define atan2(a, b) atan2(a, b)
#define sin(a) sin(a)
#define cos(a) cos(a)
#define tan(a) tan(a)
#define radians(a) radians(a)
#define degrees(a) degrees(a)
#define inverse(m) inverse(m)
#define transpose(m) transpose(m)
#define determinant(m) determinant(m)
#define mat3(m) mat3(m)
#define mat4(m) mat4(m)
#define vec2(a, b) vec2(a, b)
#define vec3(a, b, c) vec3(a, b, c)
#define vec4(a, b, c, d) vec4(a, b, c, d)
#define ivec2(a, b) ivec2(a, b)
#define ivec3(a, b, c) ivec3(a, b, c)
#define ivec4(a, b, c, d) ivec4(a, b, c, d)
#define bvec2(a, b) bvec2(a, b)
#define bvec3(a, b, c) bvec3(a, b, c)
#define bvec4(a, b, c, d) bvec4(a, b, c, d)
#define uint(a) uint(a)
#define int(a) int(a)
#define bool(a) bool(a)
#define float(a) float(a)
#define texture2D(sampler, uv) texture2D(sampler, uv)
#define textureCube(sampler, uv) textureCube(sampler, uv)
#define texture2DProj(sampler, uv) texture2DProj(sampler, uv)
#define textureCubeLodEXT(sampler, uv, lod) textureCubeLodEXT(sampler, uv, lod)
#define texture2DLodEXT(sampler, uv, lod) texture2DLodEXT(sampler, uv, lod)
#define texture2DGradEXT(sampler, uv, ddx, ddy) texture2DGradEXT(sampler, uv, ddx, ddy)
#define texture2DProjLodEXT(sampler, uv, lod) texture2DProjLodEXT(sampler, uv, lod)
#define texture2DProjGradEXT(sampler, uv, ddx, ddy) texture2DProjGradEXT(sampler, uv, ddx, ddy)
`;
        case 'uv_pars_fragment':
          return `#ifdef USE_UV
	varying vec2 vUv;
#endif`;
        case 'map_pars_fragment':
          return `#ifdef USE_MAP
	uniform sampler2D map;
#endif`;
        case 'alphamap_pars_fragment':
          return `#ifdef USE_ALPHAMAP
	uniform sampler2D alphaMap;
#endif`;
        case 'alphatest_pars_fragment':
          return `#ifdef ALPHATEST
	uniform float alphaTest;
#endif`;
        case 'alphahash_pars_fragment':
          return `#ifdef USE_ALPHAHASH
	uniform vec3 alphaHash;
#endif`;
        case 'fog_pars_fragment':
          return `#ifdef USE_FOG
	uniform vec3 fogColor;
	varying float fogDepth;
#endif`;
        case 'logdepthbuf_pars_fragment':
          return `#ifdef USE_LOGDEPTHBUF
	uniform float logDepthBufFC;
#endif`;
        case 'clipping_planes_pars_fragment':
          return `#ifdef USE_CLIPPING
	uniform vec4 clippingPlanes[ NUM_CLIPPING_PLANES ];
#endif`;
        case 'map_fragment':
          return `#ifdef USE_MAP
		diffuseColor.rgb *= texture2D( map, vUv ).rgb;
	#endif`;
        case 'alphamap_fragment':
          return `#ifdef USE_ALPHAMAP
		diffuseColor.a *= texture2D( alphaMap, vUv ).g;
	#endif`;
        case 'alphatest_fragment':
          return `#ifdef ALPHATEST
		if ( diffuseColor.a < alphaTest ) discard;
	#endif`;
        case 'alphahash_fragment':
          return `#ifdef USE_ALPHAHASH
		if ( fract( dot( vUv, alphaHash ) ) > 0.5 ) discard;
	#endif`;
        case 'logdepthbuf_fragment':
          return `#ifdef USE_LOGDEPTHBUF
		if ( gl_FragDepthEXT > log2( max( 0.000001, gl_FragCoord.w + 1.0 ) ) * logDepthBufFC - 1.0 ) discard;
	#endif`;
        case 'clipping_planes_fragment':
          return `#ifdef USE_CLIPPING
		if ( clippingPlanes[ 0 ].a * gl_FragCoord.x + clippingPlanes[ 0 ].b * gl_FragCoord.y + clippingPlanes[ 0 ].c * gl_FragCoord.z + clippingPlanes[ 0 ].d < 0.0 ) discard;
		#if NUM_CLIPPING_PLANES > 1
			if ( clippingPlanes[ 1 ].a * gl_FragCoord.x + clippingPlanes[ 1 ].b * gl_FragCoord.y + clippingPlanes[ 1 ].c * gl_FragCoord.z + clippingPlanes[ 1 ].d < 0.0 ) discard;
		#endif
		#if NUM_CLIPPING_PLANES > 2
			if ( clippingPlanes[ 2 ].a * gl_FragCoord.x + clippingPlanes[ 2 ].b * gl_FragCoord.y + clippingPlanes[ 2 ].c * gl_FragCoord.z + clippingPlanes[ 2 ].d < 0.0 ) discard;
		#endif
		#if NUM_CLIPPING_PLANES > 3
			if ( clippingPlanes[ 3 ].a * gl_FragCoord.x + clippingPlanes[ 3 ].b * gl_FragCoord.y + clippingPlanes[ 3 ].c * gl_FragCoord.z + clippingPlanes[ 3 ].d < 0.0 ) discard;
		#endif
		#if NUM_CLIPPING_PLANES > 4
			if ( clippingPlanes[ 4 ].a * gl_FragCoord.x + clippingPlanes[ 4 ].b * gl_FragCoord.y + clippingPlanes[ 4 ].c * gl_FragCoord.z + clippingPlanes[ 4 ].d < 0.0 ) discard;
		#endif
		#if NUM_CLIPPING_PLANES > 5
			if ( clippingPlanes[ 5 ].a * gl_FragCoord.x + clippingPlanes[ 5 ].b * gl_FragCoord.y + clippingPlanes[ 5 ].c * gl_FragCoord.z + clippingPlanes[ 5 ].d < 0.0 ) discard;
		#endif
		#if NUM_CLIPPING_PLANES > 6
			if ( clippingPlanes[ 6 ].a * gl_FragCoord.x + clippingPlanes[ 6 ].b * gl_FragCoord.y + clippingPlanes[ 6 ].c * gl_FragCoord.z + clippingPlanes[ 6 ].d < 0.0 ) discard;
		#endif
		#if NUM_CLIPPING_PLANES > 7
			if ( clippingPlanes[ 7 ].a * gl_FragCoord.x + clippingPlanes[ 7 ].b * gl_FragCoord.y + clippingPlanes[ 7 ].c * gl_FragCoord.z + clippingPlanes[ 7 ].d < 0.0 ) discard;
		#endif
	#endif`;
        case 'opaque_fragment':
          return `#ifdef USE_OPAQUE
		gl_FragColor = vec4( outgoingLight, diffuseColor.a );
	#endif`;
        case 'tonemapping_fragment':
          return `#ifdef USE_TONEMAPPING
		gl_FragColor.rgb = toneMapping( gl_FragColor.rgb );
	#endif`;
        case 'colorspace_fragment':
          return `#ifdef USE_COLORSPACE
		gl_FragColor.rgb = colorspace( gl_FragColor.rgb );
	#endif`;
        case 'fog_fragment':
          return `#ifdef USE_FOG
		float fogFactor = smoothstep( fogNear, fogFar, fogDepth );
		gl_FragColor.rgb = mix( gl_FragColor.rgb, fogColor, fogFactor );
	#endif`;
        default:
          return '// #include <' + includeName + '>';
      }
    });

    // Wrap the code in a class
    return {
      expr: {
        type: {
          kind: Type.TPath,
          path: {
            pack: {
              name: "Main",
              comps: [],
              imp: true
            },
            name: "Glsl",
            comps: []
          },
          params: []
        },
        kind: Expr.EField,
        field: code
      }
    };
  }
}

class Main {
  static function main() {
    Context.current().macro.error("This is a glsl to haxe converter, it can't be compiled.", 0, 0);
  }
}


**Explanation:**

1. **Import necessary Haxe macros:**
   - `haxe.macro.Context` provides access to the macro context.
   - `haxe.macro.Expr` represents Haxe expressions.
   - `haxe.macro.Type` provides tools for defining types.

2. **Create `Glsl` class:**
   - `convert` function:
     - Takes a `Context` and `Expr` as input.
     - Converts the JavaScript GLSL code to Haxe code.
     - Removes the `/* glsl */` strings.
     - Replaces `export const` with `static public var`.
     - Replaces `vec2/vec3` with `Vector2/Vector3`.
     - Replaces `uniform` with `var`.
     - Replaces `#include` directives with the corresponding GLSL code.
     - Wraps the code in a `Glsl` class.

3. **Create `Main` class:**
   - `main` function:
     - Outputs an error message to prevent compiling the code directly. This is because the code is meant to be used as a macro, not compiled into an Haxe program.

**How to use:**

1. **Save the code as a Haxe file:** For example, `Glsl.hx`.
2. **Use the `Glsl.convert` macro:**

   
   import Glsl;

   class MyShader {
     static public var vertex = #Glsl.convert(
       `
       uniform float rotation;
       uniform vec2 center;

       #include <common>
       #include <uv_pars_vertex>
       #include <fog_pars_vertex>
       #include <logdepthbuf_pars_vertex>
       #include <clipping_planes_pars_vertex>

       void main() {

         #include <uv_vertex>

         vec4 mvPosition = modelViewMatrix * vec4( 0.0, 0.0, 0.0, 1.0 );

         vec2 scale;
         scale.x = length( vec3( modelMatrix[ 0 ].x, modelMatrix[ 0 ].y, modelMatrix[ 0 ].z ) );
         scale.y = length( vec3( modelMatrix[ 1 ].x, modelMatrix[ 1 ].y, modelMatrix[ 1 ].z ) );

         #ifndef USE_SIZEATTENUATION

           bool isPerspective = isPerspectiveMatrix( projectionMatrix );

           if ( isPerspective ) scale *= - mvPosition.z;

         #endif

         vec2 alignedPosition = ( position.xy - ( center - vec2( 0.5 ) ) ) * scale;

         vec2 rotatedPosition;
         rotatedPosition.x = cos( rotation ) * alignedPosition.x - sin( rotation ) * alignedPosition.y;
         rotatedPosition.y = sin( rotation ) * alignedPosition.x + cos( rotation ) * alignedPosition.y;

         mvPosition.xy += rotatedPosition;

         gl_Position = projectionMatrix * mvPosition;

         #include <logdepthbuf_vertex>
         #include <clipping_planes_vertex>
         #include <fog_vertex>

       }
       `
     );
     static public var fragment = #Glsl.convert(
       `
       uniform vec3 diffuse;
       uniform float opacity;

       #include <common>
       #include <uv_pars_fragment>
       #include <map_pars_fragment>
       #include <alphamap_pars_fragment>
       #include <alphatest_pars_fragment>
       #include <alphahash_pars_fragment>
       #include <fog_pars_fragment>
       #include <logdepthbuf_pars_fragment>
       #include <clipping_planes_pars_fragment>

       void main() {

         vec4 diffuseColor = vec4( diffuse, opacity );
         #include <clipping_planes_fragment>

         vec3 outgoingLight = vec3( 0.0 );

         #include <logdepthbuf_fragment>
         #include <map_fragment>
         #include <alphamap_fragment>
         #include <alphatest_fragment>
         #include <alphahash_fragment>

         outgoingLight = diffuseColor.rgb;

         #include <opaque_fragment>
         #include <tonemapping_fragment>
         #include <colorspace_fragment>
         #include <fog_fragment>

       }
       `
     );
   }