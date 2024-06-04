import three.math.Vector2;
import three.math.Vector3;
import three.lights.DirectionalLight;
import three.math.MathUtils;
import three.renderers.shaders.ShaderChunk;
import three.math.Matrix4;
import three.math.Box3;
import three.extras.Frustum;

class CSMFrustum extends Frustum {

	public var vertices: { near: Array<Vector3>, far: Array<Vector3> };

	public function new() {
		super();
		this.vertices = {
			near: [
				new Vector3(), new Vector3(), new Vector3(), new Vector3()
			],
			far: [
				new Vector3(), new Vector3(), new Vector3(), new Vector3()
			]
		};
	}

	public function toSpace(matrix: Matrix4, target: CSMFrustum):Void {
		for (i in 0...4) {
			target.vertices.near[i].copy(this.vertices.near[i]).applyMatrix4(matrix);
			target.vertices.far[i].copy(this.vertices.far[i]).applyMatrix4(matrix);
		}
		target.planes.set(this.planes);
	}

	public function split(breaks: Array<Float>, frustums: Array<CSMFrustum>):Void {
		var far = this.vertices.far;
		var near = this.vertices.near;
		var n = breaks.length;
		for (i in 0...n) {
			var amount = breaks[i];
			var f = frustums[i];
			for (j in 0...4) {
				f.vertices.near[j].lerpVectors(near[j], far[j], amount);
				f.vertices.far[j].lerpVectors(near[j], far[j], amount);
			}
			f.planes.set(this.planes);
			f.update();
		}
	}

}

class CSMShader {

	static public var lights_fragment_begin:String =
		'// CSM\n' +
		'uniform vec2 CSM_cascades[${CSM_CASCADES}];\n' +
		'uniform float cameraNear;\n' +
		'uniform float shadowFar;\n' +
		'varying vec3 vViewPosition;\n' +
		'varying vec2 vUv;\n' +
		'varying float vDepth;\n' +
		'varying float vCascade;\n' +
		'#ifdef CSM_FADE\n' +
		'varying float vLinearDepth;\n' +
		'#endif\n' +
		'float getLinearDepth( float depth ) {\n' +
		'	return cameraNear * shadowFar / ( shadowFar - ( depth - cameraNear ) * shadowFar );\n' +
		'}\n' +
		'float getCascadeIndex( float depth ) {\n' +
		'	float linearDepth = getLinearDepth( depth );\n' +
		'	for ( int i = 0; i < ${CSM_CASCADES}; i ++ ) {\n' +
		'		if ( linearDepth < CSM_cascades[ i ].y ) {\n' +
		'			return i;\n' +
		'		}\n' +
		'	}\n' +
		'	return ${CSM_CASCADES} - 1.0;\n' +
		'}\n' +
		'vec2 getCascadeUV( float depth ) {\n' +
		'	float linearDepth = getLinearDepth( depth );\n' +
		'	float cascadeIndex = getCascadeIndex( depth );\n' +
		'	return ( linearDepth - CSM_cascades[ cascadeIndex ].x ) / ( CSM_cascades[ cascadeIndex ].y - CSM_cascades[ cascadeIndex ].x );\n' +
		'}\n' +
		'float getFade( float depth ) {\n' +
		'	float linearDepth = getLinearDepth( depth );\n' +
		'	float cascadeIndex = getCascadeIndex( depth );\n' +
		'	return ( linearDepth - CSM_cascades[ cascadeIndex ].x ) / ( CSM_cascades[ cascadeIndex ].y - CSM_cascades[ cascadeIndex ].x );\n' +
		'}\n';

	static public var lights_pars_begin:String =
		'// CSM\n' +
		'varying vec3 vViewPosition;\n' +
		'varying vec2 vUv;\n' +
		'varying float vDepth;\n' +
		'varying float vCascade;\n' +
		'#ifdef CSM_FADE\n' +
		'varying float vLinearDepth;\n' +
		'#endif\n';

}

class CSM {

	public var camera:three.cameras.PerspectiveCamera;
	public var parent:Dynamic;
	public var cascades:Int;
	public var maxFar:Float;
	public var mode:String;
	public var shadowMapSize:Int;
	public var shadowBias:Float;
	public var lightDirection:Vector3;
	public var lightIntensity:Float;
	public var lightNear:Float;
	public var lightFar:Float;
	public var lightMargin:Float;
	public var customSplitsCallback:Dynamic;
	public var fade:Bool;
	public var mainFrustum:CSMFrustum;
	public var frustums:Array<CSMFrustum>;
	public var breaks:Array<Float>;
	public var lights:Array<DirectionalLight>;
	public var shaders:Map<Dynamic,Dynamic>;

