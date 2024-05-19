import three.js.src.extras.PMREMGenerator_func_part1.*;

class PMREMGenerator {

	var _renderer:Renderer;
	var _pingPongRenderTarget:WebGLRenderTarget;
	var _lodMax:Int;
	var _cubeSize:Int;
	var _lodPlanes:Array<Mesh>;
	var _sizeLods:Array<Int>;
	var _sigmas:Array<Float>;
	var _blurMaterial:ShaderMaterial;
	var _cubemapMaterial:ShaderMaterial;
	var _equirectMaterial:ShaderMaterial;

	public function new(renderer:Renderer) {
		_renderer = renderer;
		_pingPongRenderTarget = null;
		_lodMax = 0;
		_cubeSize = 0;
		_lodPlanes = [];
		_sizeLods = [];
		_sigmas = [];
		_blurMaterial = null;
		_cubemapMaterial = null;
		_equirectMaterial = null;
		_compileMaterial(_blurMaterial);
	}

	public function fromScene(scene:Scene, sigma:Float = 0, near:Float = 0.1, far:Float = 100):WebGLRenderTarget {
		var oldTarget = _renderer.getRenderTarget();
		var oldActiveCubeFace = _renderer.getActiveCubeFace();
		var oldActiveMipmapLevel = _renderer.getActiveMipmapLevel();
		var oldXrEnabled = _renderer.xr.enabled;
		_renderer.xr.enabled = false;
		_setSize(256);
		var cubeUVRenderTarget = _allocateTargets();
		cubeUVRenderTarget.depthBuffer = true;
		_sceneToCubeUV(scene, near, far, cubeUVRenderTarget);
		if (sigma > 0) {
			_blur(cubeUVRenderTarget, 0, 0, sigma);
		}
		_applyPMREM(cubeUVRenderTarget);
		_cleanup(cubeUVRenderTarget);
		return cubeUVRenderTarget;
	}

	public function fromEquirectangular(equirectangular:Texture, renderTarget:WebGLRenderTarget = null):WebGLRenderTarget {
		return _fromTexture(equirectangular, renderTarget);
	}

	public function fromCubemap(cubemap:Texture, renderTarget:WebGLRenderTarget = null):WebGLRenderTarget {
		return _fromTexture(cubemap, renderTarget);
	}

	public function compileCubemapShader():Void {
		if (_cubemapMaterial == null) {
			_cubemapMaterial = _getCubemapMaterial();
			_compileMaterial(_cubemapMaterial);
		}
	}

	public function compileEquirectangularShader():Void {
		if (_equirectMaterial == null) {
			_equirectMaterial = _getEquirectMaterial();
			_compileMaterial(_equirectMaterial);
		}
	}

	public function dispose():Void {
		_dispose();
		if (_cubemapMaterial != null) _cubemapMaterial.dispose();
		if (_equirectMaterial != null) _equirectMaterial.dispose();
	}

	private function _setSize(cubeSize:Int):Void {
		_lodMax = Math.floor(Math.log2(cubeSize));
		_cubeSize = Math.pow(2, _lodMax);
	}

	private function _dispose():Void {
		if (_blurMaterial != null) _blurMaterial.dispose();
		if (_pingPongRenderTarget != null) _pingPongRenderTarget.dispose();
		for (i in 0..._lodPlanes.length) {
			_lodPlanes[i].dispose();
		}
	}

	private function _cleanup(outputTarget:WebGLRenderTarget):Void {
		_renderer.setRenderTarget(_oldTarget, _oldActiveCubeFace, _oldActiveMipmapLevel);
		_renderer.xr.enabled = _oldXrEnabled;
		outputTarget.scissorTest = false;
		_setViewport(outputTarget, 0, 0, outputTarget.width, outputTarget.height);
	}

	private function _fromTexture(texture:Texture, renderTarget:WebGLRenderTarget):WebGLRenderTarget {
		if (texture.mapping == CubeReflectionMapping || texture.mapping == CubeRefractionMapping) {
			_setSize(texture.image.length == 0 ? 16 : (texture.image[0].width || texture.image[0].image.width));
		} else { // Equirectangular
			_setSize(texture.image.width / 4);
		}
		var oldTarget = _renderer.getRenderTarget();
		var oldActiveCubeFace = _renderer.getActiveCubeFace();
		var oldActiveMipmapLevel = _renderer.getActiveMipmapLevel();
		var oldXrEnabled = _renderer.xr.enabled;
		_renderer.xr.enabled = false;
		var cubeUVRenderTarget = renderTarget || _allocateTargets();
		_textureToCubeUV(texture, cubeUVRenderTarget);
		_applyPMREM(cubeUVRenderTarget);
		_cleanup(cubeUVRenderTarget);
		return cubeUVRenderTarget;
	}

