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
import three.renderers.shaders.ShaderLib.VSM;

class WebGLShadowMap {

	private _frustum:Frustum;

	private _shadowMapSize:Vector2;
	private _viewportSize:Vector2;
	private _viewport:Vector4;

	private _depthMaterial:MeshDepthMaterial;
	private _distanceMaterial:MeshDistanceMaterial;

	private _materialCache:Map<String, Map<String, MeshDepthMaterial>>;

	private _maxTextureSize:Int;

	private shadowSide:Map<Int, Int>;

	private shadowMaterialVertical:ShaderMaterial;
	private shadowMaterialHorizontal:ShaderMaterial;

	private fullScreenTri:BufferGeometry;
	private fullScreenMesh:Mesh;

	private enabled:Bool;
	private autoUpdate:Bool;
	private needsUpdate:Bool;

	private type:Int;
	private _previousType:Int;

	public function new(renderer, objects, capabilities) {

		_frustum = new Frustum();

		_shadowMapSize = new Vector2();
		_viewportSize = new Vector2();
		_viewport = new Vector4();

		_depthMaterial = new MeshDepthMaterial( { depthPacking: RGBADepthPacking } );
		_distanceMaterial = new MeshDistanceMaterial();

		_materialCache = new Map();

		_maxTextureSize = capabilities.maxTextureSize;

		shadowSide = new Map<Int, Int>([
			[ FrontSide, BackSide ],
			[ BackSide, FrontSide ],
			[ DoubleSide, DoubleSide ]
		]);

		shadowMaterialVertical = new ShaderMaterial( {
			defines: {
				VSM_SAMPLES: 8
			},
			uniforms: {
				shadow_pass: { value: null },
				resolution: { value: new Vector2() },
				radius: { value: 4.0 }
			},
			vertexShader: VSM.vertex,
			fragmentShader: VSM.fragment
		} );

		shadowMaterialHorizontal = shadowMaterialVertical.clone();
		shadowMaterialHorizontal.defines.HORIZONTAL_PASS = 1;

		fullScreenTri = new BufferGeometry();
		fullScreenTri.setAttribute('position', new BufferAttribute(new Float32Array([ - 1, - 1, 0.5, 3, - 1, 0.5, - 1, 3, 0.5 ]), 3));
		fullScreenMesh = new Mesh(fullScreenTri, shadowMaterialVertical);

		enabled = false;
		autoUpdate = true;
		needsUpdate = false;

		type = PCFShadowMap;
		_previousType = type;
	}

