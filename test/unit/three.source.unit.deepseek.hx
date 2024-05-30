import three.utils.ConsoleWrapper;
import three.utils.QunitUtils;

//src
import three.src.ConstantsTests;
import three.src.UtilsTests;

//src/animation
import three.src.animation.AnimationActionTests;
import three.src.animation.AnimationClipTests;
import three.src.animation.AnimationMixerTests;
import three.src.animation.AnimationObjectGroupTests;
import three.src.animation.AnimationUtilsTests;
import three.src.animation.KeyframeTrackTests;
import three.src.animation.PropertyBindingTests;
import three.src.animation.PropertyMixerTests;

//src/animation/tracks
import three.src.animation.tracks.BooleanKeyframeTrackTests;
import three.src.animation.tracks.ColorKeyframeTrackTests;
import three.src.animation.tracks.NumberKeyframeTrackTests;
import three.src.animation.tracks.QuaternionKeyframeTrackTests;
import three.src.animation.tracks.StringKeyframeTrackTests;
import three.src.animation.tracks.VectorKeyframeTrackTests;

//src/audio
import three.src.audio.AudioTests;
import three.src.audio.AudioAnalyserTests;
import three.src.audio.AudioContextTests;
import three.src.audio.AudioListenerTests;
import three.src.audio.PositionalAudioTests;

//src/cameras
import three.src.cameras.ArrayCameraTests;
import three.src.cameras.CameraTests;
import three.src.cameras.CubeCameraTests;
import three.src.cameras.OrthographicCameraTests;
import three.src.cameras.PerspectiveCameraTests;
import three.src.cameras.StereoCameraTests;

//src/core
import three.src.core.BufferAttributeTests;
import three.src.core.BufferGeometryTests;
import three.src.core.ClockTests;
import three.src.core.EventDispatcherTests;
import three.src.core.GLBufferAttributeTests;
import three.src.core.InstancedBufferAttributeTests;
import three.src.core.InstancedBufferGeometryTests;
import three.src.core.InstancedInterleavedBufferTests;
import three.src.core.InterleavedBufferTests;
import three.src.core.InterleavedBufferAttributeTests;
import three.src.core.LayersTests;
import three.src.core.Object3DTests;
import three.src.core.RaycasterTests;
import three.src.core.UniformTests;
import three.src.core.UniformsGroupTests;

//src/extras
import three.src.extras.DataUtilsTests;
import three.src.extras.EarcutTests;
import three.src.extras.ImageUtilsTests;
import three.src.extras.PMREMGeneratorTests;
import three.src.extras.ShapeUtilsTests;

//src/extras/core
import three.src.extras.core.CurveTests;
import three.src.extras.core.CurvePathTests;
import three.src.extras.core.InterpolationsTests;
import three.src.extras.core.PathTests;
import three.src.extras.core.ShapeTests;
import three.src.extras.core.ShapePathTests;

//src/extras/curves
import three.src.extras.curves.ArcCurveTests;
import three.src.extras.curves.CatmullRomCurve3Tests;
import three.src.extras.curves.CubicBezierCurveTests;
import three.src.extras.curves.CubicBezierCurve3Tests;
import three.src.extras.curves.EllipseCurveTests;
import three.src.extras.curves.LineCurveTests;
import three.src.extras.curves.LineCurve3Tests;
import three.src.extras.curves.QuadraticBezierCurveTests;
import three.src.extras.curves.QuadraticBezierCurve3Tests;
import three.src.extras.curves.SplineCurveTests;

