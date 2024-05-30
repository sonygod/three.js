import js.NodeMaterial;
import { getDirection, blur } from js.nodes.pmrem.PMREMUtils;
import { equirectUV } from js.nodes.utils.EquirectUVNode;
import { uniform } from js.nodes.core.UniformNode;
import { uniforms } from js.nodes.accessors.UniformsNode;
import { texture } from js.nodes.accessors.TextureNode;
import { cubeTexture } from js.nodes.accessors.CubeTextureNode;
import { float, vec3 } from js.nodes.shadernode.ShaderNode;
import { uv } from js.nodes.accessors.UVNode;
import { attribute } from js.nodes.core.AttributeNode;
import { OrthographicCamera, Color, Vector3, BufferGeometry, BufferAttribute, RenderTarget, Mesh, CubeReflectionMapping, CubeRefractionMapping, CubeUVReflectionMapping, LinearFilter, NoBlending, RGBAFormat, HalfFloatType, BackSide, LinearSRGBColorSpace, PerspectiveCamera, MeshBasicMaterial, BoxGeometry } from js.three;

static var LOD_MIN = 4;

// The standard deviations (radians) associated with the extra mips. These are
// chosen to approximate a Trowbridge-Reitz distribution function times the
// geometric shadowing function. These sigma values squared must match the
// variance #defines in cube_uv_reflection_fragment.glsl.js.
static var EXTRA_LOD_SIGMA = [ 0.125, 0.215, 0.35, 0.446, 0.526, 0.582 ];

// The maximum length of the blur for loop. Smaller sigmas will use fewer
// samples and exit early, but not recompile the shader.
static var MAX_SAMPLES = 20;

static var _flatCamera = new OrthographicCamera(-1, 1, 1, -1, 0, 1);
static var _cubeCamera = new PerspectiveCamera(90, 1);
static var _clearColor = new Color();
static var _oldTarget = null;
static var _oldActiveCubeFace = 0;
static var _oldActiveMipmapLevel = 0;

// Golden Ratio
static var PHI = (1 + Math.sqrt(5)) / 2;
static var INV_PHI = 1 / PHI;

// Vertices of a dodecahedron (except the opposites, which represent the
// same axis), used as axis directions evenly spread on a sphere.
static var _axisDirections = [
	new Vector3(-PHI, INV_PHI, 0),
	new Vector3(PHI, INV_PHI, 0),
	new Vector3(-INV_PHI, 0, PHI),
	new Vector3(INV_PHI, 0, PHI),
	new Vector3(0, PHI, -INV_PHI),
	new Vector3(0, PHI, INV_PHI),
	new Vector3(-1, 1, -1),
	new Vector3(1, 1, -1),
	new Vector3(-1, 1, 1),
	new Vector3(1, 1, 1)
];

//

// WebGPU Face indices
static var _faceLib = [
	3, 1, 5,
	0, 4, 2
];

var direction = getDirection(uv(), attribute('faceIndex')).normalize();
var outputDirection = vec3(direction.x, direction.y.negate(), direction.z);

/**
 * This class generates a Prefiltered, Mipmapped Radiance Environment Map
 * (PMREM) from a cubeMap environment texture. This allows different levels of
 * blur to be quickly accessed based on material roughness. It is packed into a
 * special CubeUV format that allows us to perform custom interpolation so that
 * we can support nonlinear formats such as RGBE. Unlike a traditional mipmap
 * chain, it only goes down to the LOD_MIN level (above), and then creates extra
 * even more filtered 'mips' at the same LOD_MIN resolution, associated with
 * higher roughness levels. In this way we maintain resolution to smoothly
 * interpolate diffuse lighting while limiting sampling computation.
 *
 * Paper: Fast, Accurate Image-Based Lighting
 * https://drive.google.com/file/d/15y8r_UpKlU9SvV4ILb0C3qCPecS8pvLz/view
*/

class PMREMGenerator {

