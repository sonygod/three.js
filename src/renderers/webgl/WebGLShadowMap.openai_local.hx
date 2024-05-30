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

import shaders.ShaderLib.VSMGlsl;

class WebGLShadowMap {
    
    private var _frustum:Frustum;
    private var _shadowMapSize:Vector2;
    private var _viewportSize:Vector2;
    private var _viewport:Vector4;
    private var _depthMaterial:MeshDepthMaterial;
    private var _distanceMaterial:MeshDistanceMaterial;
    private var _materialCache:Map<String, Map<String, ShaderMaterial>>;
    private var _maxTextureSize:Int;
    private var shadowSide:Map<Int, Int>;
    private var shadowMaterialVertical:ShaderMaterial;
    private var shadowMaterialHorizontal:ShaderMaterial;
    private var fullScreenTri:BufferGeometry;
    private var fullScreenMesh:Mesh;
    private var renderer:Dynamic;
    private var objects:Dynamic;
    private var capabilities:Dynamic;
    private var scope:Dynamic;
    private var _previousType:Int;

    public var enabled:Bool;
    public var autoUpdate:Bool;
    public var needsUpdate:Bool;
    public var type:Int;

    public function new(renderer:Dynamic, objects:Dynamic, capabilities:Dynamic) {
        this.renderer = renderer;
        this.objects = objects;
        this.capabilities = capabilities;

        _frustum = new Frustum();
        _shadowMapSize = new Vector2();
        _viewportSize = new Vector2();
        _viewport = new Vector4();

        _depthMaterial = new MeshDepthMaterial({depthPacking: RGBADepthPacking});
        _distanceMaterial = new MeshDistanceMaterial();
        _materialCache = new Map();

        _maxTextureSize = capabilities.maxTextureSize;

        shadowSide = new Map();
        shadowSide.set(FrontSide, BackSide);
        shadowSide.set(BackSide, FrontSide);
        shadowSide.set(DoubleSide, DoubleSide);

        shadowMaterialVertical = new ShaderMaterial({
            defines: {
                VSM_SAMPLES: 8
            },
            uniforms: {
                shadow_pass: { value: null },
                resolution: { value: new Vector2() },
                radius: { value: 4.0 }
            },
            vertexShader: VSMGlsl.vertex,
            fragmentShader: VSMGlsl.fragment
        });

        shadowMaterialHorizontal = shadowMaterialVertical.clone();
        shadowMaterialHorizontal.defines.HORIZONTABAL_PASS = 1;

        fullScreenTri = new BufferGeometry();
        fullScreenTri.setAttribute(
            'position',
            new BufferAttribute(new Float32Array([ -1, -1, 0.5, 3, -1, 0.5, -1, 3, 0.5 ]), 3)
        );

        fullScreenMesh = new Mesh(fullScreenTri, shadowMaterialVertical);

        scope = this;

        this.enabled = false;
        this.autoUpdate = true;
        this.needsUpdate = false;
        this.type = PCFShadowMap;
        _previousType = this.type;
    }

    public function render(lights:Array<Dynamic>, scene:Dynamic, camera:Dynamic):Void {
        if (!scope.enabled) return;
        if (!scope.autoUpdate && !scope.needsUpdate) return;
        if (lights.length == 0) return;

        var currentRenderTarget = renderer.getRenderTarget();
        var activeCubeFace = renderer.getActiveCubeFace();
        var activeMipmapLevel = renderer.getActiveMipmapLevel();
        var _state = renderer.state;

        _state.setBlending(NoBlending);
        _state.buffers.color.setClear(1, 1, 1, 1);
        _state.buffers.depth.setTest(true);
        _state.setScissorTest(false);

        var toVSM = (_previousType != VSMShadowMap && this.type == VSMShadowMap);
        var fromVSM = (_previousType == VSMShadowMap && this.type != VSMShadowMap);

        for (i in 0...lights.length) {
            var light = lights[i];
            var shadow = light.shadow;
            if (shadow == null) {
                trace('THREE.WebGLShadowMap: $light has no shadow.');
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
                var pars = if (this.type != VSMShadowMap) { minFilter: NearestFilter, magFilter: NearestFilter } else {};
                if (shadow.map != null) shadow.map.dispose();
                shadow.map = new WebGLRenderTarget(_shadowMapSize.x, _shadowMapSize.y, pars);
                shadow.map.texture.name = light.name + '.shadowMap';
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
                renderObject(scene, camera, shadow.camera, light, this.type);
            }

            if (!shadow.isPointLightShadow && this.type == VSMShadowMap) {
                VSMPass(shadow, camera);
            }

            shadow.needsUpdate = false;
        }

        _previousType = this.type;
        scope.needsUpdate = false;
        renderer.setRenderTarget(currentRenderTarget, activeCubeFace, activeMipmapLevel);
    }

    private function VSMPass(shadow:Dynamic, camera:Dynamic):Void {
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

    private function getDepthMaterial(object:Dynamic, material:Dynamic, light:Dynamic, type:Int):Dynamic {
        var result:Dynamic = null;
        var customMaterial = if (light.isPointLight) object.customDistanceMaterial else object.customDepthMaterial;
        if (customMaterial != null) {
            result = customMaterial;
        } else {
            result = if (light.isPointLight) _distanceMaterial else _depthMaterial;
            if ((renderer.localClippingEnabled && material.clipShadows && material.clippingPlanes != null && material.clippingPlanes.length > 0) ||
                (material.displacementMap != null && material.displacementScale != 0) ||
                (material.alphaMap != null && material.alphaTest > 0) ||
                (material.map != null && material.alphaTest > 0)) {
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
        result.side = if (type == VSMShadowMap) (material.shadowSide != null) ? material.shadowSide : material.side else (material.shadowSide != null) ? material.shadowSide : shadowSide.get(material.side);
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

    private function renderObject(object:Dynamic, camera:Dynamic, shadowCamera:Dynamic, light:Dynamic, type:Int):Void {
        if (!object.visible) return;

        var visible = object.layers.test(camera.layers);
        if (visible && (object.isMesh || object.isLine || object.isPoints)) {
            if ((object.castShadow || (object.receiveShadow && type == VSMShadowMap)) && (!object.frustumCulled || _frustum.intersectsObject(object))) {
                object.modelViewMatrix.multiplyMatrices(shadowCamera.matrixWorldInverse, object.matrixWorld);
                var geometry = objects.update(object);
                var material = object.material;
                if (Std.is(material, Array)) {
                    var groups = geometry.groups;
                    for (group in groups) {
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

        for (child in object.children) {
            renderObject(child, camera, shadowCamera, light, type);
        }
    }

    private function onMaterialDispose(event:Dynamic):Void {
        var material = event.target;
        material.removeEventListener('dispose', onMaterialDispose);
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