	public function new(data:Dynamic) {
		this.camera = cast data.camera;
		this.parent = data.parent;
		this.cascades = data.cascades != null ? cast data.cascades : 3;
		this.maxFar = data.maxFar != null ? cast data.maxFar : 100000;
		this.mode = data.mode != null ? cast data.mode : 'practical';
		this.shadowMapSize = data.shadowMapSize != null ? cast data.shadowMapSize : 2048;
		this.shadowBias = data.shadowBias != null ? cast data.shadowBias : 0.000001;
		this.lightDirection = data.lightDirection != null ? cast data.lightDirection : new Vector3(1, -1, 1).normalize();
		this.lightIntensity = data.lightIntensity != null ? cast data.lightIntensity : 3;
		this.lightNear = data.lightNear != null ? cast data.lightNear : 1;
		this.lightFar = data.lightFar != null ? cast data.lightFar : 2000;
		this.lightMargin = data.lightMargin != null ? cast data.lightMargin : 200;
		this.customSplitsCallback = data.customSplitsCallback;
		this.fade = false;
		this.mainFrustum = new CSMFrustum();
		this.frustums = new Array<CSMFrustum>();
		this.breaks = new Array<Float>();
		this.lights = new Array<DirectionalLight>();
		this.shaders = new Map<Dynamic,Dynamic>();
		this.createLights();
		this.updateFrustums();
		this.injectInclude();
	}

	public function createLights():Void {
		for (i in 0...this.cascades) {
			var light = new DirectionalLight(0xffffff, this.lightIntensity);
			light.castShadow = true;
			light.shadow.mapSize.set(this.shadowMapSize, this.shadowMapSize);
			light.shadow.camera.near = this.lightNear;
			light.shadow.camera.far = this.lightFar;
			light.shadow.bias = this.shadowBias;
			this.parent.add(light);
			this.parent.add(light.target);
			this.lights.push(light);
		}
	}

	public function initCascades():Void {
		var camera = this.camera;
		camera.updateProjectionMatrix();
		this.mainFrustum.setFromProjectionMatrix(camera.projectionMatrix, this.maxFar);
		for (i in 0...this.cascades) {
			this.frustums.push(new CSMFrustum());
		}
		this.mainFrustum.split(this.breaks, this.frustums);
	}

	public function updateShadowBounds():Void {
		for (i in 0...this.frustums.length) {
			var light = this.lights[i];
			var shadowCam = light.shadow.camera;
			var frustum = this.frustums[i];
			var nearVerts = frustum.vertices.near;
			var farVerts = frustum.vertices.far;
			var point1 = farVerts[0];
			var point2:Vector3;
			if (point1.distanceTo(farVerts[2]) > point1.distanceTo(nearVerts[2])) {
				point2 = farVerts[2];
			} else {
				point2 = nearVerts[2];
			}
			var squaredBBWidth = point1.distanceTo(point2);
			if (this.fade) {
				var camera = this.camera;
				var far = Math.max(camera.far, this.maxFar);
				var linearDepth = frustum.vertices.far[0].z / (far - camera.near);
				var margin = 0.25 * Math.pow(linearDepth, 2.0) * (far - camera.near);
				squaredBBWidth += margin;
			}
			shadowCam.left = -squaredBBWidth / 2;
			shadowCam.right = squaredBBWidth / 2;
			shadowCam.top = squaredBBWidth / 2;
			shadowCam.bottom = -squaredBBWidth / 2;
			shadowCam.updateProjectionMatrix();
		}
	}