	constructor(renderer) {

		this->_renderer = renderer;
		this->_pingPongRenderTarget = null;

		this->_lodMax = 0;
		this->_cubeSize = 0;
		this->_lodPlanes = [];
		this->_sizeLods = [];
		this->_sigmas = [];
		this->_lodMeshes = [];

		this->_blurMaterial = null;
		this->_cubemapMaterial = null;
		this->_equirectMaterial = null;
		this->_backgroundBox = null;

	}

	/**
	 * Generates a PMREM from a supplied Scene, which can be faster than using an
	 * image if networking bandwidth is low. Optional sigma specifies a blur radius
	 * in radians to be applied to the scene before PMREM generation. Optional near
	 * and far planes ensure the scene is rendered in its entirety (the cubeCamera
	 * is placed at the origin).
	 */
	public function fromScene(scene:Dynamic, sigma:Float = 0.0, near:Float = 0.1, far:Float = 100):RenderTarget {

		_oldTarget = this->_renderer.getRenderTarget();
		_oldActiveCubeFace = this->_renderer.getActiveCubeFace();
		_oldActiveMipmapLevel = this->_renderer.getActiveMipmapLevel();

		this->_setSize(256);

		var cubeUVRenderTarget = this->_allocateTargets();
		cubeUVRenderTarget.depthBuffer = true;

		this->_sceneToCubeUV(scene, near, far, cubeUVRenderTarget);

		if (sigma > 0) {

			this->_blur(cubeUVRenderTarget, 0, 0, sigma);

		}

		this->_applyPMREM(cubeUVRenderTarget);

		this->_cleanup(cubeUVRenderTarget);

		return cubeUVRenderTarget;

	}

	/**
	 * Generates a PMREM from an equirectangular texture, which can be either LDR
	 * or HDR. The ideal input image size is 1k (1024 x 512),
	 * as this matches best with the 256 x 256 cubemap output.
	 */
	public function fromEquirectangular(equirectangular:Dynamic, ?renderTarget:RenderTarget):RenderTarget {

		return this->_fromTexture(equirectangular, renderTarget);

	}

	/**
	 * Generates a PMREM from an cubemap texture, which can be either LDR
	 * or HDR. The ideal input cube size is 256 x 256,
	 * as this matches best with the 256 x 256 cubemap output.
	 */
	public function fromCubemap(cubemap:Dynamic, ?renderTarget:RenderTarget):RenderTarget {

		return this->_fromTexture(cubemap, renderTarget);

	}

	/**
	 * Pre-compiles the cubemap shader. You can get faster start-up by invoking this method during
	 * your texture's network fetch for increased concurrency.
	 */
	public function compileCubemapShader():Void {

		if (this->_cubemapMaterial == null) {

			this->_cubemapMaterial = _getCubemapMaterial();
			this->_compileMaterial(this->_cubemapMaterial);

		}

	}

	/**
	 * Pre-compiles the equirectangular shader. You can get faster start-up by invoking this method during
	 * your texture's network fetch for increased concurrency.
	 */
	public function compileEquirectangularShader():Void {

		if (this->_equirectMaterial == null) {

			this->_equirectMaterial = _getEquirectMaterial();
			this->_compileMaterial(this->_equirectMaterial);

		}

	}

	/**
	 * Disposes of the PMREMGenerator's internal memory. Note that PMREMGenerator is a static class,
	 * so you should not need more than one PMREMGenerator object. If you do, calling dispose() on
	 * one of them will cause any others to also become unusable.
	 */
	public function dispose():Void {

		this->_dispose();

		if (this->_cubemapMaterial != null) this->_cubemapMaterial.dispose();
		if (this->_equirectMaterial != null) this->_equirectMaterial.dispose();
		if (this->_backgroundBox != null) {

			this->_backgroundBox.geometry.dispose();
			this->_backgroundBox.material.dispose();

		}

	}

	// private interface

