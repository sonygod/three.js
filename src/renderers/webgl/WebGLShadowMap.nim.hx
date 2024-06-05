import three.js.src.constants.FrontSide;
import three.js.src.constants.BackSide;
import three.js.src.constants.DoubleSide;
import three.js.src.constants.NearestFilter;
import three.js.src.constants.PCFShadowMap;
import three.js.src.constants.VSMShadowMap;
import three.js.src.constants.RGBADepthPacking;
import three.js.src.constants.NoBlending;
import three.js.src.renderers.WebGLRenderTarget;
import three.js.src.materials.MeshDepthMaterial;
import three.js.src.materials.MeshDistanceMaterial;
import three.js.src.materials.ShaderMaterial;
import three.js.src.core.BufferAttribute;
import three.js.src.core.BufferGeometry;
import three.js.src.objects.Mesh;
import three.js.src.math.Vector4;
import three.js.src.math.Vector2;
import three.js.src.math.Frustum;

import three.js.src.shaders.ShaderLib.vsm.vertex;
import three.js.src.shaders.ShaderLib.vsm.fragment;

class WebGLShadowMap {
    var _frustum: Frustum;
    var _shadowMapSize: Vector2;
    var _viewportSize: Vector2;
    var _viewport: Vector4;
    var _depthMaterial: MeshDepthMaterial;
    var _distanceMaterial: MeshDistanceMaterial;
    var _materialCache: Dynamic;
    var _maxTextureSize: Int;
    var shadowSide: Dynamic;
    var shadowMaterialVertical: ShaderMaterial;
    var shadowMaterialHorizontal: ShaderMaterial;
    var fullScreenTri: BufferGeometry;
    var fullScreenMesh: Mesh;
    var scope: Dynamic;
    var enabled: Bool;
    var autoUpdate: Bool;
    var needsUpdate: Bool;
    var type: Int;
    var _previousType: Int;

    public function new(renderer: Dynamic, objects: Dynamic, capabilities: Dynamic) {
        _frustum = new Frustum();
        _shadowMapSize = new Vector2();
        _viewportSize = new Vector2();
        _viewport = new Vector4();
        _depthMaterial = new MeshDepthMaterial({ depthPacking: RGBADepthPacking });
        _distanceMaterial = new MeshDistanceMaterial();
        _materialCache = {};
        _maxTextureSize = capabilities.maxTextureSize;
        shadowSide = { [ FrontSide ]: BackSide, [ BackSide ]: FrontSide, [ DoubleSide ]: DoubleSide };
        shadowMaterialVertical = new ShaderMaterial({
            defines: {
                VSM_SAMPLES: 8
            },
            uniforms: {
                shadow_pass: { value: null },
                resolution: { value: new Vector2() },
                radius: { value: 4.0 }
            },
            vertexShader: vertex,
            fragmentShader: fragment
        });
        shadowMaterialHorizontal = shadowMaterialVertical.clone();
        shadowMaterialHorizontal.defines.HORIZONTAL_PASS = 1;
        fullScreenTri = new BufferGeometry();
        fullScreenTri.setAttribute('position', new BufferAttribute(new Float32Array([-1, -1, 0.5, 3, -1, 0.5, -1, 3, 0.5]), 3));
        fullScreenMesh = new Mesh(fullScreenTri, shadowMaterialVertical);
        scope = this;
        enabled = false;
        autoUpdate = true;
        needsUpdate = false;
        type = PCFShadowMap;
        _previousType = this.type;
    }

