import NodeMaterial from '../../../nodes/materials/NodeMaterial.hx';
import PMREMUtils from '../../../nodes/pmrem/PMREMUtils.hx';
import EquirectUVNode from '../../../nodes/utils/EquirectUVNode.hx';
import UniformNode from '../../../nodes/core/UniformNode.hx';
import UniformsNode from '../../../nodes/accessors/UniformsNode.hx';
import TextureNode from '../../../nodes/accessors/TextureNode.hx';
import CubeTextureNode from '../../../nodes/accessors/CubeTextureNode.hx';
import Float32Array from 'haxe/format/Json.hx';
import Vector3 from 'openfl/geom/Vector3.hx';
import AttributeNode from '../../../nodes/core/AttributeNode.hx';
import OrthographicCamera from 'three/src/cameras/OrthographicCamera.hx';
import PerspectiveCamera from 'three/src/cameras/PerspectiveCamera.hx';
import Color from 'three/src/math/Color.hx';
import BufferGeometry from 'three/src/core/BufferGeometry.hx';
import BufferAttribute from 'three/src/core/BufferAttribute.hx';
import RenderTarget from 'three/src/renderers/WebGLRenderTarget.hx';
import Mesh from 'three/src/objects/Mesh.hx';
import CubeReflectionMapping from 'three/src/textures/CubeReflectionMapping.hx';
import CubeRefractionMapping from 'three/src/textures/CubeRefractionMapping.hx';
import CubeUVReflectionMapping from 'three/src/textures/CubeUVReflectionMapping.hx';
import LinearFilter from 'three/src/constants/Textures.hx';
import NoBlending from 'three/src/constants/BlendFactors.hx';
import RGBAFormat from 'three/src/constants/Textures.hx';
import HalfFloatType from 'three/src/constants/Textures.hx';
import BackSide from 'three/src/constants/Shading.hx';
import LinearSRGBColorSpace from 'three/src/math/ColorSpace.hx';
import UVNode from '../../../nodes/accessors/UVNode.hx';

class PMREMGenerator {

	private _renderer:Dynamic;
	private _pingPongRenderTarget:RenderTarget;
	private _lodMax:Int;
	private _cubeSize:Int;
	private _lodPlanes:Array<BufferGeometry>;
	private _sizeLods:Array<Int>;
	private _sigmas:Array<Float>;
	private _lodMeshes:Array<Mesh>;
	private _blurMaterial:NodeMaterial;
	private _cubemapMaterial:NodeMaterial;
	private _equirectMaterial:NodeMaterial;
	private _backgroundBox:Mesh;

	public constructor(renderer:Dynamic) {
		this._renderer = renderer;
		this._lodMax = 0;
		this._cubeSize = 0;
		this._lodPlanes = [];
		this._sizeLods = [];
		this._sigmas = [];
		this._lodMeshes = [];
		this._blurMaterial = null;
		this._cubemapMaterial = null;
		this._equirectMaterial = null;
		this._backgroundBox = null;
	}

	public fromScene(scene:Dynamic, sigma:Float = 0, near:Float = 0.1, far:Float = 100):RenderTarget {
		// Implement the fromScene method
	}

	public fromEquirectangular(equirectangular:Dynamic, renderTarget:RenderTarget = null):RenderTarget {
		// Implement the fromEquirectangular method
	}

	public fromCubemap(cubemap:Dynamic, renderTarget:RenderTarget = null):RenderTarget {
		// Implement the fromCubemap method
	}

	public compileCubemapShader():Void {
		// Implement the compileCubemapShader method
	}

	public compileEquirectangularShader():Void {
		// Implement the compileEquirectangularShader method
	}

	public dispose():Void {
		// Implement the dispose method
	}

	// Implement the private methods

}