import three.js.examples.jsm.objects.ReflectorForSSRPass;
import three.js.examples.jsm.objects.ReflectorForSSRPass.ReflectorShader;
import three.js.examples.jsm.objects.ReflectorForSSRPass.ReflectorShader.UniformsUtils;
import three.js.examples.jsm.objects.ReflectorForSSRPass.ReflectorShader.Vector2;
import three.js.examples.jsm.objects.ReflectorForSSRPass.ReflectorShader.Vector3;
import three.js.examples.jsm.objects.ReflectorForSSRPass.ReflectorShader.Matrix4;
import three.js.examples.jsm.objects.ReflectorForSSRPass.ReflectorShader.ShaderMaterial;
import three.js.examples.jsm.objects.ReflectorForSSRPass.ReflectorShader.Color;
import three.js.examples.jsm.objects.ReflectorForSSRPass.ReflectorShader.Plane;
import three.js.examples.jsm.objects.ReflectorForSSRPass.ReflectorShader.WebGLRenderTarget;
import three.js.examples.jsm.objects.ReflectorForSSRPass.ReflectorShader.DepthTexture;
import three.js.examples.jsm.objects.ReflectorForSSRPass.ReflectorShader.UnsignedShortType;
import three.js.examples.jsm.objects.ReflectorForSSRPass.ReflectorShader.NearestFilter;
import three.js.examples.jsm.objects.ReflectorForSSRPass.ReflectorShader.PerspectiveCamera;
import three.js.examples.jsm.objects.ReflectorForSSRPass.ReflectorShader.HalfFloatType;

class ReflectorForSSRPass extends Mesh {

  public function new(geometry:Geometry, options:Dynamic) {
    super(geometry);

    this.isReflectorForSSRPass = true;
    this.type = 'ReflectorForSSRPass';

    var scope = this;

    var color = (options.color !== null) ? new Color(options.color) : new Color(0x7F7F7F);
    var textureWidth = options.textureWidth || 512;
    var textureHeight = options.textureHeight || 512;
    var clipBias = options.clipBias || 0;
    var shader = options.shader || ReflectorForSSRPass.ReflectorShader;
    var useDepthTexture = options.useDepthTexture === true;
    var yAxis = new Vector3(0, 1, 0);
    var vecTemp0 = new Vector3();
    var vecTemp1 = new Vector3();

    // ... rest of the code ...
  }

  // ... rest of the class methods ...
}

ReflectorForSSRPass.ReflectorShader = {

  name: 'ReflectorShader',

  defines: {
    DISTANCE_ATTENUATION: true,
    FRESNEL: true,
  },

  uniforms: {

    color: { value: null },
    tDiffuse: { value: null },
    tDepth: { value: null },
    textureMatrix: { value: new Matrix4() },
    maxDistance: { value: 180 },
    opacity: { value: 0.5 },
    fresnelCoe: { value: null },
    virtualCameraNear: { value: null },
    virtualCameraFar: { value: null },
    virtualCameraProjectionMatrix: { value: new Matrix4() },
    virtualCameraMatrixWorld: { value: new Matrix4() },
    virtualCameraProjectionMatrixInverse: { value: new Matrix4() },
    resolution: { value: new Vector2() },

  },

  vertexShader: /* glsl */`
    uniform mat4 textureMatrix;
    varying vec4 vUv;

    void main() {

      vUv = textureMatrix * vec4( position, 1.0 );

      gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );

    }`,

  fragmentShader: /* glsl */`
    uniform vec3 color;
    uniform sampler2D tDiffuse;
    uniform sampler2D tDepth;
    uniform float maxDistance;
    uniform float opacity;
    uniform float fresnelCoe;
    uniform float virtualCameraNear;
    uniform float virtualCameraFar;
    uniform mat4 virtualCameraProjectionMatrix;
    uniform mat4 virtualCameraProjectionMatrixInverse;
    uniform mat4 virtualCameraMatrixWorld;
    uniform vec2 resolution;
    varying vec4 vUv;
    #include <packing>
    float blendOverlay( float base, float blend ) {
      return( base < 0.5 ? ( 2.0 * base * blend ) : ( 1.0 - 2.0 * ( 1.0 - base ) * ( 1.0 - blend ) ) );
    }
    vec3 blendOverlay( vec3 base, vec3 blend ) {
      return vec3( blendOverlay( base.r, blend.r ), blendOverlay( base.g, blend.g ), blendOverlay( base.b, blend.b ) );
    }
    float getDepth( const in vec2 uv ) {
      return texture2D( tDepth, uv ).x;
    }
    float getViewZ( const in float depth ) {
      return perspectiveDepthToViewZ( depth, virtualCameraNear, virtualCameraFar );
    }
    vec3 getViewPosition( const in vec2 uv, const in float depth/*clip space*/, const in float clipW ) {
      vec4 clipPosition = vec4( ( vec3( uv, depth ) - 0.5 ) * 2.0, 1.0 );//ndc
      clipPosition *= clipW; //clip
      return ( virtualCameraProjectionMatrixInverse * clipPosition ).xyz;//view
    }
    void main() {
      vec4 base = texture2DProj( tDiffuse, vUv );
      #ifdef useDepthTexture
        vec2 uv=(gl_FragCoord.xy-.5)/resolution.xy;
        uv.x=1.-uv.x;
        float depth = texture2DProj( tDepth, vUv ).r;
        float viewZ = getViewZ( depth );
        float clipW = virtualCameraProjectionMatrix[2][3] * viewZ+virtualCameraProjectionMatrix[3][3];
        vec3 viewPosition=getViewPosition( uv, depth, clipW );
        vec3 worldPosition=(virtualCameraMatrixWorld*vec4(viewPosition,1)).xyz;
        if(worldPosition.y>maxDistance) discard;
        float op=opacity;
        #ifdef DISTANCE_ATTENUATION
          float ratio=1.-(worldPosition.y/maxDistance);
          float attenuation=ratio*ratio;
          op=opacity*attenuation;
        #endif
        #ifdef FRESNEL
          op*=fresnelCoe;
        #endif
        gl_FragColor = vec4( blendOverlay( base.rgb, color ), op );
      #else
        gl_FragColor = vec4( blendOverlay( base.rgb, color ), 1.0 );
      #endif
    }
  `,
};

export ReflectorForSSRPass;