package three;

import utils.ConsoleWrapper;
import utils.QUnitUtils;

//src
import src.constants.ConstantsTests;
import src.utils.UtilsTests;

//src/animation
import src.animation.AnimationActionTests;
import src.animation.AnimationClipTests;
import src.animation.AnimationMixerTests;
import src.animation.AnimationObjectGroupTests;
import src.animation.AnimationUtilsTests;
import src.animation.KeyframeTrackTests;
import src.animation.PropertyBindingTests;
import src.animation.PropertyMixerTests;

//src/animation/tracks
import src.animation.tracks.BooleanKeyframeTrackTests;
import src.animation.tracks.ColorKeyframeTrackTests;
import src.animation.tracks.NumberKeyframeTrackTests;
import src.animation.tracks.QuaternionKeyframeTrackTests;
import src.animation.tracks.StringKeyframeTrackTests;
import src.animation.tracks.VectorKeyframeTrackTests;

//src/audio
import src.audio.AudioTests;
import src.audio.AudioAnalyserTests;
import src.audio.AudioContextTests;
import src.audio.AudioListenerTests;
import src.audio.PositionalAudioTests;

//src/cameras
import src.cameras.ArrayCameraTests;
import src.cameras.CameraTests;
import src.cameras.CubeCameraTests;
import src.cameras.OrthographicCameraTests;
import src.cameras.PerspectiveCameraTests;
import src.cameras.StereoCameraTests;

//src/core
import src.core.BufferAttributeTests;
import src.core.BufferGeometryTests;
import src.core.ClockTests;
import src.core.EventDispatcherTests;
import src.core.GLBufferAttributeTests;
import src.core.InstancedBufferAttributeTests;
import src.core.InstancedBufferGeometryTests;
import src.core.InstancedInterleavedBufferTests;
import src.core.InterleavedBufferTests;
import src.core.InterleavedBufferAttributeTests;
import src.core.LayersTests;
import src.core.Object3DTests;
import src.core.RaycasterTests;
import src.core.UniformTests;
import src.core.UniformsGroupTests;

//src/extras
import src.extras.DataUtilsTests;
import src.extras.EarcutTests;
import src.extras.ImageUtilsTests;
import src.extras.PMREMGeneratorTests;
import src.extras.ShapeUtilsTests;

//src/extras/core
import src.extras.core.CurveTests;
import src.extras.core.CurvePathTests;
import src.extras.core.InterpolationsTests;
import src.extras.core.PathTests;
import src.extras.core.ShapeTests;
import src.extras.core.ShapePathTests;

//src/extras/curves
import src.extras.curves.ArcCurveTests;
import src.extras.curves.CatmullRomCurve3Tests;
import src.extras.curves.CubicBezierCurveTests;
import src.extras.curves.CubicBezierCurve3Tests;
import src.extras.curves.EllipseCurveTests;
import src.extras.curves.LineCurveTests;
import src.extras.curves.LineCurve3Tests;
import src.extras.curves.QuadraticBezierCurveTests;
import src.extras.curves.QuadraticBezierCurve3Tests;
import src.extras.curves.SplineCurveTests;

//src/geometries
import src.geometries.BoxGeometryTests;
import src.geometries.CapsuleGeometryTests;
import src.geometries.CircleGeometryTests;
import src.geometries.ConeGeometryTests;
import src.geometries.CylinderGeometryTests;
import src.geometries.DodecahedronGeometryTests;
import src.geometries.EdgesGeometryTests;
import src.geometries.ExtrudeGeometryTests;
import src.geometries.IcosahedronGeometryTests;
import src.geometries.LatheGeometryTests;
import src.geometries.OctahedronGeometryTests;
import src.geometries.PlaneGeometryTests;
import src.geometries.PolyhedronGeometryTests;
import src.geometries.RingGeometryTests;
import src.geometries.ShapeGeometryTests;
import src.geometries.SphereGeometryTests;
import src.geometries.TetrahedronGeometryTests;
import src.geometries.TorusGeometryTests;
import src.geometries.TorusKnotGeometryTests;
import src.geometries.TubeGeometryTests;
import src.geometries.WireframeGeometryTests;

//src/helpers
import src.helpers.ArrowHelperTests;
import src.helpers.AxesHelperTests;
import src.helpers.Box3HelperTests;
import src.helpers.BoxHelperTests;
import src.helpers.CameraHelperTests;
import src.helpers.DirectionalLightHelperTests;
import src.helpers.GridHelperTests;
import src.helpers.HemisphereLightHelperTests;
import src.helpers.PlaneHelperTests;
import src.helpers.PointLightHelperTests;
import src.helpers.PolarGridHelperTests;
import src.helpers.SkeletonHelperTests;
import src.helpers.SpotLightHelperTests;

//src/lights
import src.lights.AmbientLightTests;
import src.lights.DirectionalLightTests;
import src.lights.DirectionalLightShadowTests;
import src.lights.HemisphereLightTests;
import src.lights.LightTests;
import src.lights.LightProbeTests;
import src.lights.LightShadowTests;
import src.lights.PointLightTests;
import src.lights.PointLightShadowTests;
import src.lights.RectAreaLightTests;
import src.lights.SpotLightTests;
import src.lights.SpotLightShadowTests;