//src/geometries
import three.src.geometries.BoxGeometryTests;
import three.src.geometries.CapsuleGeometryTests;
import three.src.geometries.CircleGeometryTests;
import three.src.geometries.ConeGeometryTests;
import three.src.geometries.CylinderGeometryTests;
import three.src.geometries.DodecahedronGeometryTests;
import three.src.geometries.EdgesGeometryTests;
import three.src.geometries.ExtrudeGeometryTests;
import three.src.geometries.IcosahedronGeometryTests;
import three.src.geometries.LatheGeometryTests;
import three.src.geometries.OctahedronGeometryTests;
import three.src.geometries.PlaneGeometryTests;
import three.src.geometries.PolyhedronGeometryTests;
import three.src.geometries.RingGeometryTests;
import three.src.geometries.ShapeGeometryTests;
import three.src.geometries.SphereGeometryTests;
import three.src.geometries.TetrahedronGeometryTests;
import three.src.geometries.TorusGeometryTests;
import three.src.geometries.TorusKnotGeometryTests;
import three.src.geometries.TubeGeometryTests;
import three.src.geometries.WireframeGeometryTests;

//src/helpers
import three.src.helpers.ArrowHelperTests;
import three.src.helpers.AxesHelperTests;
import three.src.helpers.Box3HelperTests;
import three.src.helpers.BoxHelperTests;
import three.src.helpers.CameraHelperTests;
import three.src.helpers.DirectionalLightHelperTests;
import three.src.helpers.GridHelperTests;
import three.src.helpers.HemisphereLightHelperTests;
import three.src.helpers.PlaneHelperTests;
import three.src.helpers.PointLightHelperTests;
import three.src.helpers.PolarGridHelperTests;
import three.src.helpers.SkeletonHelperTests;
import three.src.helpers.SpotLightHelperTests;

//src/lights
import three.src.lights.AmbientLightTests;
import three.src.lights.DirectionalLightTests;
import three.src.lights.DirectionalLightShadowTests;
import three.src.lights.HemisphereLightTests;
import three.src.lights.LightTests;
import three.src.lights.LightProbeTests;
import three.src.lights.LightShadowTests;
import three.src.lights.PointLightTests;
import three.src.lights.PointLightShadowTests;
import three.src.lights.RectAreaLightTests;
import three.src.lights.SpotLightTests;
import three.src.lights.SpotLightShadowTests;

//src/loaders
import three.src.loaders.AnimationLoaderTests;
import three.src.loaders.AudioLoaderTests;
import three.src.loaders.BufferGeometryLoaderTests;
import three.src.loaders.CacheTests;
import three.src.loaders.CompressedTextureLoaderTests;
import three.src.loaders.CubeTextureLoaderTests;
import three.src.loaders.DataTextureLoaderTests;
import three.src.loaders.FileLoaderTests;
import three.src.loaders.ImageBitmapLoaderTests;
import three.src.loaders.ImageLoaderTests;
import three.src.loaders.LoaderTests;
import three.src.loaders.LoaderUtilsTests;
import three.src.loaders.LoadingManagerTests;
import three.src.loaders.MaterialLoaderTests;
import three.src.loaders.ObjectLoaderTests;
import three.src.loaders.TextureLoaderTests;

//src/materials
import three.src.materials.LineBasicMaterialTests;
import three.src.materials.LineDashedMaterialTests;
import three.src.materials.MaterialTests;
import three.src.materials.MeshBasicMaterialTests;
import three.src.materials.MeshDepthMaterialTests;
import three.src.materials.MeshDistanceMaterialTests;
import three.src.materials.MeshLambertMaterialTests;
import three.src.materials.MeshMatcapMaterialTests;
import three.src.materials.MeshNormalMaterialTests;
import three.src.materials.MeshPhongMaterialTests;
import three.src.materials.MeshPhysicalMaterialTests;
import three.src.materials.MeshStandardMaterialTests;
import three.src.materials.MeshToonMaterialTests;
import three.src.materials.PointsMaterialTests;
import three.src.materials.RawShaderMaterialTests;
import three.src.materials.ShaderMaterialTests;
import three.src.materials.ShadowMaterialTests;
import three.src.materials.SpriteMaterialTests;