	private function _setSize(cubeSize:Int) {

		this->_lodMax = Std.int(Math.log2(cubeSize));
		this->_cubeSize = Std.int(Math.pow(2, this->_lodMax));

	}

	private function _dispose():Void {

		if (this->_blurMaterial != null) this->_blurMaterial.dispose();

		if (this->_pingPongRenderTarget != null) this->_pingPongRenderTarget.dispose();

		for (i in 0...this->_lodPlanes.length) {

			this->_lodPlanes[i].dispose();

		}

	}

	private function _cleanup(outputTarget:RenderTarget) {

		this->_renderer.setRenderTarget(_oldTarget, _oldActiveCubeFace, _oldActiveMipmapLevel);
		outputTarget.scissorTest = false;
		_setViewport(outputTarget, 0, 0, outputTarget.width, outputTarget.height);

	}

	private function _fromTexture(texture:Dynamic, ?renderTarget:RenderTarget):RenderTarget {

		if (texture.mapping == CubeReflectionMapping || texture.mapping == CubeRefractionMapping) {

			this->_setSize(texture.image.length == 0 ? 16 : (texture.image[0].width or texture.image[0].image.width));

		} else { // Equirectangular

			this->_setSize(texture.image.width / 4);

		}

		_oldTarget = this->_renderer.getRenderTarget();
		_oldActiveCubeFace = this->_renderer.getActiveCubeFace();
		_oldActiveMipmapLevel = this->_renderer.getActiveMipmapLevel();

		var cubeUVRenderTarget = renderTarget or this->_allocateTargets();
		this->_textureToCubeUV(texture, cubeUVRenderTarget);
		this->_applyPMREM(cubeUVRenderTarget);
		this->_cleanup(cubeUVRenderTarget);

		return cubeUVRenderTarget;

	}

	private function _allocateTargets():RenderTarget {

		var width = 3 * Math.max(this->_cubeSize, 16 * 7);
		var height = 4 * this->_cubeSize;

		var params = {
			magFilter: LinearFilter,
			minFilter: LinearFilter,
			generateMipmaps: false,
			type: HalfFloatType,
			format: RGBAFormat,
			colorSpace: LinearSRGBColorSpace,
			//depthBuffer: false
		};

		var cubeUVRenderTarget = _createRenderTarget(width, height, params);

		if (this->_pingPongRenderTarget == null || this->_pingPongRenderTarget.width != width || this->_pingPongRenderTarget.height != height) {

			if (this->_pingPongRenderTarget != null) {

				this->_dispose();

			}

			this->_pingPongRenderTarget = _createRenderTarget(width, height, params);

			var { _lodMax } = this;
			({ sizeLods: this->_sizeLods, lodPlanes: this->_lodPlanes, sigmas: this->_sigmas, lodMeshes: this->_lodMeshes } = _createPlanes(_lodMax));

			this->_blurMaterial = _getBlurShader(_lodMax, width, height);

		}

		return cubeUVRenderTarget;

	}

	private function _compileMaterial(material:Dynamic):Void {

		var tmpMesh = this->_lodMeshes[0];
		tmpMesh.material = material;

		this->_renderer.compile(tmpMesh, _flatCamera);

	}

