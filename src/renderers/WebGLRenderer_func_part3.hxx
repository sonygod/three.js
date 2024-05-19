class WebGLRenderer {
    private var onAnimationFrameCallback:Null<Dynamic->Void>;
    private var animation:WebGLAnimation;
    private var xr:XR;

    public function new() {
        animation = new WebGLAnimation();
        animation.setAnimationLoop(onAnimationFrame);
        if (js.Browser.isDefined(self)) animation.setContext(self);
        xr.addEventListener('sessionstart', onXRSessionStart);
        xr.addEventListener('sessionend', onXRSessionEnd);
    }

    private function onAnimationFrame(time:Float):Void {
        if (onAnimationFrameCallback != null) onAnimationFrameCallback(time);
    }

    private function onXRSessionStart():Void {
        animation.stop();
    }

    private function onXRSessionEnd():Void {
        animation.start();
    }

    public function setAnimationLoop(callback:Null<Dynamic->Void>):Void {
        onAnimationFrameCallback = callback;
        xr.setAnimationLoop(callback);
        if (callback == null) animation.stop(); else animation.start();
    }

    public function render(scene:Scene, camera:Camera):Void {
        if (camera !== undefined && camera.isCamera !== true) {
            trace('THREE.WebGLRenderer.render: camera is not an instance of THREE.Camera.');
            return;
        }
        if (_isContextLost === true) return;
        // update scene graph
        if (scene.matrixWorldAutoUpdate === true) scene.updateMatrixWorld();
        // update camera matrices and frustum
        if (camera.parent === null && camera.matrixWorldAutoUpdate === true) camera.updateMatrixWorld();
        if (xr.enabled === true && xr.isPresenting === true) {
            if (xr.cameraAutoUpdate === true) xr.updateCamera(camera);
            camera = xr.getCamera(); // use XR camera for rendering
        }
        //
        if (scene.isScene === true) scene.onBeforeRender(this, scene, camera, _currentRenderTarget);
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
        projectObject(scene, camera, 0, this.sortObjects);
        currentRenderList.finish();
        if (this.sortObjects === true) {
            currentRenderList.sort(_opaqueSort, _transparentSort);
        }
        var renderBackground = xr.enabled === false || xr.isPresenting === false || xr.hasDepthSensing() === false;
        if (renderBackground) {
            background.addToRenderList(currentRenderList, scene);
        }
        //
        this.info.render.frame++;
        if (_clippingEnabled === true) clipping.beginShadows();
        var shadowsArray = currentRenderState.state.shadowsArray;
        shadowMap.render(shadowsArray, scene, camera);
        if (_clippingEnabled === true) clipping.endShadows();
        //
        if (this.info.autoReset === true) this.info.reset();
        // render scene
        var opaqueObjects = currentRenderList.opaque;
        var transmissiveObjects = currentRenderList.transmissive;
        currentRenderState.setupLights(this._useLegacyLights);
        if (camera.isArrayCamera) {
            var cameras = camera.cameras;
            if (transmissiveObjects.length > 0) {
                for (i in cameras) {
                    var camera2 = cameras[i];
                    renderTransmissionPass(opaqueObjects, transmissiveObjects, scene, camera2);
                }
            }
            if (renderBackground) background.render(scene);
            for (i in cameras) {
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
        if (scene.isScene === true) scene.onAfterRender(this, scene, camera);
        // _gl.finish();
        bindingStates.resetDefaultState();
        _currentMaterialId = -1;
        _currentCamera = null;
        renderStateStack.pop();
        if (renderStateStack.length > 0) {
            currentRenderState = renderStateStack[renderStateStack.length - 1];
            if (_clippingEnabled === true) clipping.setGlobalState(this.clippingPlanes, currentRenderState.state.camera);
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

    private function projectObject(object:Dynamic, camera:Camera, groupOrder:Int, sortObjects:Bool):Void {
        if (object.visible === false) return;
        var visible = object.layers.test(camera.layers);
        if (visible) {
            if (object.isGroup) {
                groupOrder = object.renderOrder;
            } else if (object.isLOD) {
                if (object.autoUpdate === true) object.update(camera);
            } else if (object.isLight) {
                currentRenderState.pushLight(object);
                if (object.castShadow) {
                    currentRenderState.pushShadow(object);
                }
            } else if (object.isSprite) {
                if (!object.frustumCulled || _frustum.intersectsSprite(object)) {
                    if (sortObjects) {
                        _vector3.setFromMatrixPosition(object.matrixWorld).applyMatrix4(object.matrixWorld).applyMatrix4(_projScreenMatrix);
                    }
                    var geometry = objects.update(object);
                    var material = object.material;
                    if (material.visible) {
                        currentRenderList.push(object, geometry, material, groupOrder, _vector3.z, null);
                    }
                }
            } else if (object.isMesh || object.isLine || object.isPoints) {
                if (!object.frustumCulled || _frustum.intersectsObject(object)) {
                    var geometry = objects.update(object);
                    var material = object.material;
                    if (sortObjects) {
                        if (object.boundingSphere != undefined) {
                            if (object.boundingSphere == null) object.computeBoundingSphere();
                            _vector3.copy(object.boundingSphere.center);
                        } else {
                            if (geometry.boundingSphere == null) geometry.computeBoundingSphere();
                            _vector3.copy(geometry.boundingSphere.center);
                        }
                        _vector3.applyMatrix4(object.matrixWorld).applyMatrix4(_projScreenMatrix);
                    }
                    if (Array.isArray(material)) {
                        var groups = geometry.groups;
                        for (i in groups) {
                            var group = groups[i];
                            var groupMaterial = material[group.materialIndex];
                            if (groupMaterial && groupMaterial.visible) {
                                currentRenderList.push(object, geometry, groupMaterial, groupOrder, _vector3.z, group);
                            }
                        }
                    } else if (material.visible) {
                        currentRenderList.push(object, geometry, material, groupOrder, _vector3.z, null);
                    }
                }
            }
            var children = object.children;
            for (i in children) {
                projectObject(children[i], camera, groupOrder, sortObjects);
            }
        }
    }

    private function renderScene(currentRenderList:Dynamic, scene:Scene, camera:Camera, viewport:Viewport):Void {
        var opaqueObjects = currentRenderList.opaque;
        var transmissiveObjects = currentRenderList.transmissive;
        var transparentObjects = currentRenderList.transparent;
        currentRenderState.setupLightsView(camera);
        if (_clippingEnabled === true) clipping.setGlobalState(this.clippingPlanes, camera);
        if (viewport) state.viewport(_currentViewport.copy(viewport));
        if (opaqueObjects.length > 0) renderObjects(opaqueObjects, scene, camera);
        if (transmissiveObjects.length > 0) renderObjects(transmissiveObjects, scene, camera);
        if (transparentObjects.length > 0) renderObjects(transparentObjects, scene, camera);
        // Ensure depth buffer writing is enabled so it can be cleared on next render
        state.buffers.depth.setTest(true);
        state.buffers.depth.setMask(true);
        state.buffers.color.setMask(true);
        state.setPolygonOffset(false);
    }

    private function renderTransmissionPass(opaqueObjects:Dynamic, transmissiveObjects:Dynamic, scene:Scene, camera:Camera):Void {
        var overrideMaterial = scene.isScene ? scene.overrideMaterial : null;
        if (overrideMaterial != null) return;
        if (currentRenderState.state.transmissionRenderTarget[camera.id] == undefined) {
            currentRenderState.state.transmissionRenderTarget[camera.id] = new WebGLRenderTarget(1, 1, {
                generateMipmaps: true,
                type: (extensions.has('EXT_color_buffer_half_float') || extensions.has('EXT_color_buffer_float')) ? HalfFloatType : UnsignedByteType,
                minFilter: LinearMipmapLinearFilter,
                samples: 4,
                stencilBuffer: stencil,
                resolveDepthBuffer: false,
                resolveStencilBuffer: false
            });
        }
        var transmissionRenderTarget = currentRenderState.state.transmissionRenderTarget[camera.id];
        var activeViewport = camera.viewport || _currentViewport;
        transmissionRenderTarget.setSize(activeViewport.z, activeViewport.w);
        var currentRenderTarget = _this.getRenderTarget();
        _this.setRenderTarget(transmissionRenderTarget);
        _this.getClearColor(_currentClearColor);
        _currentClearAlpha = _this.getClearAlpha();
        if (_currentClearAlpha < 1) _this.setClearColor(0xffffff, 0.5);
        _this.clear();
        var currentToneMapping = _this.toneMapping;
        _this.toneMapping = NoToneMapping;
        var currentCameraViewport = camera.viewport;
        if (camera.viewport != undefined) camera.viewport = undefined;
        currentRenderState.setupLightsView(camera);
        if (_clippingEnabled === true) clipping.setGlobalState(this.clippingPlanes, camera);
        renderObjects(opaqueObjects, scene, camera);
        textures.updateMultisampleRenderTarget(transmissionRenderTarget);
        textures.updateRenderTargetMipmap(transmissionRenderTarget);
        if (extensions.has('WEBGL_multisampled_render_to_texture') == false) {
            var renderTargetNeedsUpdate = false;
            for (i in transmissiveObjects) {
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
            if (renderTargetNeedsUpdate == true) {
                textures.updateMultisampleRenderTarget(transmissionRenderTarget);
                textures.updateRenderTargetMipmap(transmissionRenderTarget);
            }
        }
        _this.setRenderTarget(currentRenderTarget);
        _this.setClearColor(_currentClearColor, _currentClearAlpha);
        if (currentCameraViewport != undefined) camera.viewport = currentCameraViewport;
        _this.toneMapping = currentToneMapping;
    }

    private function renderObjects(renderList:Dynamic, scene:Scene, camera:Camera):Void {
        var overrideMaterial = scene.isScene ? scene.overrideMaterial : null;
        for (i in renderList) {
            var renderItem = renderList[i];
            var object = renderItem.object;
            var geometry = renderItem.geometry;
            var material = overrideMaterial == null ? renderItem.material : overrideMaterial;
            var group = renderItem.group;
            if (object.layers.test(camera.layers)) {
                renderObject(object, scene, camera, geometry, material, group);
            }
        }
    }
}