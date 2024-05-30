// Animation Loop

var onAnimationFrameCallback: @js.Function<->(Float) -> Void;

@:jsRequire("AnimationFrameCallback")
function onAnimationFrame(time: Float) {
    if (onAnimationFrameCallback != null) onAnimationFrameCallback(time);
}

function onXRSessionStart() {
    animation.stop();
}

function onXRSessionEnd() {
    animation.start();
}

var animation = new WebGLAnimation();
animation.setAnimationLoop(onAnimationFrame);

if (js.Sys.context != null) animation.setContext(js.Sys.context);

public function setAnimationLoop(callback: @js.Function<->(Float) -> Void) {
    onAnimationFrameCallback = callback;
    xr.setAnimationLoop(callback);

    if (callback == null) animation.stop();
    else animation.start();
}

xr.addEventListener("sessionstart", onXRSessionStart);
xr.addEventListener("sessionend", onXRSessionEnd);

// Rendering

public function render(scene: Dynamic, camera: Dynamic) {
    if (camera != null && camera.isCamera != true) {
        trace("THREE.WebGLRenderer.render: camera is not an instance of THREE.Camera.");
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

    _localClippingEnabled = localClippingEnabled;
    _clippingEnabled = clipping.init(clippingPlanes, _localClippingEnabled);

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

    info.render.frame++;

    if (_clippingEnabled) clipping.beginShadows();

    var shadowsArray = currentRenderState.state.shadowsArray;

    shadowMap.render(shadowsArray, scene, camera);

    if (_clippingEnabled) clipping.endShadows();

    //

    if (info.autoReset) info.reset();

    // render scene

    var opaqueObjects = currentRenderList.opaque;
    var transmissiveObjects = currentRenderList.transmissive;

    currentRenderState.setupLights(_this._useLegacyLights);

    if (camera.isArrayCamera) {
        var cameras = camera.cameras;

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

function projectObject(object: Dynamic, camera: Dynamic, groupOrder: Int, sortObjects: Bool) {
    if (object.visible == false) return;

    var visible = object.layers.test(camera.layers);

    if (visible) {
        if (Std.is(object, Group)) {
            groupOrder = object.renderOrder;
        } else if (Std.is(object, LOD)) {
            if (object.autoUpdate) object.update(camera);
        } else if (Std.is(object, Light)) {
            currentRenderState.pushLight(object);

            if (object.castShadow) {
                currentRenderState.pushShadow(object);
            }
        } else if (Std.is(object, Sprite)) {
            if (!object.frustumCulled || _frustum.intersectsSprite(object)) {
                if (sortObjects) {
                    _vector3.setFromMatrixPosition(object.matrixWorld);
                    _vector3.applyMatrix4(_projScreenMatrix);
                }

                var geometry = objects.update(object);
                var material = object.material;

                if (material.visible) {
                    currentRenderList.push(object, geometry, material, groupOrder, _vector3.z, null);
                }
            }
        } else if (Std.is(object, Mesh) || Std.is(object, Line) || Std.is(object, Points)) {
            if (!object.frustumCulled || _frustum.intersectsObject(object)) {
                var geometry = objects.update(object);
                var material = object.material;

                if (sortObjects) {
                    if (object.boundingSphere != null) {
                        if (object.boundingSphere == null) object.computeBoundingSphere();
                        _vector3.copy(object.boundingSphere.center);
                    } else {
                        if (geometry.boundingSphere == null) geometry.computeBoundingSphere();
                        _vector3.copy(geometry.boundingSphere.center);
                    }

                    _vector3.applyMatrix4(object.matrixWorld);
                    _vector3.applyMatrix4(_projScreenMatrix);
                }

                if (Std.isArray(material)) {
                    var groups = geometry.groups;

                    for (i in 0...groups.length) {
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
    }

    var children = object.children;

    for (i in 0...children.length) {
        projectObject(children[i], camera, groupOrder, sortObjects);
    }
}

function renderScene(currentRenderList: Dynamic, scene: Dynamic, camera: Dynamic, viewport: Dynamic) {
    var opaqueObjects = currentRenderList.opaque;
    var transmissiveObjects = currentRenderList.transmissive;
    var transparentObjects = currentRenderList.transparent;

    currentRenderState.setupLightsView(camera);

    if (_clippingEnabled) clipping.setGlobalState(_this.clippingPlanes, camera);

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

function renderTransmissionPass(opaqueObjects: Dynamic, transmissiveObjects: Dynamic, scene: Dynamic, camera: Dynamic) {
    var overrideMaterial = if (scene.isScene) scene.overrideMaterial else null;

    if (overrideMaterial != null) {
        return;
    }

    if (currentRenderState.state.transmissionRenderTarget[camera.id] == null) {
        currentRenderState.state.transmissionRenderTarget[camera.id] = new WebGLRenderTarget(1, 1, {
            generateMipmaps: true,
            type: if (extensions.has("EXT_color_buffer_half_float") || extensions.has("EXT_color_buffer_float")) HalfFloatType else UnsignedByteType,
            minFilter: LinearMipmapLinearFilter,
            samples: 4,
            stencilBuffer: stencil,
            resolveDepthBuffer: false,
            resolveStencilBuffer: false,
        });

        // debug

        /*
        var geometry = new PlaneGeometry();
        var material = new MeshBasicMaterial({ map: _transmissionRenderTarget.texture });

        var mesh = new Mesh(geometry, material);
        scene.add(mesh);
        */
    }

    var transmissionRenderTarget = currentRenderState.state.transmissionRenderTarget[camera.id];

    var activeViewport = if (camera.viewport != null) camera.viewport else _currentViewport;
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
    var currentCameraViewport = camera.viewport;
    if (camera.viewport != null) camera.viewport = null;

    currentRenderState.setupLightsView(camera);

    if (_clippingEnabled) clipping.setGlobalState(_this.clippingPlanes, camera);

    renderObjects(opaqueObjects, scene, camera);

    textures.updateMultisampleRenderTarget(transmissionRenderTarget);
    textures.updateRenderTargetMipmap(transmissionRenderTarget);

    if (!extensions.has("WEBGL_multisampled_render_to_texture")) { // see #28131
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

function renderObjects(renderList: Dynamic, scene: Dynamic, camera: Dynamic) {
    var overrideMaterial = if (scene.isScene) scene.overrideMaterial else null;

    for (i in 0...renderList.length) {
        var renderItem = renderList[i];

        var object = renderItem.object;
        var geometry = renderItem.geometry;
        var material = if (overrideMaterial == null) renderItem.material else overrideMaterial;
        var group = renderItem.group;

        if (object.layers.test(camera.layers)) {
            renderObject(object, scene, camera, geometry, material, group);
        }
    }
}