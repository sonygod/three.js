package three;

import three.constants.REVISION;

@:keep
@:expose
class Three {
    public function new() {}

    // renderers
    public static var WebGLArrayRenderTarget:Dynamic;
    public static var WebGL3DRenderTarget:Dynamic;
    public static var WebGLCubeRenderTarget:Dynamic;
    public static var WebGLRenderTarget:Dynamic;
    public static var WebGLRenderer:Dynamic;
    public static var ShaderLib:Dynamic;
    public static var UniformsLib:Dynamic;
    public static var UniformsUtils:Dynamic;
    public static var ShaderChunk:Dynamic;

    // scenes
    public static var FogExp2:Dynamic;
    public static var Fog:Dynamic;
    public static var Scene:Dynamic;

    // objects
    public static var Sprite:Dynamic;
    public static var LOD:Dynamic;
    public static var SkinnedMesh:Dynamic;
    public static var Skeleton:Dynamic;
    public static var Bone:Dynamic;
    public static var Mesh:Dynamic;
    public static var InstancedMesh:Dynamic;
    public static var BatchedMesh:Dynamic;
    public static var LineSegments:Dynamic;
    public static var LineLoop:Dynamic;
    public static var Line:Dynamic;
    public static var Points:Dynamic;
    public static var Group:Dynamic;

    // textures
    public static var VideoTexture:Dynamic;
    public static var FramebufferTexture:Dynamic;
    public static var Source:Dynamic;
    public static var DataTexture:Dynamic;
    public static var DataArrayTexture:Dynamic;
    public static var Data3DTexture:Dynamic;
    public static var CompressedTexture:Dynamic;
    public static var CompressedArrayTexture:Dynamic;
    public static var CompressedCubeTexture:Dynamic;
    public static var CubeTexture:Dynamic;
    public static var CanvasTexture:Dynamic;
    public static var DepthTexture:Dynamic;
    public static var Texture:Dynamic;

    // geometries
    public static var Geometries:Dynamic;

    // materials
    public static var Materials:Dynamic;

    // loaders
    public static var AnimationLoader:Dynamic;
    public static var CompressedTextureLoader:Dynamic;
    public static var CubeTextureLoader:Dynamic;
    public static var DataTextureLoader:Dynamic;
    public static var TextureLoader:Dynamic;
    public static var ObjectLoader:Dynamic;
    public static var MaterialLoader:Dynamic;
    public static var BufferGeometryLoader:Dynamic;
    public static var DefaultLoadingManager:Dynamic;
    public static var LoadingManager:Dynamic;
    public static var ImageLoader:Dynamic;
    public static var ImageBitmapLoader:Dynamic;
    public static var FileLoader:Dynamic;
    public static var Loader:Dynamic;
    public static var LoaderUtils:Dynamic;
    public static var Cache:Dynamic;
    public static var AudioLoader:Dynamic;

    // lights
    public static var SpotLight:Dynamic;
    public static var PointLight:Dynamic;
    public static var RectAreaLight:Dynamic;
    public static var HemisphereLight:Dynamic;
    public static var DirectionalLight:Dynamic;
    public static var AmbientLight:Dynamic;
    public static var Light:Dynamic;
    public static var LightProbe:Dynamic;

    // cameras
    public static var StereoCamera:Dynamic;
    public static var PerspectiveCamera:Dynamic;
    public static var OrthographicCamera:Dynamic;
    public static var CubeCamera:Dynamic;
    public static var ArrayCamera:Dynamic;
    public static var Camera:Dynamic;

    // audio
    public static var AudioListener:Dynamic;
    public static var PositionalAudio:Dynamic;
    public static var AudioContext:Dynamic;
    public static var AudioAnalyser:Dynamic;
    public static var Audio:Dynamic;

