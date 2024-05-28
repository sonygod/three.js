import js.Browser.Window;
import js.three.*;

class WebGLShadowMap {
    var _frustum:Frustum;
    var _shadowMapSize:Vector2;
    var _viewportSize:Vector2;
    var _viewport:Vector4;
    var _depthMaterial:MeshDepthMaterial;
    var _distanceMaterial:MeshDistanceMaterial;
    var _materialCache:Map<String, Map<String, Material>>;
    var _maxTextureSize:Int;
    var shadowSide:Dynamic;
    var shadowMaterialVertical:ShaderMaterial;
    var shadowMaterialHorizontal:ShaderMaterial;
    var fullScreenTri:BufferGeometry;
    var fullScreenMesh:Mesh;
    var scope:Dynamic;

    public function new(renderer:WebGLRenderer, objects:Object3D, capabilities:WebGLCapabilities) {
        _frustum = new Frustum();
        _shadowMapSize = new Vector2();
        _viewportSize = new Vector2();
        _viewport = new Vector4();
        _depthMaterial = new MeshDepthMaterial({ depthPacking: RGBADepthPacking });
        _distanceMaterial = new MeshDistanceMaterial();
        _materialCache = new Map();
        _maxTextureSize = capabilities.maxTextureSize;
        shadowSide = {
            FrontSide: BackSide,
            BackSide: FrontSide,
            DoubleSide: DoubleSide
        };
        shadowMaterialVertical = new ShaderMaterial({
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
        shadowMaterialHorizontal = shadowMaterialVertical.clone();
        shadowMaterialHorizontal.defines.HORIZONTAL_PASS = 1;
        fullScreenTri = new BufferGeometry();
        fullScreenTri.setAttribute('position', new BufferAttribute(new Float32Array([-1, -1, 0.5, 3, -1, 0.5, -1, 3, 0.5]), 3));
        fullScreenMesh = new Mesh(fullScreenTri, shadowMaterialVertical);
        scope = this;
        this.enabled = false;
        this.autoUpdate = true;
        this.needsUpdate = false;
        this.type = PCFShadowMap;
        _previousType = this.type;
    }

    public function render(lights:Array<Light>, scene:Scene, camera:Camera) {
        if (!scope.enabled) return;
        if (!scope.autoUpdate && !scope.needsUpdate) return;
        if (lights.length == 0) return;

        var currentRenderTarget = renderer.getRenderTarget();
        var activeCubeFace = renderer.getActiveCubeFace();
        var activeMipmapLevel = renderer.getActiveMipmapLevel();
        var _state = renderer.state;

        // Set GL state for depth map.
        _state.setBlending(NoBlending);
        _state.buffers.color.setClear(1, 1, 1, 1);
        _state.buffers.depth.setTest(true);
        _state.setScissorTest(false);

        // check for shadow map type changes
        var toVSM = (_previousType != VSMShadowMap && this.type == VSMShadowMap);
        var fromVSM = (_previousType == VSMShadowMap && this.type != VSMShadowMap);

        // render depth map
        for (i in 0...lights.length) {
            var light = lights[i];
            var shadow = light.shadow;
            if (shadow == null) {
                Window.console.warn('THREE.WebGLShadowMap:', light, 'has no shadow.');
                continue;
            }
            if (!shadow.autoUpdate && !shadow.needsUpdate) continue;

            _shadowMapSize.copy(shadow.mapSize);
            var shadowFrameExtents = shadow.getFrameExtents();
            _shadowMapSize.multiply(shadowFrameExtents);
            _viewportSize.copy(shadow.mapSize);

            if (_shadowMapSize.x > _maxTextureSize || _shadowMapSize.y > _maxTextureSize) {
                if (_shadowMapSize.x > _maxTextureSize) {
                    _viewportSize.x = Std.int(_maxTextureSize / shadowFrameExtents.x);
                    _shadowMapSize.x = _viewportSize.x * shadowFrameExtents.x;
                    shadow.mapSize.x = _viewportSize.x;
                }
                if (_shadowMapSize.y > _maxTextureSize) {
                    _viewportSize.y = Std.int(_maxTextureSize / shadowFrameExtents.y);
                    _shadowMapSize.y = _viewportSize.y * shadowFrameExtents.y;
                    shadow.mapSize.y = _viewportSize.y;
                }
            }

            if (shadow.map == null || toVSM || fromVSM) {
                var pars = if (this.type != VSMShadowMap) {
                    { minFilter: NearestFilter, magFilter: NearestFilter }
                } else {
                    null
                };
                if (shadow.map != null) {
                    shadow.map.dispose();
                }
                shadow.map = new WebGLRenderTarget(_shadowMapSize.x, _shadowMapSize.y, pars);
                shadow.map.texture.name = light.name + '.shadowMap';
                shadow.camera.updateProjectionMatrix();
            }

            renderer.setRenderTarget(shadow.map);
            renderer.clear();

            var viewportCount = shadow.getViewportCount();
            for (vp in 0...viewportCount) {
                var viewport = shadow.getViewport(vp);
                _viewport.set(_viewportSize.x * viewport.x, _viewportSize.y * viewport.y, _viewportSize.x * viewport.z, _viewportSize.y * viewport.w);
                _state.viewport(_viewport);
                shadow.updateMatrices(light, vp);
                _frustum = shadow.getFrustum();
                renderObject(scene, camera, shadow.camera, light, this.type);
            }

            // do blur pass for VSM
            if (!shadow.isPointLightShadow && this.type == VSMShadowMap) {
                VSMPass(shadow, camera);
            }

            shadow.needsUpdate = false;
        }

        _previousType = this.type;
        scope.needsUpdate = false;
        renderer.setRenderTarget(currentRenderTarget, activeCubeFace, activeMipmapLevel);
    }

    function VSMPass(shadow:LightShadow, camera:Camera) {
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

        // vertical pass
        shadowMaterialVertical.uniforms.shadow_pass.value = shadow.map.texture;
        shadowMaterialVertical.uniforms.resolution.value = shadow.mapSize;
        shadowMaterialVertical.uniforms.radius.value = shadow.radius;
        renderer.setRenderTarget(shadow.mapPass);
        renderer.clear();
        renderer.renderBufferDirect(camera, null, geometry, shadowMaterialVertical, fullScreenMesh, null);

        // horizontal pass
        shadowMaterialHorizontal.uniforms.shadow_pass.value = shadow.mapPass.texture;
        shadowMaterialHorizontal.uniforms.resolution.value = shadow.mapSize;
        shadowMaterialHorizontal.uniforms.radius.value = shadow.radius;
        renderer.setRenderTarget(shadow.map);
        renderer.clear();
        renderer.renderBufferDirect(camera, null, geometry, shadowMaterialHorizontal, fullScreenMesh, null);
    }

    function getDepthMaterial(object:Object3D, material:Material, light:Light, type:Int) {
        var result:Material = null;
        var customMaterial = if (light.isPointLight) object.customDistanceMaterial else object.customDepthMaterial;
        if (customMaterial != null) {
            result = customMaterial;
        } else {
            result = if (light.isPointLight) _distanceMaterial else _depthMaterial;
            if ((renderer.localClippingEnabled && material.clipShadows && material.clippingPlanes.length != 0) ||
                (material.displacementMap && material.displacementScale != 0) ||
                (material.alphaMap && material.alphaTest > 0) ||
                (material.map && material.alphaTest > 0)) {
                // in this case we need a unique material instance reflecting the
                // appropriate state
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
                    material.addEventListener('dispose', onMaterialDispose);
                }
                result = cachedMaterial;
            }
        }
        result.visible = material.visible;
        result.wireframe = material.wireframe;
        if (type == VSMShadowMap) {
            result.side = if (material.shadowSide != null) material.shadowSide else material.side;
        } else {
            result.side = if (material.shadowSide != null) material.shadowSide else shadowSide[material.side];
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

    function renderObject(object:Object3D, camera:Camera, shadowCamera:Camera, light:Light, type:Int) {
        if (!object.visible) return;
        var visible = object.layers.test(camera.layers);
        if (visible && (object is Mesh || object is Line || object is Points)) {
            if ((object.castShadow || (object.receiveShadow && type == VSMShadowMap)) && (!object.frustumCulled || _frustum.intersectsObject(object))) {
                object.modelViewMatrix.multiplyMatrices(shadowCamera.matrixWorldInverse, object.matrixWorld);
                var geometry = objects.update(object);
                var material = object.material;
                if (material is Array<Material>) {
                    var groups = geometry.groups;
                    for (k in 0...groups.length) {
                        var group = groups[k];
                        var groupMaterial = material[group.materialIndex];
                        if (groupMaterial && groupMaterial.visible) {
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

    function onMaterialDispose(event:Dynamic) {
        var material = event.target;
        material.removeEventListener('dispose', onMaterialDispose);
        // make sure to remove the unique distance/depth materials used for shadow map rendering
        for (id in _materialCache.keys()) {
            var cache = _materialCache.get(id);
            var uuid = material.uuid;
            if (cache.exists(uuid)) {
                var shadowMaterial = cache.get(uuid);
                shadowMaterial.dispose();
                cache.remove(uuid);
            }
        }
    }
}