//src/loaders
import src.loaders.AnimationLoaderTests;
import src.loaders.AudioLoaderTests;
import src.loaders.BufferGeometryLoaderTests;
import src.loaders.CacheTests;
import src.loaders.CompressedTextureLoaderTests;
import src.loaders.CubeTextureLoaderTests;
import src.loaders.DataTextureLoaderTests;
import src.loaders.FileLoaderTests;
import src.loaders.ImageBitmapLoaderTests;
import src.loaders.ImageLoaderTests;
import src.loaders.LoaderTests;
import src.loaders.LoaderUtilsTests;
import src.loaders.LoadingManagerTests;
import src.loaders.MaterialLoaderTests;
import src.loaders.ObjectLoaderTests;
import src.loaders.TextureLoaderTests;

//src/materials
import src.materials.LineBasicMaterialTests;
import src.materials.LineDashedMaterialTests;
import src.materials.MaterialTests;
import src.materials.MeshBasicMaterialTests;
import src.materials.MeshDepthMaterialTests;
import src.materials.MeshDistanceMaterialTests;
import src.materials.MeshLambertMaterialTests;
import src.materials.MeshMatcapMaterialTests;
import src.materials.MeshNormalMaterialTests;
import src.materials.MeshPhongMaterialTests;
import src.materials.MeshPhysicalMaterialTests;
import src.materials.MeshStandardMaterialTests;
import src.materials.MeshToonMaterialTests;
import src.materials.PointsMaterialTests;
import src.materials.RawShaderMaterialTests;
import src.materials.ShaderMaterialTests;
import src.materials.ShadowMaterialTests;
import src.materials.SpriteMaterialTests;

//src/math
import src.math.Box2Tests;
import src.math.Box3Tests;
import src.math.ColorTests;
import src.math.ColorManagementTests;
import src.math.CylindricalTests;
import src.math.EulerTests;
import src.math.FrustumTests;
import src.math.InterpolantTests;
import src.math.Line3Tests;
import src.math.MathUtilsTests;
import src.math.Matrix3Tests;
import src.math.Matrix4Tests;
import src.math.PlaneTests;
import src.math.QuaternionTests;
import src.math.RayTests;
import src.math.SphereTests;
import src.math.SphericalTests;
import src.math.SphericalHarmonics3Tests;
import src.math.TriangleTests;
import src.math.Vector2Tests;
import src.math.Vector3Tests;
import src.math.Vector4Tests;

//src/math/interpolants
import src.math.interpolants.CubicInterpolantTests;
import src.math.interpolants.DiscreteInterpolantTests;
import src.math.interpolants.LinearInterpolantTests;
import src.math.interpolants.QuaternionLinearInterpolantTests;

//src/objects
import src.objects.BoneTests;
import src.objects.GroupTests;
import src.objects.InstancedMeshTests;
import src.objects.LineTests;
import src.objects.LineLoopTests;
import src.objects.LineSegmentsTests;
import src.objects.LODTests;
import src.objects.MeshTests;
import src.objects.PointsTests;
import src.objects.SkeletonTests;
import src.objects.SkinnedMeshTests;
import src.objects.SpriteTests;

//src/renderers
import src.renderers.WebGL3DRenderTargetTests;
import src.renderers.WebGLArrayRenderTargetTests;
import src.renderers.WebGLCubeRenderTargetTests;
import src.renderers.WebGLRendererTests;
import src.renderers.WebGLRenderTargetTests;

//src/renderers/shaders
import src.renderers.shaders.ShaderChunkTests;
import src.renderers.shaders.ShaderLibTests;
import src.renderers.shaders.UniformsLibTests;
import src.renderers.shaders.UniformsUtilsTests;

//src/renderers/webgl
import src.renderers.webgl.WebGLAttributesTests;
import src.renderers.webgl.WebGLBackgroundTests;
import src.renderers.webgl.WebGLBufferRendererTests;
import src.renderers.webgl.WebGLCapabilitiesTests;
import src.renderers.webgl.WebGLClippingTests;
import src.renderers.webgl.WebGLExtensionsTests;
import src.renderers.webgl.WebGLGeometriesTests;
import src.renderers.webgl.WebGLIndexedBufferRendererTests;
import src.renderers.webgl.WebGLLightsTests;
import src.renderers.webgl.WebGLMorphtargetsTests;
import src.renderers.webgl.WebGLObjectsTests;
import src.renderers.webgl.WebGLProgramTests;
import src.renderers.webgl.WebGLProgramsTests;
import src.renderers.webgl.WebGLPropertiesTests;
import src.renderers.webgl.WebGLRenderListsTests;
import src.renderers.webgl.WebGLShaderTests;
import src.renderers.webgl.WebGLShadowMapTests;
import src.renderers.webgl.WebGLStateTests;
import src.renderers.webgl.WebGLTexturesTests;
import src.renderers.webgl.WebGLUniformsTests;
import src.renderers.webgl.WebGLUtilsTests;

//src/scenes
import src.scenes.FogTests;
import src.scenes.FogExp2Tests;
import src.scenes.SceneTests;

//src/textures
import src.textures.CanvasTextureTests;
import src.textures.CompressedArrayTextureTests;
import src.textures.CompressedTextureTests;
import src.textures.CubeTextureTests;
import src.textures.Data3DTextureTests;
import src.textures.DataArrayTextureTests;
import src.textures.DataTextureTests;
import src.textures.DepthTextureTests;
import src.textures.FramebufferTextureTests;
import src.textures.SourceTests;
import src.textures.TextureTests;
import src.textures.VideoTextureTests;