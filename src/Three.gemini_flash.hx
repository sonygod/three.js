import three.constants.REVISION;

// Renderers
import three.renderers.WebGLArrayRenderTarget;
import three.renderers.WebGL3DRenderTarget;
import three.renderers.WebGLCubeRenderTarget;
import three.renderers.WebGLRenderTarget;
import three.renderers.WebGLRenderer;

// Renderers - Shaders
import three.renderers.shaders.ShaderLib;
import three.renderers.shaders.UniformsLib;
import three.renderers.shaders.UniformsUtils;
import three.renderers.shaders.ShaderChunk;

// Scenes
import three.scenes.FogExp2;
import three.scenes.Fog;
import three.scenes.Scene;

// Objects
import three.objects.Sprite;
import three.objects.LOD;
import three.objects.SkinnedMesh;
import three.objects.Skeleton;
import three.objects.Bone;
import three.objects.Mesh;
import three.objects.InstancedMesh;
import three.objects.BatchedMesh;
import three.objects.LineSegments;
import three.objects.LineLoop;
import three.objects.Line;
import three.objects.Points;
import three.objects.Group;

// Textures
import three.textures.VideoTexture;
import three.textures.FramebufferTexture;
import three.textures.Source;
import three.textures.DataTexture;
import three.textures.DataArrayTexture;
import three.textures.Data3DTexture;
import three.textures.CompressedTexture;
import three.textures.CompressedArrayTexture;
import three.textures.CompressedCubeTexture;
import three.textures.CubeTexture;
import three.textures.CanvasTexture;
import three.textures.DepthTexture;
import three.textures.Texture;

// Geometries
import three.geometries.*;

// Materials
import three.materials.*;

// Loaders
import three.loaders.AnimationLoader;
import three.loaders.CompressedTextureLoader;
import three.loaders.CubeTextureLoader;
import three.loaders.DataTextureLoader;
import three.loaders.TextureLoader;
import three.loaders.ObjectLoader;
import three.loaders.MaterialLoader;
import three.loaders.BufferGeometryLoader;
import three.loaders.DefaultLoadingManager;
import three.loaders.LoadingManager;
import three.loaders.ImageLoader;
import three.loaders.ImageBitmapLoader;
import three.loaders.FileLoader;
import three.loaders.Loader;
import three.loaders.LoaderUtils;
import three.loaders.Cache;
import three.loaders.AudioLoader;

// Lights
import three.lights.SpotLight;
import three.lights.PointLight;
import three.lights.RectAreaLight;
import three.lights.HemisphereLight;
import three.lights.DirectionalLight;
import three.lights.AmbientLight;
import three.lights.Light;
import three.lights.LightProbe;

// Cameras
import three.cameras.StereoCamera;
import three.cameras.PerspectiveCamera;
import three.cameras.OrthographicCamera;
import three.cameras.CubeCamera;
import three.cameras.ArrayCamera;
import three.cameras.Camera;

// Audio
import three.audio.AudioListener;
import three.audio.PositionalAudio;
import three.audio.AudioContext;
import three.audio.AudioAnalyser;
import three.audio.Audio;

// Animation
import three.animation.tracks.VectorKeyframeTrack;
import three.animation.tracks.StringKeyframeTrack;
import three.animation.tracks.QuaternionKeyframeTrack;
import three.animation.tracks.NumberKeyframeTrack;
import three.animation.tracks.ColorKeyframeTrack;
import three.animation.tracks.BooleanKeyframeTrack;
import three.animation.PropertyMixer;
import three.animation.PropertyBinding;
import three.animation.KeyframeTrack;
import three.animation.AnimationUtils;
import three.animation.AnimationObjectGroup;
import three.animation.AnimationMixer;
import three.animation.AnimationClip;
import three.animation.AnimationAction;

// Core
import three.core.RenderTarget;
import three.core.Uniform;
import three.core.UniformsGroup;
import three.core.InstancedBufferGeometry;
import three.core.BufferGeometry;
import three.core.InterleavedBufferAttribute;
import three.core.InstancedInterleavedBuffer;
import three.core.InterleavedBuffer;
import three.core.InstancedBufferAttribute;
import three.core.GLBufferAttribute;
import three.core.BufferAttribute;
import three.core.Object3D;
import three.core.Raycaster;
import three.core.Layers;
import three.core.EventDispatcher;
import three.core.Clock;

// Math
import three.math.interpolants.QuaternionLinearInterpolant;
import three.math.interpolants.LinearInterpolant;
import three.math.interpolants.DiscreteInterpolant;
import three.math.interpolants.CubicInterpolant;
import three.math.Interpolant;
import three.math.Triangle;
import three.math.MathUtils;
import three.math.Spherical;
import three.math.Cylindrical;
import three.math.Plane;
import three.math.Frustum;
import three.math.Sphere;
import three.math.Ray;
import three.math.Matrix4;
import three.math.Matrix3;
import three.math.Box3;
import three.math.Box2;
import three.math.Line3;
import three.math.Euler;
import three.math.Vector4;
import three.math.Vector3;
import three.math.Vector2;
import three.math.Quaternion;
import three.math.Color;
import three.math.ColorManagement;
import three.math.SphericalHarmonics3;

// Helpers
import three.helpers.SpotLightHelper;
import three.helpers.SkeletonHelper;
import three.helpers.PointLightHelper;
import three.helpers.HemisphereLightHelper;
import three.helpers.GridHelper;
import three.helpers.PolarGridHelper;
import three.helpers.DirectionalLightHelper;
import three.helpers.CameraHelper;
import three.helpers.BoxHelper;
import three.helpers.Box3Helper;
import three.helpers.PlaneHelper;
import three.helpers.ArrowHelper;
import three.helpers.AxesHelper;

// Extras - Curves
import three.extras.curves.*;

// Extras - Core
import three.extras.core.Shape;
import three.extras.core.Path;
import three.extras.core.ShapePath;
import three.extras.core.CurvePath;
import three.extras.core.Curve;

// Extras
import three.extras.DataUtils;
import three.extras.ImageUtils;
import three.extras.ShapeUtils;
import three.extras.PMREMGenerator;

// Renderers - Webgl
import three.renderers.webgl.WebGLUtils;

// Utils
import three.utils.createCanvasElement;

// Constants
import three.constants.*;
import three.ThreeLegacy;

class Three {
	public static function main():Void {
		if (js.Lib.exists("window") && js.Lib.typeof("window.__THREE__") == "undefined") {
			js.Lib.set("window.__THREE__", REVISION);
		}

		if (js.Lib.exists("window") && js.Lib.typeof("window.__THREE_DEVTOOLS__") != "undefined") {
			var event = new js.html.CustomEvent("register", {detail: {revision: REVISION}});
			js.Lib.get("window.__THREE_DEVTOOLS__").dispatchEvent(event);
		}
	}
}