	public function render(lights:Array<Dynamic>, scene:Dynamic, camera:Dynamic):Void {

		if ( !enabled ) return;
		if ( !autoUpdate && !needsUpdate ) return;

		if ( lights.length == 0 ) return;

		const currentRenderTarget = renderer.getRenderTarget();
		const activeCubeFace = renderer.getActiveCubeFace();
		const activeMipmapLevel = renderer.getActiveMipmapLevel();

		const _state = renderer.state;

		_state.setBlending(NoBlending);
		_state.buffers.color.setClear(1, 1, 1, 1);
		_state.buffers.depth.setTest(true);
		_state.setScissorTest(false);

		const toVSM = _previousType != VSMShadowMap && type == VSMShadowMap;
		const fromVSM = _previousType == VSMShadowMap && type != VSMShadowMap;

		for ( i in 0...lights.length ) {

			const light = lights[i];
			const shadow = light.shadow;

			if ( shadow == null ) {

				console.warn("THREE.WebGLShadowMap:", light, "has no shadow.");
				continue;

			}

			if ( !shadow.autoUpdate && !shadow.needsUpdate ) continue;

			_shadowMapSize.copy(shadow.mapSize);
			const shadowFrameExtents = shadow.getFrameExtents();
			_shadowMapSize.multiply(shadowFrameExtents);
			_viewportSize.copy(shadow.mapSize);

			if ( _shadowMapSize.x > _maxTextureSize || _shadowMapSize.y > _maxTextureSize ) {

				if ( _shadowMapSize.x > _maxTextureSize ) {

					_viewportSize.x = Std.int(_maxTextureSize / shadowFrameExtents.x);
					_shadowMapSize.x = _viewportSize.x * shadowFrameExtents.x;
					shadow.mapSize.x = _viewportSize.x;

				}

				if ( _shadowMapSize.y > _maxTextureSize ) {

					_viewportSize.y = Std.int(_maxTextureSize / shadowFrameExtents.y);
					_shadowMapSize.y = _viewportSize.y * shadowFrameExtents.y;
					shadow.mapSize.y = _viewportSize.y;

				}

			}

			if ( shadow.map == null || toVSM || fromVSM ) {

				const pars = ( type != VSMShadowMap ) ? { minFilter: NearestFilter, magFilter: NearestFilter } : {};

				if ( shadow.map != null ) {

					shadow.map.dispose();

				}

				shadow.map = new WebGLRenderTarget(_shadowMapSize.x, _shadowMapSize.y, pars);
				shadow.map.texture.name = light.name + ".shadowMap";

				shadow.camera.updateProjectionMatrix();

			}

			renderer.setRenderTarget(shadow.map);
			renderer.clear();

			const viewportCount = shadow.getViewportCount();

			for ( vp in 0...viewportCount ) {

				const viewport = shadow.getViewport(vp);

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

			if ( shadow.isPointLightShadow != true && type == VSMShadowMap ) {

				VSMPass(shadow, camera);

			}

			shadow.needsUpdate = false;

		}

		_previousType = type;
		needsUpdate = false;

		renderer.setRenderTarget(currentRenderTarget, activeCubeFace, activeMipmapLevel);

	}

	private function VSMPass(shadow, camera):Void {

		const geometry = objects.update(fullScreenMesh);

		if ( shadowMaterialVertical.defines.VSM_SAMPLES != shadow.blurSamples ) {

			shadowMaterialVertical.defines.VSM_SAMPLES = shadow.blurSamples;
			shadowMaterialHorizontal.defines.VSM_SAMPLES = shadow.blurSamples;

			shadowMaterialVertical.needsUpdate = true;
			shadowMaterialHorizontal.needsUpdate = true;

		}

		if ( shadow.mapPass == null ) {

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

	private function getDepthMaterial(object, material, light, type):MeshDepthMaterial {

		let result = null;

		const customMaterial = ( light.isPointLight == true ) ? object.customDistanceMaterial : object.customDepthMaterial;

		if ( customMaterial != null ) {

			result = customMaterial;

		} else {

			result = ( light.isPointLight == true ) ? _distanceMaterial : _depthMaterial;

			if ( ( renderer.localClippingEnabled && material.clipShadows == true && Std.is(material.clippingPlanes, Array) && material.clippingPlanes.length != 0 ) ||
				( material.displacementMap != null && material.displacementScale != 0 ) ||
				( material.alphaMap != null && material.alphaTest > 0 ) ||
				( material.map != null && material.alphaTest > 0 ) ) {

				const keyA = result.uuid;
				const keyB = material.uuid;

				var materialsForVariant = _materialCache.get(keyA);

				if ( materialsForVariant == null ) {

					materialsForVariant = new Map();
					_materialCache.set(keyA, materialsForVariant);

				}

				var cachedMaterial = materialsForVariant.get(keyB);

				if ( cachedMaterial == null ) {

					cachedMaterial = result.clone();
					materialsForVariant.set(keyB, cachedMaterial);
					material.addEventListener("dispose", onMaterialDispose);

				}

				result = cachedMaterial;

			}

		}

		result.visible = material.visible;
		result.wireframe = material.wireframe;

		if ( type == VSMShadowMap ) {

			result.side = ( material.shadowSide != null ) ? material.shadowSide : material.side;

		} else {

			result.side = ( material.shadowSide != null ) ? material.shadowSide : shadowSide.get(material.side);

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

		if ( light.isPointLight == true && result.isMeshDistanceMaterial == true ) {

			const materialProperties = renderer.properties.get(result);
			materialProperties.light = light;

		}

		return result;

	}

	private function renderObject(object, camera, shadowCamera, light, type):Void {

		if ( object.visible == false ) return;

		const visible = object.layers.test(camera.layers);

		if ( visible && ( object.isMesh || object.isLine || object.isPoints ) ) {

			if ( ( object.castShadow || ( object.receiveShadow && type == VSMShadowMap ) ) && ( ! object.frustumCulled || _frustum.intersectsObject(object) ) ) {

				object.modelViewMatrix.multiplyMatrices(shadowCamera.matrixWorldInverse, object.matrixWorld);

				const geometry = objects.update(object);
				const material = object.material;

				if ( Std.is(material, Array) ) {

					const groups = geometry.groups;

					for ( k in 0...groups.length ) {

						const group = groups[k];
						const groupMaterial = material[group.materialIndex];

						if ( groupMaterial != null && groupMaterial.visible ) {

							const depthMaterial = getDepthMaterial(object, groupMaterial, light, type);

							object.onBeforeShadow(renderer, object, camera, shadowCamera, geometry, depthMaterial, group);
							renderer.renderBufferDirect(shadowCamera, null, geometry, depthMaterial, object, group);
							object.onAfterShadow(renderer, object, camera, shadowCamera, geometry, depthMaterial, group);

						}

					}

				} else if ( material != null && material.visible ) {

					const depthMaterial = getDepthMaterial(object, material, light, type);

					object.onBeforeShadow(renderer, object, camera, shadowCamera, geometry, depthMaterial, null);
					renderer.renderBufferDirect(shadowCamera, null, geometry, depthMaterial, object, null);
					object.onAfterShadow(renderer, object, camera, shadowCamera, geometry, depthMaterial, null);

				}

			}

		}

		const children = object.children;

		for ( i in 0...children.length ) {

			renderObject(children[i], camera, shadowCamera, light, type);

		}

	}

	private function onMaterialDispose(event) {

		const material = event.target;
		material.removeEventListener("dispose", onMaterialDispose);

		for ( id in _materialCache.keys() ) {

			const cache = _materialCache.get(id);

			const uuid = event.target.uuid;

			if ( cache.exists(uuid) ) {

				const shadowMaterial = cache.get(uuid);
				shadowMaterial.dispose();
				cache.remove(uuid);

			}

		}

	}

}