//src/math
import three.src.math.Box2Tests;
import three.src.math.Box3Tests;
import three.src.math.ColorTests;
import three.src.math.ColorManagementTests;
import three.src.math.CylindricalTests;
import three.src.math.EulerTests;
import three.src.math.FrustumTests;
import three.src.math.InterpolantTests;
import three.src.math.Line3Tests;
import three.src.math.MathUtilsTests;
import three.src.math.Matrix3Tests;
import three.src.math.Matrix4Tests;
import three.src.math.PlaneTests;
import three.src.math.QuaternionTests;
import three.src.math.RayTests;
import three.src.math.SphereTests;
import three.src.math.SphericalTests;
import three.src.math.SphericalHarmonics3Tests;
import three.src.math.TriangleTests;
import three.src.math.Vector2Tests;
import three.src.math.Vector3Tests;
import three.src.math.Vector4Tests;

//src/math/interpolants
import three.src.math.interpolants.CubicInterpolantTests;
import three.src.math.interpolants.DiscreteInterpolantTests;
import three.src.math.interpolants.LinearInterpolantTests;
import three.src.math.interpolants.QuaternionLinearInterpolantTests;

//src/objects
import three.src.objects.BoneTests;
import three.src.objects.GroupTests;
import three.src.objects.InstancedMeshTests;
import three.src.objects.LineTests;
import three.src.objects.LineLoopTests;
import three.src.objects.LineSegmentsTests;
import three.src.objects.LODTests;
import three.src.objects.MeshTests;
import three.src.objects.PointsTests;
import three.src.objects.SkeletonTests;
import three.src.objects.SkinnedMeshTests;
import three.src.objects.SpriteTests;

//src/renderers
import three.src.renderers.WebGL3DRenderTargetTests;
import three.src.renderers.WebGLArrayRenderTargetTests;
import three.src.renderers.WebGLCubeRenderTargetTests;
import three.src.renderers.WebGLRendererTests;
import three.src.renderers.WebGLRenderTargetTests;

//src/renderers/shaders
import three.src.renderers.shaders.ShaderChunkTests;
import three.src.renderers.shaders.ShaderLibTests;
import three.src.renderers.shaders.UniformsLibTests;
import three.src.renderers.shaders.UniformsUtilsTests;

//src/renderers/webgl
import three.src.renderers.webgl.WebGLAttributesTests;
import three.src.renderers.webgl.WebGLBackgroundTests;
import three.src.renderers.webgl.WebGLBufferRendererTests;
import three.src.renderers.webgl.WebGLCapabilitiesTests;
import three.src.renderers.webgl.WebGLClippingTests;
import three.src.renderers.webgl.WebGLExtensionsTests;
import three.src.renderers.webgl.WebGLGeometriesTests;
import three.src.renderers.webgl.WebGLIndexedBufferRendererTests;
import three.src.renderers.webgl.WebGLLightsTests;
import three.src.renderers.webgl.WebGLMorphtargetsTests;
import three.src.renderers.webgl.WebGLObjectsTests;
import three.src.renderers.webgl.WebGLProgramTests;
import three.src.renderers.webgl.WebGLProgramsTests;
import three.src.renderers.webgl.WebGLPropertiesTests;
import three.src.renderers.webgl.WebGLRenderListsTests;
import three.src.renderers.webgl.WebGLShaderTests;
import three.src.renderers.webgl.WebGLShadowMapTests;
import three.src.renderers.webgl.WebGLStateTests;
import three.src.renderers.webgl.WebGLTexturesTests;
import three.src.renderers.webgl.WebGLUniformsTests;
import three.src.renderers.webgl.WebGLUtilsTests;

//src/scenes
import three.src.scenes.FogTests;
import three.src.scenes.FogExp2Tests;
import three.src.scenes.SceneTests;

//src/textures
import three.src.textures.CanvasTextureTests;
import three.src.textures.CompressedArrayTextureTests;
import three.src.textures.CompressedTextureTests;
import three.src.textures.CubeTextureTests;
import three.src.textures.Data3DTextureTests;
import three.src.textures.DataArrayTextureTests;
import three.src.textures.DataTextureTests;
import three.src.textures.DepthTextureTests;
import three.src.textures.FramebufferTextureTests;
import three.src.textures.SourceTests;
import three.src.textures.TextureTests;
import three.src.textures.VideoTextureTests;