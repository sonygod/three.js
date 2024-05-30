import DataMap from './DataMap.hx';

import Vector3 from 'three';
import DepthTexture from 'three';
import DepthStencilFormat from 'three';
import DepthFormat from 'three';
import UnsignedIntType from 'three';
import UnsignedInt248Type from 'three';
import LinearFilter from 'three';
import NearestFilter from 'three';
import EquirectangularReflectionMapping from 'three';
import EquirectangularRefractionMapping from 'three';
import CubeReflectionMapping from 'three';
import CubeRefractionMapping from 'three';
import UnsignedByteType from 'three';

class Textures extends DataMap {

	public var renderer:Dynamic;
	public var backend:Dynamic;
	public var info:Dynamic;

	public function new(renderer:Dynamic, backend:Dynamic, info:Dynamic) {
		super();
		this.renderer = renderer;
		this.backend = backend;
		this.info = info;
	}

	public function updateRenderTarget(renderTarget:Dynamic, activeMipmapLevel:Int = 0) {
		// ...
	}

	public function updateTexture(texture:Dynamic, options:Dynamic = {}) {
		// ...
	}

	public function getSize(texture:Dynamic, target:Vector3 = new Vector3()) {
		// ...
	}

	public function getMipLevels(texture:Dynamic, width:Int, height:Int) {
		// ...
	}

	public function needsMipmaps(texture:Dynamic) {
		// ...
	}

	public function isEnvironmentTexture(texture:Dynamic) {
		// ...
	}

	private function _destroyTexture(texture:Dynamic) {
		// ...
	}

}

export default Textures;