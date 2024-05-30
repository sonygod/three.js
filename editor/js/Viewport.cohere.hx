import js.three.*;
import js.three.addons.controls.TransformControls;
import js.three.addons.environments.RoomEnvironment;

import js.libs.ui.UIPanel;

import js.EditorControls;
import js.Viewport.Controls.ViewportControls;
import js.Viewport.Info.ViewportInfo;
import js.Viewport.ViewHelper.ViewHelper;
import js.Viewport.XR.XR;
import js.commands.SetPositionCommand;
import js.commands.SetRotationCommand;
import js.commands.SetScaleCommand;
import js.Viewport.Pathtracer.ViewportPathtracer;

class Viewport {
    public function new(editor:Editor) {
        var selector = editor.selector;
        var signals = editor.signals;

        var container = new UIPanel();
        container.setId('viewport');
        container.setPosition('absolute');

        container.add(new ViewportControls(editor));
        container.add(new ViewportInfo(editor));

        var renderer:WebGLRenderer = null;
        var pmremGenerator:PMREMGenerator = null;
        var pathtracer:ViewportPathtracer = null;

        var camera = editor.camera;
        var scene = editor.scene;
        var sceneHelpers = editor.sceneHelpers;

        // helpers

        var GRID_COLORS_LIGHT = [0x999999, 0x777777];
        var GRID_COLORS_DARK = [0x555555, 0x888888];

        var grid = new Group();

        var grid1 = new GridHelper(30, 30);
        grid1.material.color.setHex(GRID_COLORS_LIGHT[0]);
        grid1.material.vertexColors = false;
        grid.add(grid1);

        var grid2 = new GridHelper(30, 6);
        grid2.material.color.setHex(GRID_COLORS_LIGHT[1]);
        grid2.material.vertexColors = false;
        grid.add(grid2);

        var viewHelper = new ViewHelper(camera, container);

        //

        var box = new Box3();

        var selectionBox = new Box3Helper(box);
        selectionBox.material.depthTest = false;
        selectionBox.material.transparent = true;
        selectionBox.visible = false;
        sceneHelpers.add(selectionBox);

        var objectPositionOnDown:Vector3 = null;
        var objectRotationOnDown:Euler = null;
        var objectScaleOnDown:Vector3 = null;

        var transformControls = new TransformControls(camera, container.dom);
        transformControls.addEventListener('axis-changed', function() {
            if (editor.viewportShading != 'realistic') {
                render();
            }
        });
        transformControls.addEventListener('objectChange', function() {
            signals.objectChanged.dispatch(transformControls.object);
        });
        transformControls.addEventListener('mouseDown', function() {
            var object = transformControls.object;

            objectPositionOnDown = object.position.clone();
            objectRotationOnDown = object.rotation.clone();
            objectScaleOnDown = object.scale.clone();

            controls.enabled = false;
        });
        transformControls.addEventListener('mouseUp', function() {
            var object = transformControls.object;

            if (object != null) {
                switch (transformControls.getMode()) {
                    case 'translate':
                        if (!object.position.equals(objectPositionOnDown)) {
                            editor.execute(new SetPositionCommand(editor, object, object.position, objectPositionOnDown));
                        }
                        break;
                    case 'rotate':
                        if (!object.rotation.equals(objectRotationOnDown)) {
                            editor.execute(new SetRotationCommand(editor, object, object.rotation, objectRotationOnDown));
                        }
                        break;
                    case 'scale':
                        if (!object.scale.equals(objectScaleOnDown)) {
                            editor.execute(new SetScaleCommand(editor, object, object.scale, objectScaleOnDown));
                        }
                        break;
                }
            }

            controls.enabled = true;
        });

        sceneHelpers.add(transformControls);

        //

        var xr = new XR(editor, transformControls); // eslint-disable-line no-unused-vars

        // events

        function updateAspectRatio() {
            camera.aspect = container.dom.offsetWidth / container.dom.offsetHeight;
            camera.updateProjectionMatrix();
        }

        var onDownPosition = new Vector2();
        var onUpPosition = new Vector2();
        var onDoubleClickPosition = new Vector2();

        function getMousePosition(dom:HTMLCanvasElement, x:Float, y:Float) : Array<Float> {
            var rect = dom.getBoundingClientRect();
            return [(x - rect.left) / rect.width, (y - rect.top) / rect.height];
        }

        function handleClick() {
            if (onDownPosition.distanceTo(onUpPosition) == 0) {
                var intersects = selector.getPointerIntersects(onUpPosition, camera);
                signals.intersectionsDetected.dispatch(intersects);

                render();
            }
        }

        function onMouseDown(event:MouseEvent) {
            // event.preventDefault();

            if (event.target != renderer.domElement) {
                return;
            }

            var array = getMousePosition(container.dom, event.clientX, event.clientY);
            onDownPosition.fromArray(array);

            document.addEventListener('mouseup', onMouseUp);
        }

        function onMouseUp(event:MouseEvent) {
            var array = getMousePosition(container.dom, event.clientX, event.clientY);
            onUpPosition.fromArray(array);

            handleClick();

            document.removeEventListener('mouseup', onMouseUp);
        }

        function onTouchStart(event:TouchEvent) {
            var touch = event.changedTouches[0];

            var array = getMousePosition(container.dom, touch.clientX, touch.clientY);
            onDownPosition.fromArray(array);

            document.addEventListener('touchend', onTouchEnd);
        }

        function onTouchEnd(event:TouchEvent) {
            var touch = event.changedTouches[0];

            var array = getMousePosition(container.dom, touch.clientX, touch.clientY);
            onUpPosition.fromArray(array);

            handleClick();

            document.removeEventListener('touchend', onTouchEnd);
        }

        function onDoubleClick(event:MouseEvent) {
            var array = getMousePosition(container.dom, event.clientX, event.clientY);
            onDoubleClickPosition.fromArray(array);

            var intersects = selector.getPointerIntersects(onDoubleClickPosition, camera);

            if (intersects.length > 0) {
                var intersect = intersects[0];

                signals.objectFocused.dispatch(intersect.object);
            }
        }

        container.dom.addEventListener('mousedown', onMouseDown);
        container.dom.addEventListener('touchstart', onTouchStart, { passive: false });
        container.dom.addEventListener('dblclick', onDoubleClick);

        // controls need to be added *after* main logic,
        // otherwise controls.enabled doesn't work.

        var controls = new EditorControls(camera, container.dom);
        controls.addEventListener('change', function() {
            signals.cameraChanged.dispatch(camera);
            signals.refreshSidebarObject3D.dispatch(camera);
        });
        viewHelper.center = controls.center;

        // signals

        signals.editorCleared.add(function() {
            controls.center.set(0, 0, 0);
            pathtracer.reset();

            initPT();
            render();
        });

        signals.transformModeChanged.add(function(mode:String) {
            transformControls.setMode(mode);

            render();
        });

        signals.snapChanged.add(function(dist:Float) {
            transformControls.setTranslationSnap(dist);
        });

        signals.spaceChanged.add(function(space:String) {
            transformControls.setSpace(space);

            render();
        });

        signals.rendererUpdated.add(function() {
            scene.traverse(function(child) {
                if (child.material != null) {
                    child.material.needsUpdate = true;
                }
            });

            render();
        });

        signals.rendererCreated.add(function(newRenderer:WebGLRenderer) {
            if (renderer != null) {
                renderer.setAnimationLoop(null);
                renderer.dispose();
                pmremGenerator.dispose();

                container.dom.removeChild(renderer.domElement);
            }

            renderer = newRenderer;

            renderer.setAnimationLoop(animate);
            renderer.setClearColor(0xaaaaaa);

            if (window.matchMedia != null) {
                var mediaQuery = window.matchMedia('(prefers-color-scheme: dark)');
                mediaQuery.addEventListener('change', function(event:Event) {
                    renderer.setClearColor(if (event.matches) {
                        0x333333;
                    } else {
                        0xaaaaaa;
                    });
                    updateGridColors(grid1, grid2, if (event.matches) {
                        GRID_COLORS_DARK;
                    } else {
                        GRID_COLORS_LIGHT;
                    });

                    render();
                });

                renderer.setClearColor(if (mediaQuery.matches) {
                    0x333333;
                } else {
                    0xaaaaaa;
                });
                updateGridColors(grid1, grid2, if (mediaQuery.matches) {
                    GRID_COLORS_DARK;
                } else {
                    GRID_COLORS_LIGHT;
                });
            }

            renderer.setPixelRatio(window.devicePixelRatio);
            renderer.setSize(container.dom.offsetWidth, container.dom.offsetHeight);

            pmremGenerator = new PMREMGenerator(renderer);
            pmremGenerator.compileEquirectangularShader();

            pathtracer = new ViewportPathtracer(renderer);

            container.dom.appendChild(renderer.domElement);

            render();
        });

        signals.rendererDetectKTX2Support.add(function(ktx2Loader:KTX2Loader) {
            ktx2Loader.detectSupport(renderer);
        });

        signals.sceneGraphChanged.add(function() {
            initPT();
            render();
        });

        signals.cameraChanged.add(function() {
            pathtracer.reset();

            render();
        });

        signals.objectSelected.add(function(object:Object3D) {
            selectionBox.visible = false;
            transformControls.detach();

            if (object != null && object != scene && object != camera) {
                box.setFromObject(object, true);

                if (!box.isEmpty()) {
                    selectionBox.visible = true;
                }

                transformControls.attach(object);
            }

            render();
        });

        signals.objectFocused.add(function(object:Object3D) {
            controls.focus(object);
        });

        signals.geometryChanged.add(function(object:Object3D) {
            if (object != null) {
                box.setFromObject(object, true);
            }

            initPT();
            render();
        });

        signals.objectChanged.add(function(object:Object3D) {
            if (editor.selected == object) {
                box.setFromObject(object, true);
            }

            if (object.isPerspectiveCamera) {
                object.updateProjectionMatrix();
            }

            var helper = editor.helpers[object.id];

            if (helper != null && !helper.isSkeletonHelper) {
                helper.update();
            }

            initPT();
            render();
        });

        signals.objectRemoved.add(function(object:Object3D) {
            controls.enabled = true; // see #14180

            if (object == transformControls.object) {
                transformControls.detach();
            }
        });

        signals.materialChanged.add(function() {
            updatePTMaterials();
            render();
        });

        // background

        signals.sceneBackgroundChanged.add(function(backgroundType:String, backgroundColor:Int, backgroundTexture:Texture, backgroundEquirectangularTexture:Texture, backgroundBlurriness:Float, backgroundIntensity:Float, backgroundRotation:Float) {
            scene.background = null;

            switch (backgroundType) {
                case 'Color':
                    scene.background = new Color(backgroundColor);
                    break;
                case 'Texture':
                    if (backgroundTexture != null) {
                        scene.background = backgroundTexture;
                    }
                    break;
                case 'Equirectangular':
                    if (backgroundEquirectangularTexture != null) {
                        backgroundEquirectangularTexture.mapping = EquirectangularReflectionMapping;

                        scene.background = backgroundEquirectangularTexture;
                        scene.backgroundBlurriness = backgroundBlurriness;
                        scene.backgroundIntensity = backgroundIntensity;
                        scene.backgroundRotation.y = backgroundRotation * Math.PI / 180;

                        if (useBackgroundAsEnvironment) {
                            scene.environment = scene.background;
                            scene.environmentRotation.y = backgroundRotation * Math.PI / 180;
                        }
                    }
                    break;
            }

            updatePTBackground();
            render();
        });

        // environment

        var useBackgroundAsEnvironment = false;

        signals.sceneEnvironmentChanged.add(function(environmentType:String, environmentEquirectangularTexture:Texture) {
            scene.environment = null;

            useBackgroundAsEnvironment = false;

            switch (environmentType) {
                case 'Background':
                    useBackgroundAsEnvironment = true;

                    if (scene.background != null && scene.background.isTexture) {
                        scene.environment = scene.background;
                        scene.environment.mapping = EquirectangularReflectionMapping;
                        scene.environmentRotation.y = scene.backgroundRotation.y;
                    }
                    break;
                case 'Equirectangular':
                    if (environmentEquirectangularTexture != null) {
                        scene.environment = environmentEquirectangularTexture;
                        scene.environment.mapping = EquirectangularReflectionMapping;
                    }
                    break;
                case 'ModelViewer':
                    scene.environment = pmremGenerator.fromScene(new RoomEnvironment(), 0.04).texture;
                    break;
            }

            updatePTEnvironment();
            render();
        });

        // fog

        signals.sceneFogChanged.add(function(fogType:String, fogColor:Int, fogNear:Float, fogFar:Float, fogDensity:Float) {
            switch (fogType) {
                case 'None':
                    scene.fog = null;
                    break;
                case 'Fog':
                    scene.fog = new Fog(fogColor, fogNear, fogFar);
                    break;
                case 'FogExp2':
                    scene.fog = new FogExp2(fogColor, fogDensity);
                    break;
            }

            render();
        });

        signals.sceneFogSettingsChanged.add(function(fogType:String, fogColor:Int, fogNear:Float, fogFar:Float, fogDensity:Float) {
            switch (fogType) {
                case 'Fog':
                    scene.fog.color.setHex(fogColor);
                    scene.fog.near = fogNear;
                    scene.fog.far = fogFar;
                    break;
                case 'FogExp2':
                    scene.fog.color.setHex(fogColor);
                    scene.fog.density = fogDensity;
                    break;
            }

            render();
        });

        signals.viewportCameraChanged.add(function() {
            var viewportCamera = editor.viewportCamera;

            if (viewportCamera.isPerspectiveCamera) {
                viewportCamera.aspect = editor.camera.aspect;
                viewportCamera.projectionMatrix.copy(editor.camera.projectionMatrix);
            } else if (viewportCamera.isOrthographicCamera) {
                // TODO
            }

            // disable EditorControls when setting a user camera

            controls.enabled = (viewportCamera == editor.camera);

            render();
        });

        signals.viewportShadingChanged.add(function() {
            var viewportShading = editor.viewportShading;

            switch (viewportShading) {
                case 'realistic':
                    pathtracer.init(scene, camera);
                    break;
                case 'solid':
                    scene.overrideMaterial = null;
                    break;
                case 'normals':
                    scene.overrideMaterial = new MeshNormalMaterial();
                    break;
                case 'wireframe':
                    scene.overrideMaterial = new MeshBasicMaterial({ color: 0x000000, wireframe: true });
                    break;
            }

            render();
        });

        //

        signals.windowResize.add(function() {
            updateAspectRatio();

            renderer.setSize(container.dom.offsetWidth, container.dom.offsetHeight);
            pathtracer.setSize(container.dom.offsetWidth, container.dom.offsetHeight);

            render();
        });

        signals.showGridChanged.add(function(value:Bool) {
            grid.visible = value;

            render();
        });

        signals.showHelpersChanged.add(function(value:Bool) {
            sceneHelpers.visible = value;
            transformControls.enabled = value;

            render();
        });

        signals.cameraResetted.add(updateAspectRatio);

        // animations

        var prevActionsInUse = 0;

        var clock = new Clock(); // only used for animations

        function animate() {
            var mixer = editor.mixer;
            var delta = clock.getDelta();

            var needsUpdate = false;

            // Animations

            var actions = mixer.stats.actions;

            if (actions.inUse > 0 || prevActionsInUse > 0) {
                prevActionsInUse = actions.inUse;

                mixer.update(delta);
                needsUpdate = true;

                if (editor.selected != null) {
                    editor.selected.updateWorldMatrix(false, true); // avoid frame late effect for certain skinned meshes (e.g. Michelle.glb)
                    selectionBox.box.setFromObject(editor.selected, true); // selection box should reflect current animation state
                }
            }

            // View Helper

            if (viewHelper.animating) {
                viewHelper.update(delta);
                needsUpdate = true;
            }

            if (renderer.xr.isPresenting) {
                needsUpdate = true;
            }

            if (needsUpdate) {
                render();
            }

            updatePT();
        }

        function initPT() {
            if (editor.viewportShading == 'realistic') {
                pathtracer.init(scene, camera);
            }
        }

        function updatePTBackground() {
            if (editor.viewportShading == 'realistic') {
                pathtracer.setBackground(scene.background, scene.backgroundBlurriness);
            }
        }

        function updatePTEnvironment() {
            if (editor.viewportShading == 'realistic') {
                pathtracer.setEnvironment(scene.environment);
            }
        }

        function updatePTMaterials() {
            if (editor.viewportShading == 'realistic') {
                pathtracer.updateMaterials();
            }
        }

        function updatePT() {
            if (editor.viewportShading == 'realistic') {
                pathtracer.update();
            }
        }

        //

        var startTime = 0.0;
        var endTime = 0.0;

        function render() {
            startTime = Sys.performance().now();

            renderer.setViewport(0, 0, container.dom.offsetWidth, container.dom.offsetHeight);
            renderer.render(scene, editor.viewportCamera);

            if (camera == editor.viewportCamera) {
                renderer.autoClear = false;
                if (grid.visible) {
                    renderer.render(grid, camera);
                }
                if (sceneHelpers.visible) {
                    renderer.render(sceneHelpers, camera);
                }
                if (!renderer.xr.isPresenting) {
                    viewHelper.render(renderer);
                }
                renderer.autoClear = true;
            }

            endTime = Sys.performance().now();
            editor.signals.sceneRendered.dispatch(endTime - startTime);
        }

        return container;
    }

    function updateGridColors(grid1:GridHelper, grid2:GridHelper, colors:Array<Int>) {
        grid1.material.color.setHex(colors[0]);
        grid2.material.color.setHex(colors[1]);
    }
}