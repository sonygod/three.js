import three.Vector2;
import three.Vector3;
import three.DirectionalLight;
import three.MathUtils;
import three.ShaderChunk;
import three.Matrix4;
import three.Box3;
import three.examples.jsm.csm.CSMFrustum;
import three.examples.jsm.csm.CSMShader;

class CSM {

	var camera:Dynamic;
	var parent:Dynamic;
	var cascades:Int;
	var maxFar:Float;
	var mode:String;
	var shadowMapSize:Int;
	var shadowBias:Float;
	var lightDirection:Vector3;
	var lightIntensity:Float;
	var lightNear:Float;
	var lightFar:Float;
	var lightMargin:Float;
	var customSplitsCallback:Dynamic;
	var fade:Bool;
	var mainFrustum:CSMFrustum;
	var frustums:Array<CSMFrustum>;
	var breaks:Array<Float>;
	var lights:Array<DirectionalLight>;
	var shaders:Map<Dynamic, Dynamic>;

	public function new(data:Dynamic) {

		this.camera = data.camera;
		this.parent = data.parent;
		this.cascades = data.cascades || 3;
		this.maxFar = data.maxFar || 100000;
		this.mode = data.mode || 'practical';
		this.shadowMapSize = data.shadowMapSize || 2048;
		this.shadowBias = data.shadowBias || 0.000001;
		this.lightDirection = data.lightDirection || new Vector3( 1, - 1, 1 ).normalize();
		this.lightIntensity = data.lightIntensity || 3;
		this.lightNear = data.lightNear || 1;
		this.lightFar = data.lightFar || 2000;
		this.lightMargin = data.lightMargin || 200;
		this.customSplitsCallback = data.customSplitsCallback;
		this.fade = false;
		this.mainFrustum = new CSMFrustum();
		this.frustums = [];
		this.breaks = [];
		this.lights = [];
		this.shaders = new Map();

		this.createLights();
		this.updateFrustums();
		this.injectInclude();

	}

	public function createLights() {

		for (i in 0...this.cascades) {

			var light = new DirectionalLight( 0xffffff, this.lightIntensity );
			light.castShadow = true;
			light.shadow.mapSize.width = this.shadowMapSize;
			light.shadow.mapSize.height = this.shadowMapSize;
			light.shadow.camera.near = this.lightNear;
			light.shadow.camera.far = this.lightFar;
			light.shadow.bias = this.shadowBias;
			this.parent.add( light );
			this.parent.add( light.target );
			this.lights.push( light );

		}

	}

	public function initCascades() {

		var camera = this.camera;
		camera.updateProjectionMatrix();
		this.mainFrustum.setFromProjectionMatrix( camera.projectionMatrix, this.maxFar );
		this.mainFrustum.split( this.breaks, this.frustums );

	}

	public function updateShadowBounds() {

		var frustums = this.frustums;
		for (i in 0...frustums.length) {

			var light = this.lights[i];
			var shadowCam = light.shadow.camera;
			var frustum = this.frustums[i];
			var nearVerts = frustum.vertices.near;
			var farVerts = frustum.vertices.far;
			var point1 = farVerts[0];
			var point2 = (point1.distanceTo(farVerts[2]) > point1.distanceTo(nearVerts[2])) ? farVerts[2] : nearVerts[2];
			var squaredBBWidth = point1.distanceTo(point2);
			if (this.fade) {
				var camera = this.camera;
				var far = Math.max(camera.far, this.maxFar);
				var linearDepth = frustum.vertices.far[0].z / (far - camera.near);
				var margin = 0.25 * Math.pow(linearDepth, 2.0) * (far - camera.near);
				squaredBBWidth += margin;
			}
			shadowCam.left = - squaredBBWidth / 2;
			shadowCam.right = squaredBBWidth / 2;
			shadowCam.top = squaredBBWidth / 2;
			shadowCam.bottom = - squaredBBWidth / 2;
			shadowCam.updateProjectionMatrix();

		}

	}

	public function getBreaks() {

		var camera = this.camera;
		var far = Math.min(camera.far, this.maxFar);
		this.breaks.length = 0;

		switch (this.mode) {

			case 'uniform':
				uniformSplit(this.cascades, camera.near, far, this.breaks);
				break;
			case 'logarithmic':
				logarithmicSplit(this.cascades, camera.near, far, this.breaks);
				break;
			case 'practical':
				practicalSplit(this.cascades, camera.near, far, 0.5, this.breaks);
				break;
			case 'custom':
				if (this.customSplitsCallback === undefined) console.error('CSM: Custom split scheme callback not defined.');
				this.customSplitsCallback(this.cascades, camera.near, far, this.breaks);
				break;

		}

		function uniformSplit(amount:Int, near:Float, far:Float, target:Array<Float>) {

			for (i in 1...amount) {
				target.push((near + (far - near) * i / amount) / far);
			}
			target.push(1);

		}

		function logarithmicSplit(amount:Int, near:Float, far:Float, target:Array<Float>) {

			for (i in 1...amount) {
				target.push((near * (far / near) ** (i / amount)) / far);
			}
			target.push(1);

		}

		function practicalSplit(amount:Int, near:Float, far:Float, lambda:Float, target:Array<Float>) {

			var _uniformArray:Array<Float> = [];
			var _logArray:Array<Float> = [];
			logarithmicSplit(amount, near, far, _logArray);
			uniformSplit(amount, near, far, _uniformArray);
			for (i in 1...amount) {
				target.push(MathUtils.lerp(_uniformArray[i - 1], _logArray[i - 1], lambda));
			}
			target.push(1);

		}

	}

