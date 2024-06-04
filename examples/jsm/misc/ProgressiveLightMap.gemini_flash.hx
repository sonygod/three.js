import three.Object3D;
import three.Light;
import three.Scene;
import three.Mesh;
import three.MeshPhongMaterial;
import three.Vector3;
import three.Camera;
import three.WebGLRenderTarget;
import three.WebGLRenderer;
import three.PlaneGeometry;
import three.MeshBasicMaterial;
import three.Texture;
import three.FloatType;
import three.HalfFloatType;
import three.Geometry;
import three.BufferAttribute;
import three.Material;
import three.Shader;
import three.Uniforms;
import three.DoubleSide;

import potpack.Potpack;

/**
 * Progressive Light Map Accumulator, by [zalo](https://github.com/zalo/)
 *
 * To use, simply construct a `ProgressiveLightMap` object,
 * `plmap.addObjectsToLightMap(object)` an array of semi-static
 * objects and lights to the class once, and then call
 * `plmap.update(camera)` every frame to begin accumulating
 * lighting samples.
 *
 * This should begin accumulating lightmaps which apply to
 * your objects, so you can start jittering lighting to achieve
 * the texture-space effect you're looking for.
 *
 * @param {WebGLRenderer} renderer A WebGL Rendering Context
 * @param {number} res The side-long dimension of you total lightmap
 */
class ProgressiveLightMap {

	public var renderer:WebGLRenderer;
	public var res:Int;
	public var lightMapContainers:Array<{basicMat:Material, object:Object3D}> = [];
	public var compiled:Bool = false;
	public var scene:Scene;
	public var tinyTarget:WebGLRenderTarget;
	public var buffer1Active:Bool = false;
	public var firstUpdate:Bool = true;
	public var warned:Bool = false;
	public var progressiveLightMap1:WebGLRenderTarget;
	public var progressiveLightMap2:WebGLRenderTarget;
	public var uvMat:MeshPhongMaterial;
	public var blurringPlane:Mesh;
	public var labelMesh:Mesh;
	public var labelMaterial:MeshBasicMaterial;
	public var labelPlane:PlaneGeometry;
	public var uv_boxes:Array<{w:Float, h:Float, index:Int}> = [];

	public function new(renderer:WebGLRenderer, res:Int = 1024) {
		this.renderer = renderer;
		this.res = res;
		this.scene = new Scene();
		this.scene.background = null;
		this.tinyTarget = new WebGLRenderTarget(1, 1);
		this.progressiveLightMap1 = new WebGLRenderTarget(this.res, this.res, {type: ((Sys.systemName == "Android" || Sys.systemName == "iPad" || Sys.systemName == "iPhone" || Sys.systemName == "iPod")) ? HalfFloatType : FloatType});
		this.progressiveLightMap2 = new WebGLRenderTarget(this.res, this.res, {type: ((Sys.systemName == "Android" || Sys.systemName == "iPad" || Sys.systemName == "iPhone" || Sys.systemName == "iPod")) ? HalfFloatType : FloatType});
		this.progressiveLightMap2.texture.channel = 1;
		this.uvMat = new MeshPhongMaterial();
		this.uvMat.uniforms = {};
		this.uvMat.onBeforeCompile = function(shader:Shader) {
			shader.vertexShader = 'attribute vec2 uv1;\n#define USE_LIGHTMAP\n#define LIGHTMAP_UV uv1\n' + shader.vertexShader.slice(0, - 1) + '	gl_Position = vec4((LIGHTMAP_UV - 0.5) * 2.0, 1.0, 1.0); }';
			const bodyStart = shader.fragmentShader.indexOf('void main() {');
			shader.fragmentShader = '#define USE_LIGHTMAP\n' + shader.fragmentShader.slice(0, bodyStart) + '	uniform sampler2D previousShadowMap;\n	uniform float averagingWindow;\n' + shader.fragmentShader.slice(bodyStart - 1, - 1) + '\nvec3 texelOld = texture2D(previousShadowMap, vLightMapUv).rgb;\ngl_FragColor.rgb = mix(texelOld, gl_FragColor.rgb, 1.0/averagingWindow);';
			shader.uniforms.previousShadowMap = {value: this.progressiveLightMap1.texture};
			shader.uniforms.averagingWindow = {value: 100};
			this.uvMat.uniforms = shader.uniforms;
			this.uvMat.userData.shader = shader;
			this.compiled = true;
		};
	}

