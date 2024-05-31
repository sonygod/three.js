import three.Cameras.ArrayCamera;
import three.Cameras.Camera;
import three.Core.Layers;
import three.Core.Object3D;
import three.Geometries.PlaneGeometry;
import three.Lights.Light;
import three.Materials.MeshBasicMaterial;
import three.Materials.Material;
import three.Math.Frustum;
import three.Math.Vector3;
import three.Objects.LOD;
import three.Objects.Mesh;
import three.Objects.Sprite;
import three.Renderers.WebGLAnimation;
import three.Renderers.WebGLRenderTarget;
import three.Renderers.WebGLRenderer;
import three.Scenes.Scene;
import three.Textures.Texture;

class WebGLRendererHaxe {

    // ... other members

    public function setAnimationLoop(callback:Float->Void):Void {
        _onAnimationFrameCallback = callback;
        xr.setAnimationLoop(callback);

        if (callback == null) {
            animation.stop();
        } else {
            animation.start();
        }
    }

    // ... other methods

    function render(scene:Scene, camera:Camera):Void {
        if (camera != null && !camera.isCamera) {
            trace('THREE.WebGLRenderer.render: camera is not an instance of THREE.Camera.');
            return;
        }

        if (_isContextLost) return;

        // update scene graph
        if (scene.matrixWorldAutoUpdate) scene.updateMatrixWorld();

        // update camera matrices and frustum
        if (camera.parent == null && camera.matrixWorldAutoUpdate) camera.updateMatrixWorld();

        if (xr.enabled && xr.isPresenting) {
            if (xr.cameraAutoUpdate) xr.updateCamera(camera);
            camera = xr.getCamera(); // use XR camera for rendering
        }

        //
        if (scene.isScene) scene.onBeforeRender(_this, scene, camera, _currentRenderTarget);

        currentRenderState = renderStates.get(scene, renderStateStack.length);
        currentRenderState.init(camera);

        renderStateStack.push(currentRenderState);

        _projScreenMatrix.multiplyMatrices(camera.projectionMatrix, camera.matrixWorldInverse);
        _frustum.setFromProjectionMatrix(_projScreenMatrix);

        _localClippingEnabled = this.localClippingEnabled;
        _clippingEnabled = clipping.init(this.clippingPlanes, _localClippingEnabled);

        currentRenderList = renderLists.get(scene, renderListStack.length);
        currentRenderList.init();

        renderListStack.push(currentRenderList);

        projectObject(scene, camera, 0, _this.sortObjects);

        currentRenderList.finish();

        if (_this.sortObjects) {
            currentRenderList.sort(_opaqueSort, _transparentSort);
        }

        var renderBackground = !xr.enabled || !xr.isPresenting || !xr.hasDepthSensing();
        if (renderBackground) {
            background.addToRenderList(currentRenderList, scene);
        }

        //
        this.info.render.frame++;

        if (_clippingEnabled) clipping.beginShadows();

        var shadowsArray = currentRenderState.state.shadowsArray;

        shadowMap.render(shadowsArray, scene, camera);

        if (_clippingEnabled) clipping.endShadows();

        //
        if (this.info.autoReset) this.info.reset();

        // render scene
        var opaqueObjects = currentRenderList.opaque;
        var transmissiveObjects = currentRenderList.transmissive;

        currentRenderState.setupLights(_this._useLegacyLights);

        if (Std.is(camera, ArrayCamera)) {
            var cameras = cast(camera, ArrayCamera).cameras;

            if (transmissiveObjects.length > 0) {
                for (i in 0...cameras.length) {
                    var camera2 = cameras[i];
                    renderTransmissionPass(opaqueObjects, transmissiveObjects, scene, camera2);
                }
            }

            if (renderBackground) background.render(scene);

            for (i in 0...cameras.length) {
                var camera2 = cameras[i];
                renderScene(currentRenderList, scene, camera2, camera2.viewport);
            }
        } else {
            if (transmissiveObjects.length > 0) renderTransmissionPass(opaqueObjects, transmissiveObjects, scene, camera);

            if (renderBackground) background.render(scene);

            renderScene(currentRenderList, scene, camera);
        }

        //
        if (_currentRenderTarget != null) {
            // resolve multisample renderbuffers to a single-sample texture if necessary
            textures.updateMultisampleRenderTarget(_currentRenderTarget);

            // Generate mipmap if we're using any kind of mipmap filtering
            textures.updateRenderTargetMipmap(_currentRenderTarget);
        }

        //
        if (scene.isScene) scene.onAfterRender(_this, scene, camera);

        // _gl.finish();

        bindingStates.resetDefaultState();
        _currentMaterialId = -1;
        _currentCamera = null;

        renderStateStack.pop();

        if (renderStateStack.length > 0) {
            currentRenderState = renderStateStack[renderStateStack.length - 1];
            if (_clippingEnabled) clipping.setGlobalState(_this.clippingPlanes, currentRenderState.state.camera);
        } else {
            currentRenderState = null;
        }

        renderListStack.pop();

        if (renderListStack.length > 0) {
            currentRenderList = renderListStack[renderListStack.length - 1];
        } else {
            currentRenderList = null;
        }
    }

