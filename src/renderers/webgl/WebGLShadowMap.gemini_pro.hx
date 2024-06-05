import three.constants.FrontSide;
import three.constants.BackSide;
import three.constants.DoubleSide;
import three.constants.NearestFilter;
import three.constants.PCFShadowMap;
import three.constants.VSMShadowMap;
import three.constants.RGBADepthPacking;
import three.constants.NoBlending;
import three.renderers.WebGLRenderTarget;
import three.materials.MeshDepthMaterial;
import three.materials.MeshDistanceMaterial;
import three.materials.ShaderMaterial;
import three.core.BufferAttribute;
import three.core.BufferGeometry;
import three.objects.Mesh;
import three.math.Vector4;
import three.math.Vector2;
import three.math.Frustum;
import three.renderers.shaders.ShaderLib.vsm;

class WebGLShadowMap {
	public var enabled:Bool = false;
	public var autoUpdate:Bool = true;
	public var needsUpdate:Bool = false;
	public var type:Int = PCFShadowMap;
	private var _previousType:Int = type;
	private var _frustum:Frustum = new Frustum();
	private var _shadowMapSize:Vector2 = new Vector2();
	private var _viewportSize:Vector2 = new Vector2();
	private var _viewport:Vector4 = new Vector4();
	private var _depthMaterial:MeshDepthMaterial = new MeshDepthMaterial( { depthPacking : RGBADepthPacking } );
	private var _distanceMaterial:MeshDistanceMaterial = new MeshDistanceMaterial();
	private var _materialCache:Map<String, Map<String, MeshDepthMaterial | MeshDistanceMaterial>> = new Map();
	private var _maxTextureSize:Int;
	private var shadowSide:Map<Int, Int> = new Map([
		[FrontSide, BackSide],
		[BackSide, FrontSide],
		[DoubleSide, DoubleSide]
	]);
	private var shadowMaterialVertical:ShaderMaterial = new ShaderMaterial({
		defines: {
			VSM_SAMPLES: 8
		},
		uniforms: {
			shadow_pass: { value: null },
			resolution: { value: new Vector2() },
			radius: { value: 4.0 }
		},
		vertexShader: vsm.vertex,
		fragmentShader: vsm.fragment
	});
	private var shadowMaterialHorizontal:ShaderMaterial = shadowMaterialVertical.clone();
	private var fullScreenTri:BufferGeometry = new BufferGeometry();
	private var fullScreenMesh:Mesh;
	private var renderer:three.renderers.WebGLRenderer;
	private var objects:three.renderers.webgl.WebGLObjects;
	private var capabilities:three.renderers.WebGLCapabilities;

	public function new(renderer:three.renderers.WebGLRenderer, objects:three.renderers.webgl.WebGLObjects, capabilities:three.renderers.WebGLCapabilities) {
		this.renderer = renderer;
		this.objects = objects;
		this.capabilities = capabilities;
		_maxTextureSize = capabilities.maxTextureSize;
		shadowMaterialHorizontal.defines.HORIZONTAL_PASS = 1;
		fullScreenTri.setAttribute(
			'position',
			new BufferAttribute(
				new Float32Array( [ - 1, - 1, 0.5, 3, - 1, 0.5, - 1, 3, 0.5 ] ),
				3
			)
		);
		fullScreenMesh = new Mesh( fullScreenTri, shadowMaterialVertical );
	}

