import three.js.examples.jsm.misc.potpack.Potpack;
import three.js.WebGLRenderer;
import three.js.Scene;
import three.js.WebGLRenderTarget;
import three.js.MeshPhongMaterial;
import three.js.MeshBasicMaterial;
import three.js.PlaneGeometry;
import three.js.Mesh;
import three.js.Vector3;
import three.js.Object3D;
import three.js.Camera;
import three.js.FloatType;
import three.js.HalfFloatType;

class ProgressiveLightMap {

	var renderer:WebGLRenderer;
	var res:Int;
	var lightMapContainers:Array<{basicMat:MeshPhongMaterial, object:Object3D}>;
	var compiled:Bool = false;
	var scene:Scene;
	var tinyTarget:WebGLRenderTarget;
	var buffer1Active:Bool = false;
	var firstUpdate:Bool = true;
	var warned:Bool = false;
	var progressiveLightMap1:WebGLRenderTarget;
	var progressiveLightMap2:WebGLRenderTarget;
	var uvMat:MeshPhongMaterial;
	var blurringPlane:Mesh;
	var labelMesh:Mesh;
	var labelMaterial:MeshBasicMaterial;
	var labelPlane:PlaneGeometry;

	public function new(renderer:WebGLRenderer, res:Int = 1024) {
		this.renderer = renderer;
		this.res = res;
		this.lightMapContainers = [];
		this.scene = new Scene();
		this.scene.background = null;
		this.tinyTarget = new WebGLRenderTarget(1, 1);
		this.progressiveLightMap1 = new WebGLRenderTarget(this.res, this.res, { type: /(Android|iPad|iPhone|iPod)/g.test(navigator.userAgent) ? HalfFloatType : FloatType });
		this.progressiveLightMap2 = new WebGLRenderTarget(this.res, this.res, { type: /(Android|iPad|iPhone|iPod)/g.test(navigator.userAgent) ? HalfFloatType : FloatType });
		this.progressiveLightMap2.texture.channel = 1;
		this.uvMat = new MeshPhongMaterial();
		this.uvMat.uniforms = {};
		this.uvMat.onBeforeCompile = (shader) -> {
			shader.vertexShader =
				'attribute vec2 uv1;\n' +
				'#define USE_LIGHTMAP\n' +
				'#define LIGHTMAP_UV uv1\n' +
				shader.vertexShader.slice(0, -1) +
				'	gl_Position = vec4((LIGHTMAP_UV - 0.5) * 2.0, 1.0, 1.0); }';
			shader.fragmentShader =
				'#define USE_LIGHTMAP\n' +
				shader.fragmentShader.slice(0, shader.fragmentShader.indexOf('void main() {')) +
				'	uniform sampler2D previousShadowMap;\n	uniform float averagingWindow;\n' +
				shader.fragmentShader.slice(shader.fragmentShader.indexOf('void main() {') - 1, -1) +
				'	vec3 texelOld = texture2D(previousShadowMap, vLightMapUv).rgb;' +
				'	gl_FragColor.rgb = mix(texelOld, gl_FragColor.rgb, 1.0/averagingWindow);' +
				'}';
			shader.uniforms.previousShadowMap = { value: this.progressiveLightMap1.texture };
			shader.uniforms.averagingWindow = { value: 100 };
			this.uvMat.uniforms = shader.uniforms;
			this.uvMat.userData.shader = shader;
			this.compiled = true;
		};
	}

	public function addObjectsToLightMap(objects:Array<Object3D>) {
		var uv_boxes:Array<{w:Float, h:Float, index:Int}> = [];
		var padding:Float = 3 / this.res;
		for (ob in objects) {
			var object = objects[ob];
			if (object.isLight) {
				this.scene.attach(object);
				continue;
			}
			if (!object.geometry.hasAttribute('uv')) {
				trace('All lightmap objects need UVs!');
				continue;
			}
			if (this.blurringPlane == null) {
				this._initializeBlurPlane(this.res, this.progressiveLightMap1);
			}
			object.material.lightMap = this.progressiveLightMap2.texture;
			object.material.dithering = true;
			object.castShadow = true;
			object.receiveShadow = true;
			object.renderOrder = 1000 + ob;
			uv_boxes.push({ w: 1 + (padding * 2), h: 1 + (padding * 2), index: ob });
			this.lightMapContainers.push({ basicMat: object.material, object: object });
			this.compiled = false;
		}
		var dimensions = Potpack.pack(uv_boxes);
		for (box in uv_boxes) {
			var uv1 = objects[box.index].geometry.getAttribute('uv').clone();
			for (i in uv1.array) {
				uv1.array[i] = (uv1.array[i] + box.x + padding) / dimensions.w;
				uv1.array[i + 1] = (uv1.array[i + 1] + box.y + padding) / dimensions.h;
			}
			objects[box.index].geometry.setAttribute('uv1', uv1);
			objects[box.index].geometry.getAttribute('uv1').needsUpdate = true;
		}
	}