    function projectObject(object:Object3D, camera:Camera, groupOrder:Int, sortObjects:Bool):Void {
        if (!object.visible) return;

        var visible = object.layers.test(camera.layers);

        if (visible) {
            if (Std.is(object, LOD)) {
                var lod = cast(object, LOD);
                if (lod.autoUpdate) lod.update(camera);
            } else if (Std.is(object, Light)) {
                var light = cast(object, Light);
                currentRenderState.pushLight(light);
                if (light.castShadow) {
                    currentRenderState.pushShadow(light);
                }
            } else if (Std.is(object, Sprite)) {
                var sprite = cast(object, Sprite);
                if (!sprite.frustumCulled || _frustum.intersectsSprite(sprite)) {
                    if (sortObjects) {
                        _vector3.setFromMatrixPosition(sprite.matrixWorld)
                            .applyMatrix4(_projScreenMatrix);
                    }

                    var geometry = objects.update(sprite);
                    var material = sprite.material;

                    if (material.visible) {
                        currentRenderList.push(sprite, geometry, material, groupOrder, _vector3.z, null);
                    }
                }
            } else if (Std.is(object, Mesh) || Std.is(object, three.Objects.Line) || Std.is(object, three.Objects.Points)) {
                if (!object.frustumCulled || _frustum.intersectsObject(object)) {
                    var geometry = objects.update(object);
                    var material = object.material;

                    if (sortObjects) {
                        if (object.boundingSphere != null) {
                            _vector3.copy(object.boundingSphere.center);
                        } else {
                            if (geometry.boundingSphere == null) geometry.computeBoundingSphere();
                            _vector3.copy(geometry.boundingSphere.center);
                        }

                        _vector3
                            .applyMatrix4(object.matrixWorld)
                            .applyMatrix4(_projScreenMatrix);
                    }

                    if (Std.is(material, Array)) {
                        var groups = geometry.groups;
                        for (i in 0...groups.length) {
                            var group = groups[i];
                            var groupMaterial = material[group.materialIndex];

                            if (groupMaterial != null && groupMaterial.visible) {
                                currentRenderList.push(object, geometry, groupMaterial, groupOrder, _vector3.z, group);
                            }
                        }
                    } else if (material.visible) {
                        currentRenderList.push(object, geometry, material, groupOrder, _vector3.z, null);
                    }
                }
            }
        }

        var children = object.children;
        for (i in 0...children.length) {
            projectObject(children[i], camera, groupOrder, sortObjects);
        }
    }

    function renderScene(currentRenderList:RenderList, scene:Scene, camera:Camera, viewport:Null<Viewport> = null):Void {
        var opaqueObjects = currentRenderList.opaque;
        var transmissiveObjects = currentRenderList.transmissive;
        var transparentObjects = currentRenderList.transparent;

        currentRenderState.setupLightsView(camera);

        if (_clippingEnabled) clipping.setGlobalState(_this.clippingPlanes, camera);

        if (viewport != null) state.viewport(_currentViewport.copy(viewport));

        if (opaqueObjects.length > 0) renderObjects(opaqueObjects, scene, camera);
        if (transmissiveObjects.length > 0) renderObjects(transmissiveObjects, scene, camera);
        if (transparentObjects.length > 0) renderObjects(transparentObjects, scene, camera);

        // Ensure depth buffer writing is enabled so it can be cleared on next render
        state.buffers.depth.setTest(true);
        state.buffers.depth.setMask(true);
        state.buffers.color.setMask(true);

        state.setPolygonOffset(false);
    }