	public function render(lights:Array<three.lights.Light>, scene:three.scenes.Scene, camera:three.cameras.Camera) {
		if (!enabled) return;
		if (!autoUpdate && !needsUpdate) return;
		if (lights.length == 0) return;
		var currentRenderTarget = renderer.getRenderTarget();
		var activeCubeFace = renderer.getActiveCubeFace();
		var activeMipmapLevel = renderer.getActiveMipmapLevel();
		var _state = renderer.state;
		_state.setBlending(NoBlending);
		_state.buffers.color.setClear(1, 1, 1, 1);
		_state.buffers.depth.setTest(true);
		_state.setScissorTest(false);
		var toVSM = _previousType != VSMShadowMap && type == VSMShadowMap;
		var fromVSM = _previousType == VSMShadowMap && type != VSMShadowMap;
		for (i in 0...lights.length) {
			var light = lights[i];
			var shadow = light.shadow;
			if (shadow == null) {
				console.warn("THREE.WebGLShadowMap:", light, "has no shadow.");
				continue;
			}
			if (!shadow.autoUpdate && !shadow.needsUpdate) continue;
			_shadowMapSize.copy(shadow.mapSize);
			var shadowFrameExtents = shadow.getFrameExtents();
			_shadowMapSize.multiply(shadowFrameExtents);
			_viewportSize.copy(shadow.mapSize);
			if (_shadowMapSize.x > _maxTextureSize || _shadowMapSize.y > _maxTextureSize) {
				if (_shadowMapSize.x > _maxTextureSize) {
					_viewportSize.x = Math.floor(_maxTextureSize / shadowFrameExtents.x);
					_shadowMapSize.x = _viewportSize.x * shadowFrameExtents.x;
					shadow.mapSize.x = _viewportSize.x;
				}
				if (_shadowMapSize.y > _maxTextureSize) {
					_viewportSize.y = Math.floor(_maxTextureSize / shadowFrameExtents.y);
					_shadowMapSize.y = _viewportSize.y * shadowFrameExtents.y;
					shadow.mapSize.y = _viewportSize.y;
				}
			}
			if (shadow.map == null || toVSM || fromVSM) {
				var pars = type != VSMShadowMap ? { minFilter : NearestFilter, magFilter : NearestFilter } : {};
				if (shadow.map != null) {
					shadow.map.dispose();
				}
				shadow.map = new WebGLRenderTarget(_shadowMapSize.x, _shadowMapSize.y, pars);
				shadow.map.texture.name = light.name + ".shadowMap";
				shadow.camera.updateProjectionMatrix();
			}
			renderer.setRenderTarget(shadow.map);
			renderer.clear();
			var viewportCount = shadow.getViewportCount();
			for (vp in 0...viewportCount) {
				var viewport = shadow.getViewport(vp);
				_viewport.set(
					_viewportSize.x * viewport.x,
					_viewportSize.y * viewport.y,
					_viewportSize.x * viewport.z,
					_viewportSize.y * viewport.w
				);
				_state.viewport(_viewport);
				shadow.updateMatrices(light, vp);
				_frustum = shadow.getFrustum();
				renderObject(scene, camera, shadow.camera, light, type);
			}
			if (shadow.isPointLightShadow != true && type == VSMShadowMap) {
				VSMPass(shadow, camera);
			}
			shadow.needsUpdate = false;
		}
		_previousType = type;
		needsUpdate = false;
		renderer.setRenderTarget(currentRenderTarget, activeCubeFace, activeMipmapLevel);
	}

	private function VSMPass(shadow:three.lights.LightShadow, camera:three.cameras.Camera) {
		var geometry = objects.update(fullScreenMesh);
		if (shadowMaterialVertical.defines.VSM_SAMPLES != shadow.blurSamples) {
			shadowMaterialVertical.defines.VSM_SAMPLES = shadow.blurSamples;
			shadowMaterialHorizontal.defines.VSM_SAMPLES = shadow.blurSamples;
			shadowMaterialVertical.needsUpdate = true;
			shadowMaterialHorizontal.needsUpdate = true;
		}
		if (shadow.mapPass == null) {
			shadow.mapPass = new WebGLRenderTarget(_shadowMapSize.x, _shadowMapSize.y);
		}
		shadowMaterialVertical.uniforms.shadow_pass.value = shadow.map.texture;
		shadowMaterialVertical.uniforms.resolution.value = shadow.mapSize;
		shadowMaterialVertical.uniforms.radius.value = shadow.radius;
		renderer.setRenderTarget(shadow.mapPass);
		renderer.clear();
		renderer.renderBufferDirect(camera, null, geometry, shadowMaterialVertical, fullScreenMesh, null);
		shadowMaterialHorizontal.uniforms.shadow_pass.value = shadow.mapPass.texture;
		shadowMaterialHorizontal.uniforms.resolution.value = shadow.mapSize;
		shadowMaterialHorizontal.uniforms.radius.value = shadow.radius;
		renderer.setRenderTarget(shadow.map);
		renderer.clear();
		renderer.renderBufferDirect(camera, null, geometry, shadowMaterialHorizontal, fullScreenMesh, null);
	}

