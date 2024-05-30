import NodeMaterial from '../../../nodes/materials/NodeMaterial.hx';
import { getDirection, blur } from '../../../nodes/pmrem/PMREMUtils.hx';
import { equirectUV } from '../../../nodes/utils/EquirectUVNode.hx';
import { uniform } from '../../../nodes/core/UniformNode.hx';
import { uniforms } from '../../../nodes/accessors/UniformsNode.hx';
import { texture } from '../../../nodes/accessors/TextureNode.hx';
import { cubeTexture } from '../../../nodes/accessors/CubeTextureNode.hx';
import { float, vec3 } from '../../../nodes/shadernode/ShaderNode.hx';
import { uv } from '../../../nodes/accessors/UVNode.hx';
import { attribute } from '../../../nodes/core/AttributeNode.hx';
import {
	OrthographicCamera,
	Color,
	Vector3,
	BufferGeometry,
	BufferAttribute,
	RenderTarget,
	Mesh,
	CubeReflectionMapping,
	CubeRefractionMapping,
	CubeUVReflectionMapping,
	LinearFilter,
	NoBlending,
	RGBAFormat,
	HalfFloatType,
	BackSide,
	LinearSRGBColorSpace,
	PerspectiveCamera,
	MeshBasicMaterial,
	BoxGeometry
} from 'three';

class PMREMGenerator {

	constructor( renderer ) {

		this._renderer = renderer;
		this._pingPongRenderTarget = null;

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

	// ... rest of the class methods ...

}

function _createPlanes( lodMax ) {

	// ... rest of the function implementation ...

}

function _createRenderTarget( width, height, params ) {

	// ... rest of the function implementation ...

}

function _setViewport( target, x, y, width, height ) {

	// ... rest of the function implementation ...

}

function _getMaterial() {

	// ... rest of the function implementation ...

}

function _getBlurShader( lodMax, width, height ) {

	// ... rest of the function implementation ...

}

function _getCubemapMaterial( envTexture ) {

	// ... rest of the function implementation ...

}

function _getEquirectMaterial( envTexture ) {

	// ... rest of the function implementation ...

}

export default PMREMGenerator;