    public function render(lights: Array<Dynamic>, scene: Dynamic, camera: Dynamic): Void {
        if (scope.enabled === false) return;
        if (scope.autoUpdate === false && scope.needsUpdate === false) return;
        if (lights.length === 0) return;
        var currentRenderTarget = renderer.getRenderTarget();
        var activeCubeFace = renderer.getActiveCubeFace();
        var activeMipmapLevel = renderer.getActiveMipmapLevel();
        var _state = renderer.state;
        _state.setBlending(NoBlending);
        _state.buffers.color.setClear(1, 1, 1, 1);
        _state.buffers.depth.setTest(true);
        _state.setScissorTest(false);
        var toVSM = (_previousType !== VSMShadowMap && this.type === VSMShadowMap);
        var fromVSM = (_previousType === VSMShadowMap && this.type !== VSMShadowMap);
        for (i in 0...lights.length) {
            var light = lights[i];
            var shadow = light.shadow;
            if (shadow === undefined) {
                trace('THREE.WebGLShadowMap:', light, 'has no shadow.');
                continue;
            }
            if (shadow.autoUpdate === false && shadow.needsUpdate === false) continue;
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
            if (shadow.map === null || toVSM === true || fromVSM === true) {
                var pars = (this.type !== VSMShadowMap) ? { minFilter: NearestFilter, magFilter: NearestFilter } : {};
                if (shadow.map !== null) {
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
            if (shadow.isPointLightShadow !== true && this.type === VSMShadowMap) {
                VSMPass(shadow, camera);
            }
            shadow.needsUpdate = false;
        }
        _previousType = this.type;
        scope.needsUpdate = false;
        renderer.setRenderTarget(currentRenderTarget, activeCubeFace, activeMipmapLevel);
    }

    public function VSMPass(shadow: Dynamic, camera: Dynamic): Void {
        var geometry = objects.update(fullScreenMesh);
        if (shadowMaterialVertical.defines.VSM_SAMPLES !== shadow.blurSamples) {
            shadowMaterialVertical.defines.VSM_SAMPLES = shadow.blurSamples;
            shadowMaterialHorizontal.defines.VSM_SAMPLES = shadow.blurSamples;
            shadowMaterialVertical.needsUpdate = true;
            shadowMaterialHorizontal.needsUpdate = true;
        }
        if (shadow.mapPass === null) {
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

    public function getDepthMaterial(object: Dynamic, material: Dynamic, light: Dynamic, type: Int): Dynamic {
        var result = null;
        var customMaterial = (light.isPointLight === true) ? object.customDistanceMaterial : object.customDepthMaterial;
        if (customMaterial !== undefined) {
            result = customMaterial;
        } else {
            result = (light.isPointLight === true) ? _distanceMaterial : _depthMaterial;
            if ((renderer.localClippingEnabled && material.clipShadows === true && Array.isArray(material.clippingPlanes) && material.clippingPlanes.length !== 0) ||
                (material.displacementMap && material.displacementScale !== 0) ||
                (material.alphaMap && material.alphaTest > 0) ||
                (material.map && material.alphaTest > 0)) {
                result = result.clone();
                material.addEventListener('dispose', onMaterialDispose);
            }
        }
        result.visible = material.visible;
        result.wireframe = material.wireframe;
        if (type === VSMShadowMap) {
            result.side = (material.shadowSide !== null) ? material.shadowSide : material.side;
        } else {
            result.side = (material.shadowSide !== null) ? material.shadowSide : shadowSide[material.side];
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
        if (light.isPointLight === true && result.isMeshDistanceMaterial === true) {
            var materialProperties = renderer.properties.get(result);
            materialProperties.light = light;
        }
        return result;
    }

    public function renderObject(object: Dynamic, camera: Dynamic, shadowCamera: Dynamic, light: Dynamic, type: Int): Void {
        if (object.visible === false) return;
        var visible = object.layers.test(camera.layers);
        if (visible && (object.isMesh || object.isLine || object.isPoints)) {
            if ((object.castShadow || (object.receiveShadow && type === VSMShadowMap)) && (!object.frustumCulled || _frustum.intersectsObject(object))) {
                object.modelViewMatrix.multiplyMatrices(shadowCamera.matrixWorldInverse, object.matrixWorld);
                var geometry = objects.update(object);
                var material = object.material;
                if (Array.isArray(material)) {
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

    public function onMaterialDispose(event: Dynamic): Void {
        var material = event.target;
        material.removeEventListener('dispose', onMaterialDispose);
        for (id in _materialCache) {
            var cache = _materialCache[id];
            var uuid = event.target.uuid;
            if (uuid in cache) {
                var shadowMaterial = cache[uuid];
                shadowMaterial.dispose();
                delete cache[uuid];
            }
        }
    }
}