	private function getDepthMaterial(object:three.core.Object3D, material:three.materials.Material, light:three.lights.Light, type:Int):MeshDepthMaterial | MeshDistanceMaterial {
		var result:MeshDepthMaterial | MeshDistanceMaterial = null;
		var customMaterial = light.isPointLight ? object.customDistanceMaterial : object.customDepthMaterial;
		if (customMaterial != null) {
			result = customMaterial;
		} else {
			result = light.isPointLight ? _distanceMaterial : _depthMaterial;
			if (renderer.localClippingEnabled && material.clipShadows && Std.isOfType(material.clippingPlanes, Array) && material.clippingPlanes.length != 0 || material.displacementMap && material.displacementScale != 0 || material.alphaMap && material.alphaTest > 0 || material.map && material.alphaTest > 0) {
				var keyA = result.uuid;
				var keyB = material.uuid;
				var materialsForVariant = _materialCache.get(keyA);
				if (materialsForVariant == null) {
					materialsForVariant = new Map();
					_materialCache.set(keyA, materialsForVariant);
				}
				var cachedMaterial = materialsForVariant.get(keyB);
				if (cachedMaterial == null) {
					cachedMaterial = result.clone();
					materialsForVariant.set(keyB, cachedMaterial);
					material.addEventListener("dispose", onMaterialDispose);
				}
				result = cachedMaterial;
			}
		}
		result.visible = material.visible;
		result.wireframe = material.wireframe;
		if (type == VSMShadowMap) {
			result.side = material.shadowSide != null ? material.shadowSide : material.side;
		} else {
			result.side = material.shadowSide != null ? material.shadowSide : shadowSide.get(material.side);
		}
		result.alphaMap = material.alphaMap;
		result.alphaTest = material.alphaTest;
		result.map = material.map;
		result.clipShadows = material.clipShadows;
		result.clippingPlanes = material.clippingPlanes;
		result.clipIntersection = material.clipIntersection;
		result.displacementMap = material.displacementMap;
		result.displacementScale = material.displacementScale;
		result.displacementBias = material.displacementBias;
		result.wireframeLinewidth = material.wireframeLinewidth;
		result.linewidth = material.linewidth;
		if (light.isPointLight && result.isMeshDistanceMaterial) {
			var materialProperties = renderer.properties.get(result);
			materialProperties.light = light;
		}
		return result;
	}

	private function renderObject(object:three.core.Object3D, camera:three.cameras.Camera, shadowCamera:three.cameras.Camera, light:three.lights.Light, type:Int) {
		if (!object.visible) return;
		var visible = object.layers.test(camera.layers);
		if (visible && (object.isMesh || object.isLine || object.isPoints)) {
			if ((object.castShadow || (object.receiveShadow && type == VSMShadowMap)) && (!object.frustumCulled || _frustum.intersectsObject(object))) {
				object.modelViewMatrix.multiplyMatrices(shadowCamera.matrixWorldInverse, object.matrixWorld);
				var geometry = objects.update(object);
				var material = object.material;
				if (Std.isOfType(material, Array)) {
					var groups = geometry.groups;
					for (k in 0...groups.length) {
						var group = groups[k];
						var groupMaterial = material[group.materialIndex];
						if (groupMaterial != null && groupMaterial.visible) {
							var depthMaterial = getDepthMaterial(object, groupMaterial, light, type);
							object.onBeforeShadow(renderer, object, camera, shadowCamera, geometry, depthMaterial, group);
							renderer.renderBufferDirect(shadowCamera, null, geometry, depthMaterial, object, group);
							object.onAfterShadow(renderer, object, camera, shadowCamera, geometry, depthMaterial, group);
						}
					}
				} else if (material.visible) {
					var depthMaterial = getDepthMaterial(object, material, light, type);
					object.onBeforeShadow(renderer, object, camera, shadowCamera, geometry, depthMaterial, null);
					renderer.renderBufferDirect(shadowCamera, null, geometry, depthMaterial, object, null);
					object.onAfterShadow(renderer, object, camera, shadowCamera, geometry, depthMaterial, null);
				}
			}
		}
		var children = object.children;
		for (i in 0...children.length) {
			renderObject(children[i], camera, shadowCamera, light, type);
		}
	}

	private function onMaterialDispose(event:three.events.Event) {
		var material = event.target;
		material.removeEventListener("dispose", onMaterialDispose);
		for (id in _materialCache.keys()) {
			var cache = _materialCache.get(id);
			var uuid = event.target.uuid;
			if (cache.exists(uuid)) {
				var shadowMaterial = cache.get(uuid);
				shadowMaterial.dispose();
				cache.remove(uuid);
			}
		}
	}
}