	private function _sceneToCubeUV(scene:Dynamic, near:Float, far:Float, cubeUVRenderTarget:RenderTarget) {

		var cubeCamera = _cubeCamera;
		cubeCamera.near = near;
		cubeCamera.far = far;

		// px, py, pz, nx, ny, nz
		var upSign = [ - 1, 1, - 1, - 1, - 1, - 1 ];
		var forwardSign = [ 1, 1, 1, - 1, - 1, - 1 ];

		var renderer = this->_renderer;

		var originalAutoClear = renderer.autoClear;

		renderer.getClearColor(_clearColor);

		renderer.autoClear = false;

		var backgroundBox = this->_backgroundBox;

		if (backgroundBox == null) {

			var backgroundMaterial = new MeshBasicMaterial({
				name: 'PMREM.Background',
				side: BackSide,
				depthWrite: false,
				depthTest: false
			});

			backgroundBox = new Mesh(new BoxGeometry(), backgroundMaterial);

		}

		var useSolidColor = false;
		var background = scene.background;

		if (background != null) {

			if (background.isColor) {

				backgroundBox.material.color.copy(background);
				scene.background = null;
				useSolidColor = true;

			}

		} else {

			backgroundBox.material.color.copy(_clearColor);
			useSolidColor = true;

		}

		renderer.setRenderTarget(cubeUVRenderTarget);

		renderer.clear();

		if (useSolidColor) {

			renderer.render(backgroundBox, cubeCamera);

		}

		for (i in 0...6) {

			var col = i % 3;

			if (col == 0) {

				cubeCamera.up.set(0, upSign[i], 0);
				cubeCamera.lookAt(forwardSign[i], 0, 0);

			} else if (col == 1) {

				cubeCamera.up.set(0, 0, upSign[i]);
				cubeCamera.lookAt(0, forwardSign[i], 0);

			} else {

				cubeCamera.up.set(0, upSign[i], 0);
				cubeCamera.lookAt(0, 0, forwardSign[i]);

			}

			var size = this->_cubeSize;

			_setViewport(cubeUVRenderTarget, col * size, i > 2 ? size : 0, size, size);

			renderer.render(scene, cubeCamera);

		}

		renderer.autoClear = originalAutoClear;
		scene.background = background;

	}

	private function _textureToCubeUV(texture:Dynamic, cubeUVRenderTarget:RenderTarget) {

		var renderer = this->_renderer;

		var isCubeTexture = (texture.mapping == CubeReflectionMapping || texture.mapping == CubeRefractionMapping);

		if (isCubeTexture) {

			if (this->_cubemapMaterial == null) {

				this->_cubemapMaterial = _getCubemapMaterial(texture);

			}

		} else {

			if (this->_equirectMaterial == null) {

				this->_equirectMaterial = _getEquirectMaterial(texture);

			}

		}

		var material = isCubeTexture ? this->_cubemapMaterial : this->_equirectMaterial;
		material.fragmentNode.value = texture;

		var mesh = this->_lodMeshes[0];
		mesh.material = material;

		var size = this->_cubeSize;

		_setViewport(cubeUVRenderTarget, 0, 0, 3 * size, 2 * size);

		renderer.setRenderTarget(cubeUVRenderTarget);
		renderer.render(mesh, _flatCamera);

	}

	private function _applyPMREM(cubeUVRenderTarget:RenderTarget) {

		var renderer = this->_renderer;
		var autoClear = renderer.autoClear;
		renderer.autoClear = false;
		var n = this->_lodPlanes.length;

		for (i in 1...n) {

			var sigma = Math.sqrt(this->_sigmas[i] * this->_sigmas[i] - this->_sigmas[i - 1] * this->_sigmas[i - 1]);

			var poleAxis = _axisDirections[(n - i - 1) % _axisDirections.length];

			this->_blur(cubeUVRenderTarget, i - 1, i, sigma, poleAxis);

		}

		renderer.autoClear = autoClear;

	}

