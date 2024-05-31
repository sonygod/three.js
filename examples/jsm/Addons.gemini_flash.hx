import three.animation.AnimationClipCreator;
import three.animation.CCDIKSolver;
import three.animation.MMDAnimationHelper;
import three.animation.MMDPhysics;

import three.cameras.CinematicCamera;

import three.capabilities.WebGL;

import three.controls.ArcballControls;
import three.controls.DragControls;
import three.controls.FirstPersonControls;
import three.controls.FlyControls;
import three.controls.MapControls;
import three.controls.OrbitControls;
import three.controls.PointerLockControls;
import three.controls.TrackballControls;
import three.controls.TransformControls;

import three.csm.CSM;
import three.csm.CSMFrustum;
import three.csm.CSMHelper;
import three.csm.CSMShader;

import three.curves.CurveExtras; // Note: This is imported as a package
import three.curves.NURBSCurve;
import three.curves.NURBSSurface;
import three.curves.NURBSVolume;
import three.curves.NURBSUtils; // Note: This is imported as a package

import three.effects.AnaglyphEffect;
import three.effects.AsciiEffect;
import three.effects.OutlineEffect;
import three.effects.ParallaxBarrierEffect;
import three.effects.PeppersGhostEffect;
import three.effects.StereoEffect;

import three.environments.DebugEnvironment;
import three.environments.RoomEnvironment;

import three.exporters.DRACOExporter;
import three.exporters.EXRExporter;
import three.exporters.GLTFExporter;
import three.exporters.KTX2Exporter;
import three.exporters.MMDExporter;
import three.exporters.OBJExporter;
import three.exporters.PLYExporter;
import three.exporters.STLExporter;
import three.exporters.USDZExporter;

import three.geometries.BoxLineGeometry;
import three.geometries.ConvexGeometry;
import three.geometries.DecalGeometry;
import three.geometries.ParametricGeometries; // Note: This is imported as a package
import three.geometries.ParametricGeometry;
import three.geometries.RoundedBoxGeometry;
import three.geometries.TeapotGeometry;
import three.geometries.TextGeometry;

import three.helpers.LightProbeHelper;
import three.helpers.OctreeHelper;
import three.helpers.PositionalAudioHelper;
import three.helpers.RectAreaLightHelper;
import three.helpers.TextureHelper;
import three.helpers.VertexNormalsHelper;
import three.helpers.VertexTangentsHelper;
import three.helpers.ViewHelper;

import three.interactive.HTMLMesh;
import three.interactive.InteractiveGroup;
import three.interactive.SelectionBox;
import three.interactive.SelectionHelper;

import three.lights.IESSpotLight;
import three.lights.LightProbeGenerator;
import three.lights.RectAreaLightUniformsLib;

import three.lines.Line2;
import three.lines.LineGeometry;
import three.lines.LineMaterial;
import three.lines.LineSegments2;
import three.lines.LineSegmentsGeometry;
import three.lines.Wireframe;
import three.lines.WireframeGeometry2;

// Loaders - all starting with "three.loaders."
import three.loaders.AMFLoader;
import three.loaders.BVHLoader;
import three.loaders.ColladaLoader;
import three.loaders.DDSLoader;
import three.loaders.DRACOLoader;
import three.loaders.EXRLoader;
import three.loaders.FBXLoader;
import three.loaders.FontLoader;
import three.loaders.GCodeLoader;
import three.loaders.GLTFLoader;
import three.loaders.HDRCubeTextureLoader;
import three.loaders.IESLoader;
import three.loaders.KMZLoader;
import three.loaders.KTX2Loader;
import three.loaders.KTXLoader;
import three.loaders.LDrawLoader;
import three.loaders.LUT3dlLoader;
import three.loaders.LUTCubeLoader;
import three.loaders.LWOLoader;
import three.loaders.LogLuvLoader;
import three.loaders.LottieLoader;
import three.loaders.MD2Loader;
import three.loaders.MDDLoader;
import three.loaders.MMDLoader;
import three.loaders.MTLLoader;
import three.loaders.NRRDLoader;
import three.loaders.OBJLoader;
import three.loaders.PCDLoader;
import three.loaders.PDBLoader;
import three.loaders.PLYLoader;
import three.loaders.PVRLoader;
import three.loaders.RGBELoader;
import three.loaders.RGBMLoader;
import three.loaders.STLLoader;
import three.loaders.SVGLoader;
import three.loaders.TDSLoader;
import three.loaders.TGALoader;
import three.loaders.TIFFLoader;
import three.loaders.TTFLoader;
import three.loaders.TiltLoader;
import three.loaders.USDZLoader;
import three.loaders.VOXLoader;
import three.loaders.VRMLLoader;
import three.loaders.VTKLoader;
import three.loaders.XYZLoader;

import three.materials.MeshGouraudMaterial;

import three.math.Capsule;
import three.math.ColorConverter;
import three.math.ConvexHull;
import three.math.ImprovedNoise;
import three.math.Lut;
import three.math.MeshSurfaceSampler;
import three.math.OBB;
import three.math.Octree;
import three.math.SimplexNoise;

import three.misc.ConvexObjectBreaker;
import three.misc.GPUComputationRenderer;
import three.misc.Gyroscope;
import three.misc.MD2Character;
import three.misc.MD2CharacterComplex;
import three.misc.MorphAnimMesh;
import three.misc.MorphBlendMesh;
import three.misc.ProgressiveLightMap;
import three.misc.RollerCoaster;
import three.misc.Timer;
import three.misc.TubePainter;
import three.misc.Volume;
import three.misc.VolumeSlice;