	public function getBreaks():Void {
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
			if (this.customSplitsCallback == null) {
				trace('CSM: Custom split scheme callback not defined.');
			}
			this.customSplitsCallback(this.cascades, camera.near, far, this.breaks);
			break;
		}
	}

	public function update():Void {
		var camera = this.camera;
		var frustums = this.frustums;
		var _lightOrientationMatrix = new Matrix4();
		var _lightOrientationMatrixInverse = new Matrix4();
		var _up = new Vector3(0, 1, 0);
		_lightOrientationMatrix.lookAt(new Vector3(), this.lightDirection, _up);
		_lightOrientationMatrixInverse.copy(_lightOrientationMatrix).invert();
		for (i in 0...frustums.length) {
			var light = this.lights[i];
			var shadowCam = light.shadow.camera;
			var texelWidth = (shadowCam.right - shadowCam.left) / this.shadowMapSize;
			var texelHeight = (shadowCam.top - shadowCam.bottom) / this.shadowMapSize;
			var _cameraToLightMatrix = new Matrix4();
			_cameraToLightMatrix.multiplyMatrices(_lightOrientationMatrixInverse, camera.matrixWorld);
			frustums[i].toSpace(_cameraToLightMatrix, cast frustums[i]);
			var nearVerts = cast frustums[i].vertices.near;
			var farVerts = cast frustums[i].vertices.far;
			var _bbox = new Box3();
			_bbox.makeEmpty();
			for (j in 0...4) {
				_bbox.expandByPoint(nearVerts[j]);
				_bbox.expandByPoint(farVerts[j]);
			}
			var _center = new Vector3();
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

	public function injectInclude():Void {
		ShaderChunk.lights_fragment_begin = CSMShader.lights_fragment_begin;
		ShaderChunk.lights_pars_begin = CSMShader.lights_pars_begin;
	}

	public function setupMaterial(material:Dynamic):Void {
		material.defines = material.defines != null ? cast material.defines : new Map<String,Dynamic>();
		material.defines.set('USE_CSM', 1);
		material.defines.set('CSM_CASCADES', this.cascades);
		if (this.fade) {
			material.defines.set('CSM_FADE', '');
		}
		var breaksVec2:Array<Vector2> = new Array<Vector2>();
		var scope = this;
		material.onBeforeCompile = function(shader:Dynamic) {
			var far = Math.min(scope.camera.far, scope.maxFar);
			scope.getExtendedBreaks(breaksVec2);
			shader.uniforms.set('CSM_cascades', {value: breaksVec2});
			shader.uniforms.set('cameraNear', {value: scope.camera.near});
			shader.uniforms.set('shadowFar', {value: far});
			scope.shaders.set(material, shader);
		};
		scope.shaders.set(material, null);
	}

	public function updateUniforms():Void {
		var far = Math.min(this.camera.far, this.maxFar);
		this.shaders.forEach(function(shader:Dynamic, material:Dynamic) {
			if (shader != null) {
				var uniforms = cast shader.uniforms;
				this.getExtendedBreaks(uniforms.get('CSM_cascades').value);
				uniforms.get('cameraNear').value = this.camera.near;
				uniforms.get('shadowFar').value = far;
			}
			if (!this.fade && material.defines.exists('CSM_FADE')) {
				material.defines.remove('CSM_FADE');
				material.needsUpdate = true;
			} else if (this.fade && !material.defines.exists('CSM_FADE')) {
				material.defines.set('CSM_FADE', '');
				material.needsUpdate = true;
			}
		}, this);
	}

	public function getExtendedBreaks(target:Array<Vector2>):Void {
		while (target.length < this.breaks.length) {
			target.push(new Vector2());
		}
		target.length = this.breaks.length;
		for (i in 0...this.cascades) {
			var amount = this.breaks[i];
			var prev = this.breaks[i - 1] != null ? this.breaks[i - 1] : 0;
			target[i].set(prev, amount);
		}
	}

	public function updateFrustums():Void {
		this.getBreaks();
		this.initCascades();
		this.updateShadowBounds();
		this.updateUniforms();
	}

	public function remove():Void {
		for (i in 0...this.lights.length) {
			this.parent.remove(this.lights[i].target);
			this.parent.remove(this.lights[i]);
		}
	}

	public function dispose():Void {
		this.shaders.forEach(function(shader:Dynamic, material:Dynamic) {
			material.onBeforeCompile = null;
			material.defines.remove('USE_CSM');
			material.defines.remove('CSM_CASCADES');
			material.defines.remove('CSM_FADE');
			if (shader != null) {
				shader.uniforms.remove('CSM_cascades');
				shader.uniforms.remove('cameraNear');
				shader.uniforms.remove('shadowFar');
			}
			material.needsUpdate = true;
		}, this);
		this.shaders.clear();
	}

	static function uniformSplit(amount:Int, near:Float, far:Float, target:Array<Float>):Void {
		for (i in 1...amount) {
			target.push((near + (far - near) * i / amount) / far);
		}
		target.push(1);
	}

	static function logarithmicSplit(amount:Int, near:Float, far:Float, target:Array<Float>):Void {
		for (i in 1...amount) {
			target.push((near * (far / near) ** (i / amount)) / far);
		}
		target.push(1);
	}

	static function practicalSplit(amount:Int, near:Float, far:Float, lambda:Float, target:Array<Float>):Void {
		var _uniformArray:Array<Float> = new Array<Float>();
		var _logArray:Array<Float> = new Array<Float>();
		logarithmicSplit(amount, near, far, _logArray);
		uniformSplit(amount, near, far, _uniformArray);
		for (i in 1...amount) {
			target.push(MathUtils.lerp(_uniformArray[i - 1], _logArray[i - 1], lambda));
		}
		target.push(1);
	}

}