	/**
	 * This is a two-pass Gaussian blur for a cubemap. Normally this is done
	 * vertically and horizontally, but this breaks down on a cube. Here we apply
	 * the blur latitudinally (around the poles), and then longitudinally (towards
	 * the poles) to approximate the orthogonally-separable blur. It is least
	 * accurate at the poles, but still does a decent job.
	 */
	private function _blur(cubeUVRenderTarget:RenderTarget, lodIn:Int, lodOut:Int, sigma:Float, ?poleAxis:Vector3) {

		var pingPongRenderTarget = this->_pingPongRenderTarget;

		this->_halfBlur(
cubeUVRenderTarget,
pingPongRenderTarget,
lodIn,
lodOut,
sigma,
'latitudinal',
poleAxis);

this->_halfBlur(
pingPongRenderTarget,
cubeUVRenderTarget,
lodOut,
lodOut,
sigma,
'longitudinal',
poleAxis);

}

private function _halfBlur(targetIn:RenderTarget, targetOut:RenderTarget, lodIn:Int, lodOut:Int, sigmaRadians:Float, direction:String, ?poleAxis:Vector3) {

var renderer = this->_renderer;
var blurMaterial = this->_blurMaterial;

if (direction != 'latitudinal' && direction != 'longitudinal') {

trace('blur direction must be either latitudinal or longitudinal!');

}

// Number of standard deviations at which to cut off the discrete approximation.
var STANDARD_DEVIATIONS = 3;

var blurMesh = this->_lodMeshes[lodOut];
blurMesh.material = blurMaterial;

var blurUniforms = blurMaterial.uniforms;

var pixels = this->_sizeLods[lodIn] - 1;
var radiansPerPixel = if (sigmaRadians != null) Math.PI / (2 * pixels) else 2 * Math.PI / (2 * MAX_SAMPLES - 1);
var sigmaPixels = sigmaRadians / radiansPerPixel;
var samples = if (sigmaRadians != null) 1 + Std.int(STANDARD_DEVIATIONS * sigmaPixels) else MAX_SAMPLES;

if (samples > MAX_SAMPLES) {

trace(`sigmaRadians, ${
sigmaRadians}, is too large and will clip, as it requested ${
samples} samples when the maximum is set to ${MAX_SAMPLES}`);

}

var weights = [];
var sum:Float = 0;

for (i in 0...MAX_SAMPLES) {

var x = i / sigmaPixels;
var weight = Math.exp(- x * x / 2);
weights.push(weight);

if (i == 0) {

sum += weight;

} else if (i < samples) {

sum += 2 * weight;

}

}

for (i in 0...weights.length) {

weights[i] = weights[i] / sum;

}

targetIn.texture.frame = (targetIn.texture.frame or 0) + 1;

blurUniforms.envMap.value = targetIn.texture;
blurUniforms.samples.value = samples;
blurUniforms.weights.array = weights;
blurUniforms.latitudinal.value = if (direction == 'latitudinal') 1 else 0;

if (poleAxis != null) {

blurUniforms.poleAxis.value = poleAxis;

}

var { _lodMax } = this;
blurUniforms.dTheta.value = radiansPerPixel;
blurUniforms.mipInt.value = _lodMax - lodIn;

var outputSize = this->_sizeLods[lodOut];
var x = 3 * outputSize * (lodOut > _lodMax - LOD_MIN ? lodOut - _lodMax + LOD_MIN : 0);
var y = 4 * (this->_cubeSize - outputSize);

_setViewport(targetOut, x, y, 3 * outputSize, 2 * outputSize);
renderer.setRenderTarget(targetOut);
renderer.render(blurMesh, _flatCamera);

}

}

