package three.js.objects;

import three.js.Color;
import three.js.FrontSide;
import three.js.Matrix4;
import three.js.Mesh;
import three.js.PerspectiveCamera;
import three.js.Plane;
import three.js.ShaderMaterial;
import three.js.UniformsLib;
import three.js.UniformsUtils;
import three.js.Vector3;
import three.js.Vector4;
import three.js.WebGLRenderTarget;

@:native Gen("Water")
class Water extends Mesh {

    public var isWater:Bool = true;

    public function new(geometry:Geometry, ?options:{}) {
        super(geometry);

        var textureWidth:Int = options.textureWidth != null ? options.textureWidth : 512;
        var textureHeight:Int = options.textureHeight != null ? options.textureHeight : 512;

        var clipBias:Float = options.clipBias != null ? options.clipBias : 0.0;
        var alpha:Float = options.alpha != null ? options.alpha : 1.0;
        var time:Float = options.time != null ? options.time : 0.0;
        var normalSampler:Texture = options.waterNormals != null ? options.waterNormals : null;
        var sunDirection:Vector3 = options.sunDirection != null ? options.sunDirection : new Vector3(0.70707, 0.70707, 0.0);
        var sunColor:Color = options.sunColor != null ? new Color(options.sunColor) : new Color(0xffffff);
        var waterColor:Color = options.waterColor != null ? new Color(options.waterColor) : new Color(0x7F7F7F);
        var eye:Vector3 = options.eye != null ? options.eye : new Vector3(0, 0, 0);
        var distortionScale:Float = options.distortionScale != null ? options.distortionScale : 20.0;
        var side:Side = options.side != null ? options.side : FrontSide;
        var fog:Bool = options.fog != null ? options.fog : false;

        // ...

        var mirrorPlane:Plane = new Plane();
        var normal:Vector3 = new Vector3();
        var mirrorWorldPosition:Vector3 = new Vector3();
        var cameraWorldPosition:Vector3 = new Vector3();
        var rotationMatrix:Matrix4 = new Matrix4();
        var lookAtPosition:Vector3 = new Vector3(0, 0, -1);
        var clipPlane:Vector4 = new Vector4();

        var view:Vector3 = new Vector3();
        var target:Vector3 = new Vector3();
        var q:Vector4 = new Vector4();

        var textureMatrix:Matrix4 = new Matrix4();

        var mirrorCamera:PerspectiveCamera = new PerspectiveCamera();
        var renderTarget:WebGLRenderTarget = new WebGLRenderTarget(textureWidth, textureHeight);

        var mirrorShader:ShaderMaterial = {
            name: 'MirrorShader',
            uniforms: UniformsUtils.merge([
                UniformsLib.fog,
                UniformsLib.lights,
                {
                    normalSampler: { value: null },
                    mirrorSampler: { value: null },
                    alpha: { value: 1.0 },
                    time: { value: 0.0 },
                    size: { value: 1.0 },
                    distortionScale: { value: 20.0 },
                    textureMatrix: { value: new Matrix4() },
                    sunColor: { value: new Color(0x7F7F7F) },
                    sunDirection: { value: new Vector3(0.70707, 0.70707, 0) },
                    eye: { value: new Vector3() },
                    waterColor: { value: new Color(0x555555) }
                }
            ]),
            vertexShader: [
                "uniform mat4 textureMatrix;",
                "uniform float time;",
                "varying vec4 mirrorCoord;",
                "varying vec4 worldPosition;",
                "#include <common>",
                "#include <fog_pars_vertex>",
                "#include <shadowmap_pars_vertex>",
                "#include <logdepthbuf_pars_vertex>",
                "void main() {",
                "    mirrorCoord = modelMatrix * vec4( position, 1.0 );",
                "    worldPosition = mirrorCoord.xyzw;",
                "    mirrorCoord = textureMatrix * mirrorCoord;",
                "    vec4 mvPosition = modelViewMatrix * vec4( position, 1.0 );",
                "    gl_Position = projectionMatrix * mvPosition;",
                "#include <beginnormal_vertex>",
                "#include <defaultnormal_vertex>",
                "#include <logdepthbuf_vertex>",
                "#include <fog_vertex>",
                "#include <shadowmap_vertex>",
                "}"
            ].join("\n"),
            fragmentShader: [
                "uniform sampler2D mirrorSampler;",
                "uniform float alpha;",
                "uniform float time;",
                "uniform float size;",
                "uniform float distortionScale;",
                "uniform sampler2D normalSampler;",
                "uniform vec3 sunColor;",
                "uniform vec3 sunDirection;",
                "uniform vec3 eye;",
                "uniform vec3 waterColor;",
                "varying vec4 mirrorCoord;",
                "varying vec4 worldPosition;",
                "vec4 getNoise( vec2 uv ) {",
                "    // ...",
                "}",
                "void sunLight( const vec3 surfaceNormal, const vec3 eyeDirection, float shiny, float spec, float diffuse, inout vec3 diffuseColor, inout vec3 specularColor ) {",
                "    // ...",
                "}",
                "void main() {",
                "    // ...",
                "    gl_FragColor = vec4( outgoingLight, alpha );",
                "#include <tonemapping_fragment>",
                "#include <colorspace_fragment>",
                "#include <fog_fragment>",
                "}"
            ].join("\n"),
            lights: true,
            side: side,
            fog: fog
        };

        mirrorShader.uniforms.mirrorSampler.value = renderTarget.texture;
        mirrorShader.uniforms.textureMatrix.value = textureMatrix;
        mirrorShader.uniforms.alpha.value = alpha;
        mirrorShader.uniforms.time.value = time;
        mirrorShader.uniforms.normalSampler.value = normalSampler;
        mirrorShader.uniforms.sunColor.value = sunColor;
        mirrorShader.uniforms.waterColor.value = waterColor;
        mirrorShader.uniforms.sunDirection.value = sunDirection;
        mirrorShader.uniforms.distortionScale.value = distortionScale;

        mirrorShader.uniforms.eye.value = eye;

        material = new ShaderMaterial(mirrorShader);

        onBeforeRender = function(renderer:Renderer, scene:Scene, camera:Camera) {
            // ...
        };
    }
}