import three.modifiers.CurveModifier;
import three.modifiers.EdgeSplitModifier;
import three.modifiers.SimplifyModifier;
import three.modifiers.TessellateModifier;

import three.objects.GroundedSkybox;
import three.objects.Lensflare;
import three.objects.MarchingCubes;
import three.objects.Reflector;
import three.objects.ReflectorForSSRPass;
import three.objects.Refractor;
import three.objects.ShadowMesh;
import three.objects.Sky;
import three.objects.Water;
import three.objects.Water2;

import three.physics.AmmoPhysics;
import three.physics.RapierPhysics;

// Post-processing - all starting with "three.postprocessing."
import three.postprocessing.AfterimagePass;
import three.postprocessing.BloomPass;
import three.postprocessing.BokehPass;
import three.postprocessing.ClearPass;
import three.postprocessing.CubeTexturePass;
import three.postprocessing.DotScreenPass;
import three.postprocessing.EffectComposer;
import three.postprocessing.FilmPass;
import three.postprocessing.GlitchPass;
import three.postprocessing.GTAOPass;
import three.postprocessing.HalftonePass;
import three.postprocessing.LUTPass;
import three.postprocessing.MaskPass;
import three.postprocessing.OutlinePass;
import three.postprocessing.OutputPass;
import three.postprocessing.Pass;
import three.postprocessing.RenderPass;
import three.postprocessing.RenderPixelatedPass;
import three.postprocessing.SAOPass;
import three.postprocessing.SMAAPass;
import three.postprocessing.SSAARenderPass;
import three.postprocessing.SSAOPass;
import three.postprocessing.SSRPass;
import three.postprocessing.SavePass;
import three.postprocessing.ShaderPass;
import three.postprocessing.TAARenderPass;
import three.postprocessing.TexturePass;
import three.postprocessing.UnrealBloomPass;

import three.renderers.CSS2DRenderer;
import three.renderers.CSS3DRenderer;
import three.renderers.Projector;
import three.renderers.SVGRenderer;

// Shaders - all starting with "three.shaders."
import three.shaders.ACESFilmicToneMappingShader;
import three.shaders.AfterimageShader;
import three.shaders.BasicShader;
import three.shaders.BleachBypassShader;
import three.shaders.BlendShader;
import three.shaders.BokehShader;
import three.shaders.BokehShader2;
import three.shaders.BrightnessContrastShader;
import three.shaders.ColorCorrectionShader;
import three.shaders.ColorifyShader;
import three.shaders.ConvolutionShader;
import three.shaders.CopyShader;
import three.shaders.DOFMipMapShader;
import three.shaders.DepthLimitedBlurShader;
import three.shaders.DigitalGlitch;
import three.shaders.DotScreenShader;
import three.shaders.ExposureShader;
import three.shaders.FXAAShader;
import three.shaders.FilmShader;
import three.shaders.FocusShader;
import three.shaders.FreiChenShader;
import three.shaders.GammaCorrectionShader;
import three.shaders.GodRaysShader;
import three.shaders.GTAOShader;
import three.shaders.HalftoneShader;
import three.shaders.HorizontalBlurShader;
import three.shaders.HorizontalTiltShiftShader;
import three.shaders.HueSaturationShader;
import three.shaders.KaleidoShader;
import three.shaders.LuminosityHighPassShader;
import three.shaders.LuminosityShader;
import three.shaders.MMDToonShader;
import three.shaders.MirrorShader;
import three.shaders.NormalMapShader;
import three.shaders.OutputShader;
import three.shaders.RGBShiftShader;
import three.shaders.SAOShader;
import three.shaders.SMAAShader;
import three.shaders.SSAOShader;
import three.shaders.SSRShader;
import three.shaders.SepiaShader;
import three.shaders.SobelOperatorShader;
import three.shaders.SubsurfaceScatteringShader;
import three.shaders.TechnicolorShader;
import three.shaders.ToonShader;
import three.shaders.TriangleBlurShader;
import three.shaders.UnpackDepthRGBAShader;
import three.shaders.VelocityShader;
import three.shaders.VerticalBlurShader;
import three.shaders.VerticalTiltShiftShader;
import three.shaders.VignetteShader;
import three.shaders.VolumeShader;
import three.shaders.WaterRefractionShader;

import three.textures.FlakesTexture;

import three.utils.BufferGeometryUtils; // Note: This is imported as a package
import three.utils.CameraUtils; // Note: This is imported as a package
import three.utils.GPUStatsPanel;
import three.utils.GeometryCompressionUtils; // Note: This is imported as a package
import three.utils.GeometryUtils; // Note: This is imported as a package
import three.utils.LDrawUtils;
import three.utils.PackedPhongMaterial;
import three.utils.SceneUtils; // Note: This is imported as a package
import three.utils.ShadowMapViewer;
import three.utils.SkeletonUtils; // Note: This is imported as a package
import three.utils.SortUtils; // Note: This is imported as a package
import three.utils.TextureUtils;
import three.utils.UVsDebug;
import three.utils.WorkerPool;

// WebXR - all starting with "three.webxr."
import three.webxr.ARButton;
import three.webxr.OculusHandModel;
import three.webxr.OculusHandPointerModel;
import three.webxr.Text2D;
import three.webxr.VRButton;
import three.webxr.XRButton;
import three.webxr.XRControllerModelFactory;
import three.webxr.XREstimatedLight;
import three.webxr.XRHandMeshModel;
import three.webxr.XRHandModelFactory;
import three.webxr.XRHandPrimitiveModel;
import three.webxr.XRPlanes;