    function renderTransmissionPass(opaqueObjects:Array<RenderItem>, transmissiveObjects:Array<RenderItem>, scene:Scene, camera:Camera):Void {
        var overrideMaterial:Material = (scene.isScene) ? scene.overrideMaterial : null;

        if (overrideMaterial != null) {
            return;
        }

        if (currentRenderState.state.transmissionRenderTarget[camera.id] == null) {
            currentRenderState.state.transmissionRenderTarget[camera.id] = new WebGLRenderTarget(1, 1, {
                generateMipmaps: true,
                type: (extensions.has('EXT_color_buffer_half_float') || extensions.has('EXT_color_buffer_float')) ? HalfFloatType : UnsignedByteType,
                minFilter: LinearMipmapLinearFilter,
                samples: 4,
                stencilBuffer: stencil,
                resolveDepthBuffer: false,
                resolveStencilBuffer: false
            });

            // debug
            /*
            var geometry = new PlaneGeometry();
            var material = new MeshBasicMaterial( { map: _transmissionRenderTarget.texture } );
            var mesh = new Mesh( geometry, material );
            scene.add( mesh );
            */
        }

        var transmissionRenderTarget = currentRenderState.state.transmissionRenderTarget[camera.id];

        var activeViewport:Viewport = (camera.viewport != null) ? camera.viewport : _currentViewport;
        transmissionRenderTarget.setSize(activeViewport.z, activeViewport.w);

        //
        var currentRenderTarget = _this.getRenderTarget();
        _this.setRenderTarget(transmissionRenderTarget);

        _this.getClearColor(_currentClearColor);
        _currentClearAlpha = _this.getClearAlpha();
        if (_currentClearAlpha < 1) _this.setClearColor(0xffffff, 0.5);

        _this.clear();

        // Turn off the features which can affect the frag color for opaque objects pass.
        // Otherwise they are applied twice in opaque objects pass and transmission objects pass.
        var currentToneMapping = _this.toneMapping;
        _this.toneMapping = NoToneMapping;

        // Remove viewport from camera to avoid nested render calls resetting viewport to it (e.g Reflector).
        // Transmission render pass requires viewport to match the transmissionRenderTarget.
        var currentCameraViewport:Viewport = camera.viewport;
        if (camera.viewport != null) camera.viewport = null;

        currentRenderState.setupLightsView(camera);

        if (_clippingEnabled) clipping.setGlobalState(_this.clippingPlanes, camera);

        renderObjects(opaqueObjects, scene, camera);

        textures.updateMultisampleRenderTarget(transmissionRenderTarget);
        textures.updateRenderTargetMipmap(transmissionRenderTarget);

        if (!extensions.has('WEBGL_multisampled_render_to_texture')) { // see #28131
            var renderTargetNeedsUpdate = false;

            for (i in 0...transmissiveObjects.length) {
                var renderItem = transmissiveObjects[i];

                var object = renderItem.object;
                var geometry = renderItem.geometry;
                var material = renderItem.material;
                var group = renderItem.group;

                if (material.side == DoubleSide && object.layers.test(camera.layers)) {
                    var currentSide = material.side;

                    material.side = BackSide;
                    material.needsUpdate = true;

                    renderObject(object, scene, camera, geometry, material, group);

                    material.side = currentSide;
                    material.needsUpdate = true;

                    renderTargetNeedsUpdate = true;
                }
            }

            if (renderTargetNeedsUpdate) {
                textures.updateMultisampleRenderTarget(transmissionRenderTarget);
                textures.updateRenderTargetMipmap(transmissionRenderTarget);
            }
        }

        _this.setRenderTarget(currentRenderTarget);

        _this.setClearColor(_currentClearColor, _currentClearAlpha);

        if (currentCameraViewport != null) camera.viewport = currentCameraViewport;

        _this.toneMapping = currentToneMapping;
    }

    function renderObjects(renderList:Array<RenderItem>, scene:Scene, camera:Camera):Void {
        var overrideMaterial:Material = scene.isScene ? scene.overrideMaterial : null;

        for (i in 0...renderList.length) {
            var renderItem = renderList[i];

            var object = renderItem.object;
            var geometry = renderItem.geometry;
            var material = (overrideMaterial == null) ? renderItem.material : overrideMaterial;
            var group = renderItem.group;

            if (object.layers.test(camera.layers)) {
                renderObject(object, scene, camera, geometry, material, group);
            }
        }
    }

    // ... other methods
}