	/**
	 * Sets these objects' materials' lightmaps and modifies their uv1's.
	 * @param {Object3D} objects An array of objects and lights to set up your lightmap.
	 */
	public function addObjectsToLightMap(objects:Array<Object3D>) {
		this.uv_boxes = [];
		const padding = 3 / this.res;
		for (ob in 0...objects.length) {
			const object = objects[ob];
			if (object.isLight) {
				this.scene.attach(object);
				continue;
			}
			if (!object.geometry.hasAttribute('uv')) {
				Sys.println('All lightmap objects need UVs!');
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
			this.uv_boxes.push({w: 1 + (padding * 2), h: 1 + (padding * 2), index: ob});
			this.lightMapContainers.push({basicMat: object.material, object: object});
			this.compiled = false;
		}
		const dimensions = Potpack.pack(this.uv_boxes);
		this.uv_boxes.forEach(function(box) {
			const uv1 = objects[box.index].geometry.getAttribute('uv').clone();
			for (i in 0...uv1.array.length) {
				if (i % uv1.itemSize == 0) {
					uv1.array[i] = (uv1.array[i] + box.x + padding) / dimensions.w;
				} else if (i % uv1.itemSize == 1) {
					uv1.array[i] = (uv1.array[i] + box.y + padding) / dimensions.h;
				}
			}
			objects[box.index].geometry.setAttribute('uv1', uv1);
			objects[box.index].geometry.getAttribute('uv1').needsUpdate = true;
		});
	}

	/**
	 * This function renders each mesh one at a time into their respective surface maps
	 * @param {Camera} camera Standard Rendering Camera
	 * @param {number} blendWindow When >1, samples will accumulate over time.
	 * @param {boolean} blurEdges  Whether to fix UV Edges via blurring
	 */
	public function update(camera:Camera, blendWindow:Int = 100, blurEdges:Bool = true) {
		if (this.blurringPlane == null) {
			return;
		}
		const oldTarget = this.renderer.getRenderTarget();
		this.blurringPlane.visible = blurEdges;
		for (l in 0...this.lightMapContainers.length) {
			this.lightMapContainers[l].object.oldScene = this.lightMapContainers[l].object.parent;
			this.scene.attach(this.lightMapContainers[l].object);
		}
		if (this.firstUpdate) {
			this.renderer.setRenderTarget(this.tinyTarget);
			this.renderer.render(this.scene, camera);
			this.firstUpdate = false;
		}
		for (l in 0...this.lightMapContainers.length) {
			this.uvMat.uniforms.averagingWindow = {value: blendWindow};
			this.lightMapContainers[l].object.material = this.uvMat;
			this.lightMapContainers[l].object.oldFrustumCulled = this.lightMapContainers[l].object.frustumCulled;
			this.lightMapContainers[l].object.frustumCulled = false;
		}
		const activeMap = this.buffer1Active ? this.progressiveLightMap1 : this.progressiveLightMap2;
		const inactiveMap = this.buffer1Active ? this.progressiveLightMap2 : this.progressiveLightMap1;
		this.renderer.setRenderTarget(activeMap);
		this.uvMat.uniforms.previousShadowMap = {value: inactiveMap.texture};
		this.blurringPlane.material.uniforms.previousShadowMap = {value: inactiveMap.texture};
		this.buffer1Active = !this.buffer1Active;
		this.renderer.render(this.scene, camera);
		for (l in 0...this.lightMapContainers.length) {
			this.lightMapContainers[l].object.frustumCulled = this.lightMapContainers[l].object.oldFrustumCulled;
			this.lightMapContainers[l].object.material = this.lightMapContainers[l].basicMat;
			this.lightMapContainers[l].object.oldScene.attach(this.lightMapContainers[l].object);
		}
		this.renderer.setRenderTarget(oldTarget);
	}

	/** DEBUG
	 * Draw the lightmap in the main scene.  Call this after adding the objects to it.
	 * @param {boolean} visible Whether the debug plane should be visible
	 * @param {Vector3} position Where the debug plane should be drawn
	*/
	public function showDebugLightmap(visible:Bool, position:Vector3 = null) {
		if (this.lightMapContainers.length == 0) {
			if (!this.warned) {
				Sys.println('Call this after adding the objects!');
				this.warned = true;
			}
			return;
		}
		if (this.labelMesh == null) {
			this.labelMaterial = new MeshBasicMaterial({map: this.progressiveLightMap1.texture, side: DoubleSide});
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

	/**
	 * INTERNAL Creates the Blurring Plane
	 * @param {number} res The square resolution of this object's lightMap.
	 * @param {WebGLRenderTexture} lightMap The lightmap to initialize the plane with.
	 */
	private function _initializeBlurPlane(res:Int, lightMap:WebGLRenderTarget = null) {
		const blurMaterial = new MeshBasicMaterial();
		blurMaterial.uniforms = {previousShadowMap: {value: null}, pixelOffset: {value: 1.0 / res}, polygonOffset: true, polygonOffsetFactor: -1, polygonOffsetUnits: 3.0};
		blurMaterial.onBeforeCompile = function(shader:Shader) {
			shader.vertexShader = '#define USE_UV\n' + shader.vertexShader.slice(0, - 1) + '	gl_Position = vec4((uv - 0.5) * 2.0, 1.0, 1.0); }';
			const bodyStart = shader.fragmentShader.indexOf('void main() {');
			shader.fragmentShader = '#define USE_UV\n' + shader.fragmentShader.slice(0, bodyStart) + '	uniform sampler2D previousShadowMap;\n	uniform float pixelOffset;\n' + shader.fragmentShader.slice(bodyStart - 1, - 1) + '	gl_FragColor.rgb = (texture2D(previousShadowMap, vUv + vec2( pixelOffset,  0.0        )).rgb + texture2D(previousShadowMap, vUv + vec2( 0.0        ,  pixelOffset)).rgb + texture2D(previousShadowMap, vUv + vec2( 0.0        , -pixelOffset)).rgb + texture2D(previousShadowMap, vUv + vec2(-pixelOffset,  0.0        )).rgb + texture2D(previousShadowMap, vUv + vec2( pixelOffset,  pixelOffset)).rgb + texture2D(previousShadowMap, vUv + vec2(-pixelOffset,  pixelOffset)).rgb + texture2D(previousShadowMap, vUv + vec2( pixelOffset, -pixelOffset)).rgb + texture2D(previousShadowMap, vUv + vec2(-pixelOffset, -pixelOffset)).rgb)/8.0;';
			shader.uniforms.previousShadowMap = {value: lightMap.texture};
			shader.uniforms.pixelOffset = {value: 0.5 / res};
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