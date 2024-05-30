#if js
import js.html.CustomEvent;
#end

#if js
import js.Browser;
#end

import Three.WebGLArrayRenderTarget;
import Three.WebGL3DRenderTarget;
import Three.WebGLCubeRenderTarget;
import Three.WebGLRenderTarget;
import Three.WebGLRenderer;
import Three.ShaderLib;
import Three.UniformsLib;
import Three.UniformsUtils;
import Three.ShaderChunk;
import Three.FogExp2;
import Three.Fog;
import Three.Scene;
import Three.Sprite;
import Three.LOD;
import Three.SkinnedMesh;
import Three.Skeleton;
import Three.Bone;
import Three.Mesh;
import Three.InstancedMesh;
import Three.BatchedMesh;
import Three.LineSegments;
import Three.LineLoop;
import Three.Line;
import Three.Points;
import Three.Group;
import Three.VideoTexture;
import Three.FramebufferTexture;
import Three.Source;
import Three.DataTexture;
import Three.DataArrayTexture;
import Three.Data3DTexture;
import Three.CompressedTexture;
import Three.CompressedArrayTexture;
import Three.CompressedCubeTexture;
import Three.CubeTexture;
import Three.CanvasTexture;
import Three.DepthTexture;
import Three.Texture;
import Three.geometries.Geometries;
import Three.materials.Materials;
import Three.loaders.AnimationLoader;
import Three.loaders.CompressedTextureLoader;
import Three.loaders.CubeTextureLoader;
import Three.loaders.DataTextureLoader;
import Three.loaders.TextureLoader;
import Three.loaders.ObjectLoader;
import Three.loaders.MaterialLoader;
import Three.loaders.BufferGeometryLoader;
import Three.loaders.DefaultLoadingManager;
import Three.loaders.LoadingManager;
import Three.loaders.ImageLoader;
import Three.loaders.ImageBitmapLoader;
import Three.loaders.FileLoader;
import Three.loaders.Loader;
import Three.loaders.LoaderUtils;
import Three.loaders.Cache;
import Three.loaders.AudioLoader;
import Three.lights.SpotLight;
import Three.lights.PointLight;
import Three.lights.RectAreaLight;
import Three.lights.HemisphereLight;
import Three.lights.DirectionalLight;
import Three.lights.AmbientLight;
import Three.lights.Light;
import Three.lights.LightProbe;
import Three.cameras.StereoCamera;
import Three.cameras.PerspectiveCamera;
import Three.cameras.OrthographicCamera;
import Three.cameras.CubeCamera;
import Three.cameras.ArrayCamera;
import Three.cameras.Camera;
import Three.audio.AudioListener;
import Three.audio.PositionalAudio;
import Three.audio.AudioContext;
import Three.audio.AudioAnalyser;
import Three.audio.Audio;
import Three.animation.tracks.VectorKeyframeTrack;
import Three.animation.tracks.StringKeyframeTrack;
import Three.animation.tracks.QuaternionKeyframeTrack;
import Three.animation.tracks.NumberKeyframeTrack;
import Three.animation.tracks.ColorKeyframeTrack;
import Three.animation.tracks.BooleanKeyframeTrack;
import Three.animation.PropertyMixer;
import Three.animation.PropertyBinding;
import Three.animation.KeyframeTrack;
import Three.animation.AnimationUtils;
import Three.animation.AnimationObjectGroup;
import Three.animation.AnimationMixer;
import Three.animation.AnimationClip;
import Three.animation.AnimationAction;
import Three.core.RenderTarget;
import Three.core.Uniform;
import Three.core.UniformsGroup;
import Three.core.InstancedBufferGeometry;
import Three.core.BufferGeometry;
import Three.core.InterleavedBufferAttribute;
import Three.core.InstancedInterleavedBuffer;
import Three.core.InterleavedBuffer;
import Three.core.InstancedBufferAttribute;
import Three.core.GLBufferAttribute;
import Three.core.BufferAttribute;
import Three.core.Object3D;
import Three.core.Raycaster;
import Three.core.Layers;
import Three.core.EventDispatcher;
import Three.core.Clock;
import Three.math.interpolants.QuaternionLinearInterpolant;
import Three.math.interpolants.LinearInterpolant;
import Three.math.interpolants.DiscreteInterpolant;
import Three.math.interpolants.CubicInterpolant;
import Three.math.Interpolant;
import Three.math.Triangle;
import Three.math.MathUtils;
import Three.math.Spherical;
import Three.math.Cylindrical;
import Three.math.Plane;
import Three.math.Frustum;
import Three.math.Sphere;
import Three.math.Ray;
import Three.math.Matrix4;
import Three.math.Matrix3;
import Three.math.Box3;
import Three.math.Box2;
import Three.math.Line3;
import Three.math.Euler;
import Three.math.Vector4;
import Three.math.Vector3;
import Three.math.Vector2;
import Three.math.Quaternion;
import Three.math.Color;
import Three.math.ColorManagement;
import Three.math.SphericalHarmonics3;
import Three.helpers.SpotLightHelper;
import Three.helpers.SkeletonHelper;
import Three.helpers.PointLightHelper;
import Three.helpers.HemisphereLightHelper;
import Three.helpers.GridHelper;
import Three.helpers.PolarGridHelper;
import Three.helpers.DirectionalLightHelper;
import Three.helpers.CameraHelper;
import Three.helpers.BoxHelper;
import Three.helpers.Box3Helper;
import Three.helpers.PlaneHelper;
import Three.helpers.ArrowHelper;
import Three.helpers.AxesHelper;
import Three.extras.curves.Curves;
import Three.extras.core.Shape;
import Three.extras.core.Path;
import Three.extras.core.ShapePath;
import Three.extras.core.CurvePath;
import Three.extras.core.Curve;
import Three.extras.DataUtils;
import Three.extras.ImageUtils;
import Three.extras.ShapeUtils;
import Three.extras.PMREMGenerator;
import Three.renderers.webgl.WebGLUtils;

class ThreeLegacy {}

class Three {
    public static var REVISION:Int = 0; // replace with the actual revision number

    public static function main() {
        #if js
        var threeDevToolsAvailable = js.Lib["__THREE_DEVTOOLS__"] != null;
        if (threeDevToolsAvailable) {
            Browser.window.dispatchEvent(new CustomEvent("register", { detail: { revision: Three.REVISION }}));
        }
        #end

        #if js
        if (Browser.window != null) {
            if (Browser.window.hasOwnProperty("__THREE__")) {
                trace("WARNING: Multiple instances of Three.js being imported.");
            } else {
                Browser.window["__THREE__"] = Three.REVISION;
            }
        }
        #end
    }
}