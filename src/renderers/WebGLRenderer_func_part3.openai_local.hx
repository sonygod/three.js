// Animation Loop

private var onAnimationFrameCallback:Dynamic = null;

private function onAnimationFrame(time:Float):Void {
    if (onAnimationFrameCallback != null) {
        onAnimationFrameCallback(time);
    }
}

private function onXRSessionStart():Void {
    animation.stop();
}

private function onXRSessionEnd():Void {
    animation.start();
}

private var animation:WebGLAnimation = new WebGLAnimation();
animation.setAnimationLoop(onAnimationFrame);

#if js
animation.setContext(js.Browser.window);
#end

public function setAnimationLoop(callback:Dynamic):Void {
    onAnimationFrameCallback = callback;
    xr.setAnimationLoop(callback);

    if (callback == null) {
        animation.stop();
    } else {
        animation.start();
    }
}

xr.addEventListener('sessionstart', onXRSessionStart);
xr.addEventListener('sessionend', onXRSessionEnd);

// Rendering

public function render(scene:Scene, camera:Camera):Void {
    if (camera == null || !camera.isCamera) {
        js.Browser.console.error('THREE.WebGLRenderer.render: camera is not an instance of THREE.Camera.');
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

    if (scene.isScene) scene.onBeforeRender(this, scene, camera, _currentRenderTarget);

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

    if (this.sortObjects) {
        currentRenderList.sort(_opaqueSort, _transparentSort);
    }

    var renderBackground:Bool = !xr.enabled || !xr.isPresenting || !xr.hasDepthSensing();
    if (renderBackground) {
        background.addToRenderList(currentRenderList, scene);
    }

    this.info.render.frame++;

    if (_clippingEnabled) clipping.beginShadows();

    var shadowsArray:Array<Shadow> = currentRenderState.state.shadowsArray;
    shadowMap.render(shadowsArray, scene, camera);

    if (_clippingEnabled) clipping.endShadows();

    if (this.info.autoReset) this.info.reset();

    // render scene
    var opaqueObjects:Array<RenderItem> = currentRenderList.opaque;
    var transmissiveObjects:Array<RenderItem> = currentRenderList.transmissive;

    currentRenderState.setupLights(this._useLegacyLights);

    if (camera.isArrayCamera) {
        var cameras:Array<Camera> = camera.cameras;

        if (transmissiveObjects.length > 0) {
            for (i in 0...cameras.length) {
                var camera2:Camera = cameras[i];
                renderTransmissionPass(opaqueObjects, transmissiveObjects, scene, camera2);
            }
        }

        if (renderBackground) background.render(scene);

        for (i in 0...cameras.length) {
            var camera2:Camera = cameras[i];
            renderScene(currentRenderList, scene, camera2, camera2.viewport);
        }
    } else {
        if (transmissiveObjects.length > 0) renderTransmissionPass(opaqueObjects, transmissiveObjects, scene, camera);
        if (renderBackground) background.render(scene);
        renderScene(currentRenderList, scene, camera);
    }

    if (_currentRenderTarget != null) {
        // resolve multisample renderbuffers to a single-sample texture if necessary
        textures.updateMultisampleRenderTarget(_currentRenderTarget);

        // Generate mipmap if we're using any kind of mipmap filtering
        textures.updateRenderTargetMipmap(_currentRenderTarget);
    }

    if (scene.isScene) scene.onAfterRender(this, scene, camera);

    // _gl.finish();

    bindingStates.resetDefaultState();
    _currentMaterialId = -1;
    _currentCamera = null;

    renderStateStack.pop();

    if (renderStateStack.length > 0) {
        currentRenderState = renderStateStack[renderStateStack.length - 1];
        if (_clippingEnabled) clipping.setGlobalState(this.clippingPlanes, currentRenderState.state.camera);
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

private function projectObject(object:Object3D, camera:Camera, groupOrder:Int, sortObjects:Bool):Void {
    if (!object.visible) return;

    var visible:Bool = object.layers.test(camera.layers);

    if (visible) {
        if (object.isGroup) {
            groupOrder = object.renderOrder;
        } else if (object.isLOD) {
            if (object.autoUpdate) object.update(camera);
        } else if (object.isLight) {
            currentRenderState.pushLight(object);
            if (object.castShadow) {
                currentRenderState.pushShadow(object);
            }
        } else if (object.isSprite) {
            if (!object.frustumCulled || _frustum.intersectsSprite(object)) {
                if (sortObjects) {
                    _vector3.setFromMatrixPosition(object.matrixWorld).applyMatrix4(_projScreenMatrix);
                }
                var geometry:Geometry = objects.update(object);
                var material:Material = object.material;
                if (material.visible) {
                    currentRenderList.push(object, geometry, material, groupOrder, _vector3.z, null);
                }
            }
        } else if (object.isMesh || object.isLine || object.isPoints) {
            if (!object.frustumCulled || _frustum.intersectsObject(object)) {
                var geometry:Geometry = objects.update(object);
                var material:Material = object.material;
                if (sortObjects) {
                    if (object.boundingSphere != null) {
                        if (object.boundingSphere == null) object.computeBoundingSphere();
                        _vector3.copy(object.boundingSphere.center);
                    } else {
                        if (geometry.boundingSphere == null) geometry.computeBoundingSphere();
                        _vector3.copy(geometry.boundingSphere.center);
                    }
                    _vector3.applyMatrix4(object.matrixWorld).applyMatrix4(_projScreenMatrix);
                }
                if (Std.is(material, Array<Material>)) {
                    var groups:Array<Group> = geometry.groups;
                    for (i in 0...groups.length) {
                        var group:Group = groups[i];
                        var groupMaterial:Material = material[group.materialIndex];
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

    var children:Array<Object3D> = object.children;
    for (i in 0...children.length) {
        projectObject(children[i], camera, groupOrder, sortObjects);
    }
}

private function renderScene(currentRenderList:RenderList, scene:Scene, camera:Camera, viewport:Viewport):Void {
    var opaqueObjects:Array<RenderItem> = currentRenderList.opaque;
    var transmissiveObjects:Array<RenderItem> = currentRenderList.transmissive;
    var transparentObjects:Array<RenderItem> = currentRenderList.transparent;

    currentRenderState.setupLightsView(camera);

    if (_clippingEnabled) clipping.setGlobalState(this.clippingPlanes, camera);

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

private function renderTransmissionPass(opaqueObjects:Array<RenderItem>, transmissiveObjects:Array<RenderItem>, scene:Scene, camera:Camera):Void {
    var overrideMaterial:Material = scene.isScene ? scene.overrideMaterial : null;

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
        var geometry:PlaneGeometry = new PlaneGeometry();
        var material:MeshBasicMaterial = new MeshBasicMaterial({map: _transmissionRenderTarget.texture});

        var mesh:Mesh = new Mesh(geometry, material);
        scene.add(mesh);
        */
    }

    var transmissionRenderTarget:WebGLRenderTarget = currentRenderState.state.transmissionRenderTarget[camera.id];

    var activeViewport:Viewport = camera.viewport != null ? camera.viewport : _currentViewport;
    transmissionRenderTarget.setSize(activeViewport.z, activeViewport.w);

    var currentRenderTarget:WebGLRenderTarget = this.getRenderTarget();
    this.setRenderTarget(transmissionRenderTarget);

    this.getClearColor(_currentClearColor);
    _currentClearAlpha = this.getClearAlpha();
    if (_currentClearAlpha < 1) this.setClearColor(0xffffff, 0.5);

    this.clear();

    // Turn off the features which can affect the frag color for opaque objects pass.
    // Otherwise they are applied twice in opaque objects pass and transmission objects pass.
    var currentToneMapping:ToneMapping = this.toneMapping;
    this.toneMapping = NoToneMapping;

    // Remove viewport from camera to avoid nested render calls resetting viewport to it (e.g Reflector).
    // Transmission render pass requires viewport to match the transmissionRenderTarget.
    var currentCameraViewport:Viewport = camera.viewport;
    if (camera.viewport != null) camera.viewport = null;

    currentRenderState.setupLightsView(camera);

    if (_clippingEnabled) clipping.setGlobalState(this.clippingPlanes, camera);

    renderObjects(opaqueObjects, scene, camera);

    textures.updateMultisampleRenderTarget(transmissionRenderTarget);
    textures.updateRenderTargetMipmap(transmissionRenderTarget);

    if (!extensions.has('WEBGL_multisampled_render_to_texture')) { // see #28131
        var renderTargetNeedsUpdate:Bool = false;

        for (i in 0...transmissiveObjects.length) {
            var renderItem:RenderItem = transmissiveObjects[i];

            var object:Object3D = renderItem.object;
            var geometry:Geometry = renderItem.geometry;
            var material:Material = renderItem.material;
            var group:Group = renderItem.group;

            if (material.side == DoubleSide && object.layers.test(camera.layers)) {
                var currentSide:Side = material.side;

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

    this.setRenderTarget(currentRenderTarget);

    this.setClearColor(_currentClearColor, _currentClearAlpha);

    if (currentCameraViewport != null) camera.viewport = currentCameraViewport;

    this.toneMapping = currentToneMapping;
}

private function renderObjects(renderList:Array<RenderItem>, scene:Scene, camera:Camera):Void {
    var overrideMaterial:Material = scene.isScene ? scene.overrideMaterial : null;

    for (i in 0...renderList.length) {
        var renderItem:RenderItem = renderList[i];

        var object:Object3D = renderItem.object;
        var geometry:Geometry = renderItem.geometry;
        var material:Material = overrideMaterial != null ? overrideMaterial : renderItem.material;
        var group:Group = renderItem.group;

        if (object.layers.test(camera.layers)) {
            renderObject(object, scene, camera, geometry, material, group);
        }
    }
}