	public function update() {

		var camera = this.camera;
		var frustums = this.frustums;
		var _lightOrientationMatrix = new Matrix4();
		var _lightOrientationMatrixInverse = new Matrix4();
		var _up = new Vector3(0, 1, 0);
		var _cameraToLightMatrix = new Matrix4();
		var _lightSpaceFrustum = new CSMFrustum();
		var _center = new Vector3();
		var _bbox = new Box3();
		_lightOrientationMatrix.lookAt(new Vector3(), this.lightDirection, _up);
		_lightOrientationMatrixInverse.copy(_lightOrientationMatrix).invert();
		for (i in 0...frustums.length) {
			var light = this.lights[i];
			var shadowCam = light.shadow.camera;
			var texelWidth = (shadowCam.right - shadowCam.left) / this.shadowMapSize;
			var texelHeight = (shadowCam.top - shadowCam.bottom) / this.shadowMapSize;
			_cameraToLightMatrix.multiplyMatrices(_lightOrientationMatrixInverse, camera.matrixWorld);
			frustums[i].toSpace(_cameraToLightMatrix, _lightSpaceFrustum);
			var nearVerts = _lightSpaceFrustum.vertices.near;
			var farVerts = _lightSpaceFrustum.vertices.far;
			_bbox.makeEmpty();
			for (j in 0...4) {
				_bbox.expandByPoint(nearVerts[j]);
				_bbox.expandByPoint(farVerts[j]);
			}
			_bbox.getCenter(_center);
			_center.z = _bbox.max.z + this.lightMargin;
			_center.x = Math.floor(_center.x / texelWidth) * texelWidth;
			_center.y = Math.floor(_center.y / texelHeight) * texelHeight;
			_center.applyMatrix4(_lightOrientationMatrix);
			light.position.copy(_center);
			light.target.position.copy(_center);
			light.target.position.x += this.lightDirection.x;
			light.target.position.y += this.lightDirection.y;
			light.target.position.z += this.lightDirection.z;
		}

	}

	public function injectInclude() {

		ShaderChunk.lights_fragment_begin = CSMShader.lights_fragment_begin;
		ShaderChunk.lights_pars_begin = CSMShader.lights_pars_begin;

	}

	public function setupMaterial(material:Dynamic) {

		material.defines = material.defines || {};
		material.defines.USE_CSM = 1;
		material.defines.CSM_CASCADES = this.cascades;
		if (this.fade) {
			material.defines.CSM_FADE = '';
		}
		var breaksVec2:Array<Vector2> = [];
		var shaders = this.shaders;
		material.onBeforeCompile = function (shader:Dynamic) {
			var far = Math.min(this.camera.far, this.maxFar);
			this.getExtendedBreaks(breaksVec2);
			shader.uniforms.CSM_cascades = {value: breaksVec2};
			shader.uniforms.cameraNear = {value: this.camera.near};
			shader.uniforms.shadowFar = {value: far};
			shaders.set(material, shader);
		};
		shaders.set(material, null);

	}

	public function updateUniforms() {

		var far = Math.min(this.camera.far, this.maxFar);
		var shaders = this.shaders;
		shaders.forEach(function (shader:Dynamic, material:Dynamic) {
			if (shader !== null) {
				var uniforms = shader.uniforms;
				this.getExtendedBreaks(uniforms.CSM_cascades.value);
				uniforms.cameraNear.value = this.camera.near;
				uniforms.shadowFar.value = far;
			}
			if (!this.fade && 'CSM_FADE' in material.defines) {
				delete material.defines.CSM_FADE;
				material.needsUpdate = true;
			} else if (this.fade && !('CSM_FADE' in material.defines)) {
				material.defines.CSM_FADE = '';
				material.needsUpdate = true;
			}
		}, this);

	}

	public function getExtendedBreaks(target:Array<Vector2>) {

		while (target.length < this.breaks.length) {
			target.push(new Vector2());
		}
		target.length = this.breaks.length;
		for (i in 0...this.cascades) {
			var amount = this.breaks[i];
			var prev = this.breaks[i - 1] || 0;
			target[i].x = prev;
			target[i].y = amount;
		}

	}

	public function updateFrustums() {

		this.getBreaks();
		this.initCascades();
		this.updateShadowBounds();
		this.updateUniforms();

	}

	public function remove() {

		for (i in 0...this.lights.length) {
			this.parent.remove(this.lights[i].target);
			this.parent.remove(this.lights[i]);
		}

	}

	public function dispose() {

		var shaders = this.shaders;
		shaders.forEach(function (shader:Dynamic, material:Dynamic) {
			delete material.onBeforeCompile;
			delete material.defines.USE_CSM;
			delete material.defines.CSM_CASCADES;
			delete material.defines.CSM_FADE;
			if (shader !== null) {
				delete shader.uniforms.CSM_cascades;
				delete shader.uniforms.cameraNear;
				delete shader.uniforms.shadowFar;
			}
			material.needsUpdate = true;
		});
		shaders.clear();

	}

}