function _createPlanes(lodMax:Int) {

var lodPlanes = [];
var sizeLods = [];
var sigmas = [];
var lodMeshes = [];

var lod = lodMax;

var totalLods = lodMax - LOD_MIN + 1 + EXTRA_LOD_SIGMA.length;

for (i in 0...totalLods) {

var sizeLod = Std.int(Math.pow(2, lod));
sizeLods.push(sizeLod);
var sigma = 1.0 / sizeLod;

if (i > lodMax - LOD_MIN) {

sigma = EXTRA_LOD_SIGMA[i - lodMax + LOD_MIN - 1];

} else if (i == 0) {

sigma = 0;

}

sigmas.push(sigma);

var texelSize = 1.0 / (sizeLod - 2);
var min = - texelSize;
var max = 1 + texelSize;
var uv1 = [ min, min, max, min, max, max, min, min, max, max, min, max ];

var cubeFaces = 6;
var vertices = 6;
var positionSize = 3;
var uvSize = 2;
var faceIndexSize = 1;

var position = new Float32Array(positionSize * vertices * cubeFaces);
var uv = new Float32Array(uvSize * vertices * cubeFaces);
var faceIndex = new Float32Array(faceIndexSize * vertices * cubeFaces);

for (var face in 0...cubeFaces) {

var x = (face % 3) * 2 / 3 - 1;
var y = if (face > 2) 0 else - 1;
var coordinates = [
x, y, 0,
x + 2 / 3, y, 0,
x + 2 / 3, y + 1, 0,
x, y, 0,
x + 2 / 3, y + 1, 0,
x, y + 1, 0
];

var faceIdx = _faceLib[face];
position.set(coordinates, positionSize * vertices * faceIdx);
uv.set(uv1, uvSize * vertices * faceIdx);
var fill = [ faceIdx, faceIdx, faceIdx, faceIdx, faceIdx, faceIdx ];
faceIndex.set(fill, faceIndexSize * vertices * faceIdx);

}

var planes = new BufferGeometry();
planes.setAttribute('position', new BufferAttribute(position, positionSize));
planes.setAttribute('uv', new BufferAttribute(uv, uvSize));
planes.setAttribute('faceIndex', new BufferAttribute(faceIndex, faceIndexSize));
lodPlanes.push(planes);
lodMeshes.push(new Mesh(planes, null));

if (lod > LOD_MIN) {

lod--;

}

}

return { lodPlanes, sizeLods, sigmas, lodMeshes };

}

function _createRenderTarget(width:Int, height:Int, params:Dynamic) {

var cubeUVRenderTarget = new RenderTarget(width, height, params);
cubeUVRenderTarget.texture.mapping = CubeUVReflectionMapping;
cubeUVRenderTarget.texture.name = 'PMREM.cubeUv';
cubeUVRenderTarget.texture.isPMREMTexture = true;
cubeUVRenderTarget.scissorTest = true;
return cubeUVRenderTarget;

}

function _setViewport(target:RenderTarget, x:Int, y:Int, width:Int, height:Int) {

var viewY = target.height - height - y;

target.viewport.set(x, viewY, width, height);
target.scissor.set(x, viewY, width, height);

}

function _getMaterial():Dynamic {

var material = new NodeMaterial();
material.depthTest = false;
material.depthWrite = false;
material.blending = NoBlending;

return material;

}

function _getBlurShader(lodMax:Int, width:Int, height:Int) {

var weights = uniforms(new Array(MAX_SAMPLES).fill(0));
var poleAxis = uniform(new Vector3(0, 1, 0));
var dTheta = uniform(0);
var n = float(MAX_SAMPLES);
var latitudinal = uniform(0); // false, bool
var samples = uniform(1); // int
var envMap = texture(null);
var mipInt = uniform(0); // int
var CUBEUV_TEXEL_WIDTH = float(1 / width);
var CUBEUV_TEXEL_HEIGHT = float(1 / height);
var CUBEUV_MAX_MIP = float(lodMax);

var materialUniforms = {
n,
latitudinal,
weights,
poleAxis,
outputDirection,
dTheta,
samples,
envMap,
mipInt,
CUBEUV_TEXEL_WIDTH,
CUBEUV_TEXEL_HEIGHT,
CUBEUV_MAX_MIP
};

var material = _getMaterial();
material.uniforms = materialUniforms; // TODO: Move to outside of the material
material.fragmentNode = blur({ ...materialUniforms, latitudinal: latitudinal.equal(1) });

return material;

}

function _getCubemapMaterial(envTexture:Dynamic) {

var material = _getMaterial();
material.fragmentNode = cubeTexture(envTexture, outputDirection);

return material;

}

function _getEquirectMaterial(envTexture:Dynamic) {

var material = _getMaterial();
material.fragmentNode = texture(envTexture, equirectUV(outputDirection), 0);

return material;

}

export default PMREMGenerator;