    // animation
    public static var VectorKeyframeTrack:Dynamic;
    public static var StringKeyframeTrack:Dynamic;
    public static var QuaternionKeyframeTrack:Dynamic;
    public static var NumberKeyframeTrack:Dynamic;
    public static var ColorKeyframeTrack:Dynamic;
    public static var BooleanKeyframeTrack:Dynamic;
    public static var PropertyMixer:Dynamic;
    public static var PropertyBinding:Dynamic;
    public static var KeyframeTrack:Dynamic;
    public static var AnimationUtils:Dynamic;
    public static var AnimationObjectGroup:Dynamic;
    public static var AnimationMixer:Dynamic;
    public static var AnimationClip:Dynamic;
    public static var AnimationAction:Dynamic;

    // core
    public static var RenderTarget:Dynamic;
    public static var Uniform:Dynamic;
    public static var UniformsGroup:Dynamic;
    public static var InstancedBufferGeometry:Dynamic;
    public static var BufferGeometry:Dynamic;
    public static var InterleavedBufferAttribute:Dynamic;
    public static var InstancedInterleavedBuffer:Dynamic;
    public static var InterleavedBuffer:Dynamic;
    public static var InstancedBufferAttribute:Dynamic;
    public static var GLBufferAttribute:Dynamic;
    public static var BufferAttribute:Dynamic;
    public static var Object3D:Dynamic;
    public static var Raycaster:Dynamic;
    public static var Layers:Dynamic;
    public static var EventDispatcher:Dynamic;
    public static var Clock:Dynamic;

    // math
    public static var QuaternionLinearInterpolant:Dynamic;
    public static var LinearInterpolant:Dynamic;
    public static var DiscreteInterpolant:Dynamic;
    public static var CubicInterpolant:Dynamic;
    public static var Interpolant:Dynamic;
    public static var Triangle:Dynamic;
    public static var MathUtils:Dynamic;
    public static var Spherical:Dynamic;
    public static var Cylindrical:Dynamic;
    public static var Plane:Dynamic;
    public static var Frustum:Dynamic;
    public static var Sphere:Dynamic;
    public static var Ray:Dynamic;
    public static var Matrix4:Dynamic;
    public static var Matrix3:Dynamic;
    public static var Box3:Dynamic;
    public static var Box2:Dynamic;
    public static var Line3:Dynamic;
    public static var Euler:Dynamic;
    public static var Vector4:Dynamic;
    public static var Vector3:Dynamic;
    public static var Vector2:Dynamic;
    public static var Quaternion:Dynamic;
    public static var Color:Dynamic;
    public static var ColorManagement:Dynamic;
    public static var SphericalHarmonics3:Dynamic;

    // helpers
    public static var SpotLightHelper:Dynamic;
    public static var SkeletonHelper:Dynamic;
    public static var PointLightHelper:Dynamic;
    public static var HemisphereLightHelper:Dynamic;
    public static var GridHelper:Dynamic;
    public static var PolarGridHelper:Dynamic;
    public static var DirectionalLightHelper:Dynamic;
    public static var CameraHelper:Dynamic;
    public static var BoxHelper:Dynamic;
    public static var Box3Helper:Dynamic;
    public static var PlaneHelper:Dynamic;
    public static var ArrowHelper:Dynamic;
    public static var AxesHelper:Dynamic;

    // extras
    public static var Curves:Dynamic;
    public static var Shape:Dynamic;
    public static var Path:Dynamic;
    public static var ShapePath:Dynamic;
    public static var CurvePath:Dynamic;
    public static var Curve:Dynamic;
    public static var DataUtils:Dynamic;
    public static var ImageUtils:Dynamic;
    public static var ShapeUtils:Dynamic;
    public static var PMREMGenerator:Dynamic;
    public static var WebGLUtils:Dynamic;

    static function main() {
        if (untyped __THREE_DEVTOOLS__ != null) {
            untyped __THREE_DEVTOOLS__.dispatchEvent(new CustomEvent("register", { detail: { revision: REVISION } }));
        }

        if (untyped window != null) {
            if (untyped window.__THREE__ != null) {
                console.warn("WARNING: Multiple instances of Three.js being imported.");
            } else {
                untyped window.__THREE__ = REVISION;
            }
        }
    }
}