	private function _allocateTargets():WebGLRenderTarget {
		var width = 3 * Math.max(_cubeSize, 16 * 7);
		var height = 4 * _cubeSize;
		var params = {
			magFilter: LinearFilter,
			minFilter: LinearFilter,
			generateMipmaps: false,
			type: HalfFloatType,
			format: RGBAFormat,
			colorSpace: LinearSRGBColorSpace,
			depthBuffer: false
		};
		var cubeUVRenderTarget = _createRenderTarget(width, height, params);
		if (_pingPongRenderTarget == null || _pingPongRenderTarget.width != width || _pingPongRenderTarget.height != height) {
			if (_pingPongRenderTarget != null) {
				_dispose();
			}
			_pingPongRenderTarget = _createRenderTarget(width, height, params);
			({sizeLods: _sizeLods, lodPlanes: _lodPlanes, sigmas: _sigmas} = _createPlanes(_lodMax));
			_blurMaterial = _getBlurShader(_lodMax, width, height);
		}
		return cubeUVRenderTarget;
	}

	private function _compileMaterial(material:ShaderMaterial):Void {
		var tmpMesh = new Mesh(_lodPlanes[0], material);
		_renderer.compile(tmpMesh, _flatCamera);
	}

	private function _sceneToCubeUV(scene:Scene, near:Float, far:Float, cubeUVRenderTarget:WebGLRenderTarget):Void {
		var fov = 90;
		var aspect = 1;
		var cubeCamera = new PerspectiveCamera(fov, aspect, near, far);
		var upSign = [1, -1, 1, 1, 1, 1];
		var forwardSign = [1, 1, 1, -1, -1, -1];
		var renderer = _renderer;
		var originalAutoClear = renderer.autoClear;
		var toneMapping = renderer.toneMapping;
		renderer.getClearColor(_clearColor);
		renderer.toneMapping = NoToneMapping;
		renderer.autoClear = false;
		var backgroundMaterial = new MeshBasicMaterial({
			name: 'PMREM.Background',
			side: BackSide,
			depthWrite: false,
			depthTest: false,
		});
		var backgroundBox = new Mesh(new BoxGeometry(), backgroundMaterial);
		var useSolidColor = false;
		var background = scene.background;
		if (background) {
			if (background.isColor) {
				backgroundMaterial.color.copy(background);
				scene.background = null;
				useSolidColor = true;
			}
		} else {
			backgroundMaterial.color.copy(_clearColor);
			useSolidColor = true;
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
			var size = _cubeSize;
			_setViewport(cubeUVRenderTarget, col * size, i > 2 ? size : 0, size, size);
			renderer.setRenderTarget(cubeUVRenderTarget);
			if (useSolidColor) {
				renderer.render(backgroundBox, cubeCamera);
			}
			renderer.render(scene, cubeCamera);
		}
		backgroundBox.geometry.dispose();
		backgroundBox.material.dispose();
		renderer.toneMapping = toneMapping;
		renderer.autoClear = originalAutoClear;
		scene.background = background;
	}

	private function _textureToCubeUV(texture:Texture, cubeUVRenderTarget:WebGLRenderTarget):Void {
		var renderer = _renderer;
		var isCubeTexture = (texture.mapping == CubeReflectionMapping || texture.mapping == CubeRefractionMapping);
		if (isCubeTexture) {
			if (_cubemapMaterial == null) {
				_cubemapMaterial = _getCubemapMaterial();
			}
			_cubemapMaterial.uniforms.flipEnvMap.value = (texture.isRenderTargetTexture == false) ? -1 : 1;
		} else {
			if (_equirectMaterial == null) {
				_equirectMaterial = _getEquirectMaterial();
			}
		}
		var material = isCubeTexture ? _cubemapMaterial : _equirectMaterial;
		var mesh = new Mesh(_lodPlanes[0], material);
		var uniforms = material.uniforms;
		uniforms['envMap'].value = texture;
		var size = _cubeSize;
		_setViewport(cubeUVRenderTarget, 0, 0, 3 * size, 2 * size);
		renderer.setRenderTarget(cubeUVRenderTarget);
		renderer.render(mesh, _flatCamera);
	}

	private function _applyPMREM(cubeUVRenderTarget:WebGLRenderTarget):Void {
		var renderer = _renderer;
		var autoClear = renderer.autoClear;
		renderer.autoClear = false;
		var n = _lodPlanes.length;
		for (i in 1...n) {
			var sigma = Math.sqrt(_sigmas[i] * _sigmas[i] - _sigmas[i - 1] * _sigmas[i - 1]);
			var poleAxis = _axisDirections[(n - i - 1) % _axisDirections.length];
			_blur(cubeUVRenderTarget, i - 1, i, sigma, poleAxis);
		}
		renderer.autoClear = autoClear;
	}

	private function _blur(cubeUVRenderTarget:WebGLRenderTarget, lodIn:Int, lodOut:Int, sigma:Float, poleAxis:Vector3):Void {
		var pingPongRenderTarget = _pingPongRenderTarget;
		_halfBlur(cubeUVRenderTarget, pingPongRenderTarget, lodIn, lodOut, sigma, 'latitudinal', poleAxis);
		_halfBlur(pingPongRenderTarget, cubeUVRenderTarget, lodOut, lodOut, sigma, 'longitudinal', poleAxis);
	}

	// ... rest of the functions ...

}