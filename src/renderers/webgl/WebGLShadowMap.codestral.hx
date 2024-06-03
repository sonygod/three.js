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

import three.shaders.ShaderLib.vsm;

class WebGLShadowMap {
    var _frustum:Frustum = new Frustum();

    var _shadowMapSize:Vector2 = new Vector2();
    var _viewportSize:Vector2 = new Vector2();

    var _viewport:Vector4 = new Vector4();

    var _depthMaterial:MeshDepthMaterial = new MeshDepthMaterial({depthPacking: RGBADepthPacking});
    var _distanceMaterial:MeshDistanceMaterial = new MeshDistanceMaterial();

    var _materialCache:haxe.ds.StringMap = new haxe.ds.StringMap();

    var _maxTextureSize:Int;

    var shadowSide:haxe.ds.IntMap = new haxe.ds.IntMap();

    var shadowMaterialVertical:ShaderMaterial;
    var shadowMaterialHorizontal:ShaderMaterial;
    var fullScreenTri:BufferGeometry;
    var fullScreenMesh:Mesh;
    var scope:WebGLShadowMap;

    public function new(renderer:Renderer, objects:Objects, capabilities:Capabilities) {
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
            vertexShader: vsm.vertex,
            fragmentShader: vsm.fragment
        });

        shadowMaterialHorizontal = shadowMaterialVertical.clone();
        shadowMaterialHorizontal.defines["HORIZONTAL_PASS"] = 1;

        fullScreenTri = new BufferGeometry();
        fullScreenTri.setAttribute(
            'position',
            new BufferAttribute(
                new Float32Array([-1, -1, 0.5, 3, -1, 0.5, -1, 3, 0.5]),
                3
            )
        );

        fullScreenMesh = new Mesh(fullScreenTri, shadowMaterialVertical);

        scope = this;

        this.enabled = false;

        this.autoUpdate = true;
        this.needsUpdate = false;

        this.type = PCFShadowMap;
        var _previousType = this.type;

        _maxTextureSize = capabilities.maxTextureSize;
    }

    public function render(lights:Array<Light>, scene:Scene, camera:Camera) {
        if (scope.enabled == false) return;
        if (scope.autoUpdate == false && scope.needsUpdate == false) return;

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

        for (light in lights) {
            var shadow = light.shadow;

            if (shadow == null) {
                trace("THREE.WebGLShadowMap: ${light} has no shadow.");
                continue;
            }

            if (shadow.autoUpdate == false && shadow.needsUpdate == false) continue;

            _shadowMapSize.copy(shadow.mapSize);

            var shadowFrameExtents = shadow.getFrameExtents();

            _shadowMapSize.multiply(shadowFrameExtents);

            _viewportSize.copy(shadow.mapSize);

            if (_shadowMapSize.x > _maxTextureSize || _shadowMapSize.y > _maxTextureSize) {
                if (_shadowMapSize.x > _maxTextureSize) {
                    _viewportSize.x = Std.int(Math.floor(_maxTextureSize / shadowFrameExtents.x));
                    _shadowMapSize.x = _viewportSize.x * shadowFrameExtents.x;
                    shadow.mapSize.x = _viewportSize.x;
                }

                if (_shadowMapSize.y > _maxTextureSize) {
                    _viewportSize.y = Std.int(Math.floor(_maxTextureSize / shadowFrameExtents.y));
                    _shadowMapSize.y = _viewportSize.y * shadowFrameExtents.y;
                    shadow.mapSize.y = _viewportSize.y;
                }
            }

            if (shadow.map == null || toVSM == true || fromVSM == true) {
                var pars = (this.type != VSMShadowMap) ? {minFilter: NearestFilter, magFilter: NearestFilter} : {};

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

            for (var vp = 0; vp < viewportCount; vp++) {
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

            if (shadow.isPointLightShadow != true && this.type == VSMShadowMap) {
                VSMPass(shadow, camera);
            }

            shadow.needsUpdate = false;
        }

        _previousType = this.type;

        scope.needsUpdate = false;

        renderer.setRenderTarget(currentRenderTarget, activeCubeFace, activeMipmapLevel);
    }

    function VSMPass(shadow:Shadow, camera:Camera) {
        var geometry = objects.update(fullScreenMesh);

        if (shadowMaterialVertical.defines["VSM_SAMPLES"] != shadow.blurSamples) {
            shadowMaterialVertical.defines["VSM_SAMPLES"] = shadow.blurSamples;
            shadowMaterialHorizontal.defines["VSM_SAMPLES"] = shadow.blurSamples;

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

    function getDepthMaterial(object:Object3D, material:Material, light:Light, type:Int):Material {
        var result:Material = null;

        var customMaterial = (light.isPointLight == true) ? object.customDistanceMaterial : object.customDepthMaterial;

        if (customMaterial != null) {
            result = customMaterial;
        } else {
            result = (light.isPointLight == true) ? _distanceMaterial : _depthMaterial;

            if ((renderer.localClippingEnabled && material.clipShadows == true && material.clippingPlanes != null && material.clippingPlanes.length != 0) ||
                (material.displacementMap != null && material.displacementScale != 0) ||
                (material.alphaMap != null && material.alphaTest > 0) ||
                (material.map != null && material.alphaTest > 0)) {

                var keyA = result.uuid;
                var keyB = material.uuid;

                var materialsForVariant = _materialCache.get(keyA);

                if (materialsForVariant == null) {
                    materialsForVariant = new haxe.ds.StringMap();
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
            result.side = (material.shadowSide != null) ? material.shadowSide : material.side;
        } else {
            result.side = (material.shadowSide != null) ? material.shadowSide : shadowSide.get(material.side);
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

        if (light.isPointLight == true && result.isMeshDistanceMaterial == true) {
            var materialProperties = renderer.properties.get(result);
            materialProperties.light = light;
        }

        return result;
    }

    function renderObject(object:Object3D, camera:Camera, shadowCamera:Camera, light:Light, type:Int) {
        if (object.visible == false) return;

        var visible = object.layers.test(camera.layers);

        if (visible && (object.isMesh || object.isLine || object.isPoints)) {
            if ((object.castShadow || (object.receiveShadow && type == VSMShadowMap)) && (object.frustumCulled == false || _frustum.intersectsObject(object))) {
                object.modelViewMatrix.multiplyMatrices(shadowCamera.matrixWorldInverse, object.matrixWorld);

                var geometry = objects.update(object);
                var material = object.material;

                if (Std.is(material, Array)) {
                    var groups = geometry.groups;

                    for (var k = 0, kl = groups.length; k < kl; k++) {
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

        for (var i = 0, l = children.length; i < l; i++) {
            renderObject(children[i], camera, shadowCamera, light, type);
        }
    }

    function onMaterialDispose(event:Event) {
        var material = event.target;

        material.removeEventListener('dispose', onMaterialDispose);

        for (key in _materialCache.keys()) {
            var cache = _materialCache.get(key);

            var uuid = event.target.uuid;

            if (cache.exists(uuid)) {
                var shadowMaterial = cache.get(uuid);
                shadowMaterial.dispose();
                cache.remove(uuid);
            }
        }
    }
}