	public function update(camera:Camera, blendWindow:Float = 100, blurEdges:Bool = true) {
		if (this.blurringPlane == null) {
			return;
		}
		var oldTarget = this.renderer.getRenderTarget();
		this.blurringPlane.visible = blurEdges;
		for (l in this.lightMapContainers) {
			this.lightMapContainers[l].object.oldScene = this.lightMapContainers[l].object.parent;
			this.scene.attach(this.lightMapContainers[l].object);
		}
		if (this.firstUpdate) {
			this.renderer.setRenderTarget(this.tinyTarget);
			this.renderer.render(this.scene, camera);
			this.firstUpdate = false;
		}
		for (l in this.lightMapContainers) {
			this.uvMat.uniforms.averagingWindow = { value: blendWindow };
			this.lightMapContainers[l].object.material = this.uvMat;
			this.lightMapContainers[l].object.oldFrustumCulled = this.lightMapContainers[l].object.frustumCulled;
			this.lightMapContainers[l].object.frustumCulled = false;
		}
		var activeMap = this.buffer1Active ? this.progressiveLightMap1 : this.progressiveLightMap2;
		var inactiveMap = this.buffer1Active ? this.progressiveLightMap2 : this.progressiveLightMap1;
		this.renderer.setRenderTarget(activeMap);
		this.uvMat.uniforms.previousShadowMap = { value: inactiveMap.texture };
		this.blurringPlane.material.uniforms.previousShadowMap = { value: inactiveMap.texture };
		this.buffer1Active = !this.buffer1Active;
		this.renderer.render(this.scene, camera);
		for (l in this.lightMapContainers) {
			this.lightMapContainers[l].object.frustumCulled = this.lightMapContainers[l].object.oldFrustumCulled;
			this.lightMapContainers[l].object.material = this.lightMapContainers[l].basicMat;
			this.lightMapContainers[l].object.oldScene.attach(this.lightMapContainers[l].object);
		}
		this.renderer.setRenderTarget(oldTarget);
	}

	public function showDebugLightmap(visible:Bool, position:Vector3 = null) {
		if (this.lightMapContainers.length == 0) {
			if (!this.warned) {
				trace('Call this after adding the objects!');
				this.warned = true;
			}
			return;
		}
		if (this.labelMesh == null) {
			this.labelMaterial = new MeshBasicMaterial({ map: this.progressiveLightMap1.texture, side: DoubleSide });
			this.labelPlane = new PlaneGeometry(100, 100);
			this.labelMesh = new Mesh(this.labelPlane, this.labelMaterial);
			this.labelMesh.position.y = 250;
			this.lightMapContainers[0].object.parent.add(this.labelMesh);
		}
		if (position != null) {
			this.labelMesh.position.copy(position);
		}
		this.labelMesh.visible = visible;
	}

	private function _initializeBlurPlane(res:Int, lightMap:WebGLRenderTarget = null) {
		var blurMaterial = new MeshBasicMaterial();
		blurMaterial.uniforms = { previousShadowMap: { value: null }, pixelOffset: { value: 1.0 / res }, polygonOffset: true, polygonOffsetFactor: -1, polygonOffsetUnits: 3.0 };
		blurMaterial.onBeforeCompile = (shader) -> {
			shader.vertexShader =
				'#define USE_UV\n' +
				shader.vertexShader.slice(0, -1) +
				'	gl_Position = vec4((uv - 0.5) * 2.0, 1.0, 1.0); }';
			shader.fragmentShader =
				'#define USE_UV\n' +
				shader.fragmentShader.slice(0, shader.fragmentShader.indexOf('void main() {')) +
				'	uniform sampler2D previousShadowMap;\n	uniform float pixelOffset;\n' +
				shader.fragmentShader.slice(shader.fragmentShader.indexOf('void main() {') - 1, -1) +
				'	gl_FragColor.rgb = (' +
				'		texture2D(previousShadowMap, vUv + vec2( pixelOffset,  0.0        )).rgb +' +
				'		texture2D(previousShadowMap, vUv + vec2( 0.0        ,  pixelOffset)).rgb +' +
				'		texture2D(previousShadowMap, vUv + vec2( 0.0        , -pixelOffset)).rgb +' +
				'		texture2D(previousShadowMap, vUv + vec2(-pixelOffset,  0.0        )).rgb +' +
				'		texture2D(previousShadowMap, vUv + vec2( pixelOffset,  pixelOffset)).rgb +' +
				'		texture2D(previousShadowMap, vUv + vec2(-pixelOffset,  pixelOffset)).rgb +' +
				'		texture2D(previousShadowMap, vUv + vec2( pixelOffset, -pixelOffset)).rgb +' +
				'		texture2D(previousShadowMap, vUv + vec2(-pixelOffset, -pixelOffset)).rgb)/8.0;' +
				'}';
			shader.uniforms.previousShadowMap = { value: lightMap.texture };
			shader.uniforms.pixelOffset = { value: 0.5 / res };
			blurMaterial.uniforms = shader.uniforms;
			blurMaterial.userData.shader = shader;
			this.compiled = true;
		};
		this.blurringPlane = new Mesh(new PlaneGeometry(1, 1), blurMaterial);
		this.blurringPlane.name = 'Blurring Plane';
		this.blurringPlane.frustumCulled = false;
		this.blurringPlane.renderOrder = 0;
		this.blurringPlane.material.depthWrite = false;
		this.scene.add(this.blurringPlane);
	}
}