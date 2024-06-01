import three.Three;
import three.addons.controls.TransformControls;
import three.cameras.OrthographicCamera;
import three.cameras.PerspectiveCamera;
import three.core.Clock;
import three.geometries.BoxGeometry;
import three.helpers.Box3Helper;
import three.helpers.GridHelper;
import three.materials.LineBasicMaterial;
import three.materials.MeshBasicMaterial;
import three.materials.MeshNormalMaterial;
import three.math.Box3;
import three.math.Vector2;
import three.math.Vector3;
import three.objects.Group;
import three.renderers.WebGLRenderer;
import three.scenes.Scene;
import js.Browser;

import app.editor.Editor;
import app.editor.commands.SetPositionCommand;
import app.editor.commands.SetRotationCommand;
import app.editor.commands.SetScaleCommand;
import app.editor.viewport.EditorControls;
import app.editor.viewport.ViewportControls;
import app.editor.viewport.ViewportInfo;
import app.editor.viewport.ViewportPathtracer;
import app.editor.viewport.ViewHelper;
import app.editor.viewport.XR;
import app.ui.UIPanel;

class Viewport {

    public var container:UIPanel;

    private var editor:Editor;

    private var renderer:WebGLRenderer = null;
    private var pmremGenerator:Dynamic = null;
    private var pathtracer:ViewportPathtracer = null;

    private var camera:PerspectiveCamera;
    private var scene:Scene;
    private var sceneHelpers:Scene;

    private var grid:Group;

    private var selectionBox:Box3Helper;
    private var transformControls:TransformControls;

    private var viewHelper:ViewHelper;

    private var controls:EditorControls;

    private static var GRID_COLORS_LIGHT:Array<Int> = [ 0x999999, 0x777777 ];
    private static var GRID_COLORS_DARK:Array<Int> = [ 0x555555, 0x888888 ];

    public function new(editor:Editor) {
        this.editor = editor;

        this.container = new UIPanel();
        this.container.setId('viewport');
        this.container.setPosition('absolute');

        this.container.add(new ViewportControls(editor));
        this.container.add(new ViewportInfo(editor));

        //

        this.camera = editor.camera;
        this.scene = editor.scene;
        this.sceneHelpers = editor.sceneHelpers;

        // helpers

        this.grid = new Group();

        var grid1:GridHelper = new GridHelper(30, 30);
        grid1.material.color.setHex(GRID_COLORS_LIGHT[0]);
        grid1.material.vertexColors = false;
        this.grid.add(grid1);

        var grid2:GridHelper = new GridHelper(30, 6);
        grid2.material.color.setHex(GRID_COLORS_LIGHT[1]);
        grid2.material.vertexColors = false;
        this.grid.add(grid2);

        this.viewHelper = new ViewHelper(camera, container);

        //

        var box:Box3 = new Box3();

        this.selectionBox = new Box3Helper(box);
        this.selectionBox.material.depthTest = false;
        this.selectionBox.material.transparent = true;
        this.selectionBox.visible = false;
        this.sceneHelpers.add(this.selectionBox);

        this.transformControls = new TransformControls(camera, container.dom);
        this.transformControls.addEventListener('axis-changed', _ -> {
            if (editor.viewportShading != 'realistic') {
                render();
            }
        });
        this.transformControls.addEventListener('objectChange', _ -> {
            editor.signals.objectChanged.dispatch(transformControls.object);
        });
        this.transformControls.addEventListener('mouseDown', _ -> {
            var object:Dynamic = transformControls.object;

            controls.enabled = false;
        });
        this.transformControls.addEventListener('mouseUp', _ -> {
            var object:Dynamic = transformControls.object;

            if (object != null) {
                switch (transformControls.getMode()) {
                    case 'translate':
                        // if (!objectPositionOnDown.equals(object.position)) {
                        //     editor.execute(new SetPositionCommand(editor, object, object.position, objectPositionOnDown));
                        // }
                    case 'rotate':
                        // if (!objectRotationOnDown.equals(object.rotation)) {
                        //     editor.execute(new SetRotationCommand(editor, object, object.rotation, objectRotationOnDown));
                        // }
                    case 'scale':
                        // if (!objectScaleOnDown.equals(object.scale)) {
                        //     editor.execute(new SetScaleCommand(editor, object, object.scale, objectScaleOnDown));
                        // }
                }
            }

            controls.enabled = true;
        });

        this.sceneHelpers.add(this.transformControls);

        //

        var xr:XR = new XR(editor, this.transformControls); // eslint-disable-line no-unused-vars

        // events

        var onDownPosition:Vector2 = new Vector2();
        var onUpPosition:Vector2 = new Vector2();
        var onDoubleClickPosition:Vector2 = new Vector2();

        this.container.dom.addEventListener('mousedown', e -> {
            // e.preventDefault();

            if (e.target != renderer.domElement) {
                return;
            }

            var array:Array<Float> = getMousePosition(container.dom, e.clientX, e.clientY);
            onDownPosition.fromArray(array);

            Browser.document.addEventListener('mouseup', onMouseUp);
        });

        var onMouseUp = (e) -> {
            var array:Array<Float> = getMousePosition(container.dom, e.clientX, e.clientY);
            onUpPosition.fromArray(array);

            handleClick();

            Browser.document.removeEventListener('mouseup', onMouseUp);
        };

        var onTouchStart = (e) -> {
            var touch:Dynamic = e.changedTouches[0];

            var array:Array<Float> = getMousePosition(container.dom, touch.clientX, touch.clientY);
            onDownPosition.fromArray(array);

            Browser.document.addEventListener('touchend', onTouchEnd);
        };

        var onTouchEnd = (e) -> {
            var touch:Dynamic = e.changedTouches[0];

            var array:Array<Float> = getMousePosition(container.dom, touch.clientX, touch.clientY);
            onUpPosition.fromArray(array);

            handleClick();

            Browser.document.removeEventListener('touchend', onTouchEnd);
        };

        var onDoubleClick = (e) -> {
            var array:Array<Float> = getMousePosition(container.dom, e.clientX, e.clientY);
            onDoubleClickPosition.fromArray(array);

            var intersects:Array<Dynamic> = editor.selector.getPointerIntersects(onDoubleClickPosition, camera);

            if (intersects.length > 0) {
                var intersect:Dynamic = intersects[0];

                editor.signals.objectFocused.dispatch(intersect.object);
            }
        };

        this.container.dom.addEventListener('touchstart', onTouchStart, { passive: false });
        this.container.dom.addEventListener('dblclick', onDoubleClick);

        // controls need to be added *after* main logic,
        // otherwise controls.enabled doesn't work.

        this.controls = new EditorControls(camera, container.dom);
        this.controls.addEventListener('change', _ -> {
            editor.signals.cameraChanged.dispatch(camera);
            editor.signals.refreshSidebarObject3D.dispatch(camera);
        });
        this.viewHelper.center = controls.center;

        // signals

        editor.signals.editorCleared.add(() -> {
            controls.center.set(0, 0, 0);
            pathtracer.reset();

            initPT();
            render();
        });

        editor.signals.transformModeChanged.add(mode -> {
            transformControls.setMode(mode);

            render();
        });

        editor.signals.snapChanged.add(dist -> {
            transformControls.setTranslationSnap(dist);
        });

        editor.signals.spaceChanged.add(space -> {
            transformControls.setSpace(space);

            render();
        });

        editor.signals.rendererUpdated.add(() -> {
            scene.traverse(child -> {
                if (child.material != null) {
                    child.material.needsUpdate = true;
                }
            });

            render();
        });

        editor.signals.rendererCreated.add(newRenderer -> {
            if (renderer != null) {
                renderer.setAnimationLoop(null);
                renderer.dispose();
                pmremGenerator.dispose();

                container.dom.removeChild(renderer.domElement);
            }

            renderer = newRenderer;

            renderer.setAnimationLoop(animate);
            renderer.setClearColor(0xaaaaaa);

            if (Browser.window.matchMedia != null) {
                var mediaQuery:Dynamic = Browser.window.matchMedia('(prefers-color-scheme: dark)');
                mediaQuery.addEventListener('change', e -> {
                    renderer.setClearColor(e.matches ? 0x333333 : 0xaaaaaa);
                    updateGridColors(grid1, grid2, e.matches ? GRID_COLORS_DARK : GRID_COLORS_LIGHT);

                    render();
                });

                renderer.setClearColor(mediaQuery.matches ? 0x333333 : 0xaaaaaa);
                updateGridColors(grid1, grid2, mediaQuery.matches ? GRID_COLORS_DARK : GRID_COLORS_LIGHT);
            }

            renderer.setPixelRatio(Browser.window.devicePixelRatio);
            renderer.setSize(container.dom.offsetWidth, container.dom.offsetHeight);

            pmremGenerator = new three.PMREMGenerator(renderer);
            pmremGenerator.compileEquirectangularShader();

            pathtracer = new ViewportPathtracer(renderer);

            container.dom.appendChild(renderer.domElement);

            render();
        });

        editor.signals.rendererDetectKTX2Support.add(ktx2Loader -> {
            ktx2Loader.detectSupport(renderer);
        });

        editor.signals.sceneGraphChanged.add(() -> {
            initPT();
            render();
        });

        editor.signals.cameraChanged.add(() -> {
            pathtracer.reset();

            render();
        });

        editor.signals.objectSelected.add(object -> {
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

        editor.signals.objectFocused.add(object -> {
            controls.focus(object);
        });

        editor.signals.geometryChanged.add(object -> {
            if (object != null) {
                box.setFromObject(object, true);
            }

            initPT();
            render();
        });

        editor.signals.objectChanged.add(object -> {
            if (editor.selected == object) {
                box.setFromObject(object, true);
            }

            if (Std.is(object, PerspectiveCamera)) {
                (cast object).updateProjectionMatrix();
            } else if (Std.is(object, OrthographicCamera)) {
                (cast object).updateProjectionMatrix();
            }

            var helper:Dynamic = editor.helpers[object.id];

            if (helper != null && !helper.isSkeletonHelper) {
                helper.update();
            }

            initPT();
            render();
        });

        editor.signals.objectRemoved.add(object -> {
            controls.enabled = true; // see #14180

            if (object == transformControls.object) {
                transformControls.detach();
            }
        });

        editor.signals.materialChanged.add(() -> {
            updatePTMaterials();
            render();
        });

        // background

        editor.signals.sceneBackgroundChanged.add((backgroundType, backgroundColor, backgroundTexture,
            backgroundEquirectangularTexture, backgroundBlurriness, backgroundIntensity, backgroundRotation) -> {
            scene.background = null;

            switch (backgroundType) {
                case 'Color':
                    scene.background = new three.Color(backgroundColor);
                case 'Texture':
                    if (backgroundTexture != null) {
                        scene.background = backgroundTexture;
                    }
                case 'Equirectangular':
                    if (backgroundEquirectangularTexture != null) {
                        backgroundEquirectangularTexture.mapping = three.EquirectangularReflectionMapping;

                        scene.background = backgroundEquirectangularTexture;
                        scene.backgroundBlurriness = backgroundBlurriness;
                        scene.backgroundIntensity = backgroundIntensity;
                        scene.backgroundRotation.y = backgroundRotation * Math.PI / 180;

                        if (useBackgroundAsEnvironment) {
                            scene.environment = scene.background;
                            scene.environmentRotation.y = backgroundRotation * Math.PI / 180;
                        }
                    }
            }

            updatePTBackground();
            render();
        });

        // environment

        var useBackgroundAsEnvironment:Bool = false;

        editor.signals.sceneEnvironmentChanged.add((environmentType, environmentEquirectangularTexture) -> {
            scene.environment = null;

            useBackgroundAsEnvironment = false;

            switch (environmentType) {
                case 'Background':
                    useBackgroundAsEnvironment = true;

                    if (scene.background != null && Std.is(scene.background, three.textures.Texture)) {
                        scene.environment = scene.background;
                        scene.environment.mapping = three.EquirectangularReflectionMapping;
                        scene.environmentRotation.y = scene.backgroundRotation.y;
                    }
                case 'Equirectangular':
                    if (environmentEquirectangularTexture != null) {
                        scene.environment = environmentEquirectangularTexture;
                        scene.environment.mapping = three.EquirectangularReflectionMapping;
                    }
                case 'ModelViewer':
                    scene.environment = pmremGenerator.fromScene(new three.environments.RoomEnvironment(), 0.04).texture;
            }

            updatePTEnvironment();
            render();
        });

        // fog

        editor.signals.sceneFogChanged.add((fogType, fogColor, fogNear, fogFar, fogDensity) -> {
            switch (fogType) {
                case 'None':
                    scene.fog = null;
                case 'Fog':
                    scene.fog = new three.Fog(fogColor, fogNear, fogFar);
                case 'FogExp2':
                    scene.fog = new three.FogExp2(fogColor, fogDensity);
            }

            render();
        });

        editor.signals.sceneFogSettingsChanged.add((fogType, fogColor, fogNear, fogFar, fogDensity) -> {
            var fog:Dynamic = scene.fog;

            switch (fogType) {
                case 'Fog':
                    fog.color.setHex(fogColor);
                    fog.near = fogNear;
                    fog.far = fogFar;
                case 'FogExp2':
                    fog.color.setHex(fogColor);
                    fog.density = fogDensity;
            }

            render();
        });

        editor.signals.viewportCameraChanged.add(() -> {
            var viewportCamera:Dynamic = editor.viewportCamera;

            if (Std.is(viewportCamera, PerspectiveCamera)) {
                viewportCamera.aspect = editor.camera.aspect;
                viewportCamera.projectionMatrix.copy(editor.camera.projectionMatrix);
            } else if (Std.is(viewportCamera, OrthographicCamera)) {
                // TODO
            }

            // disable EditorControls when setting a user camera

            controls.enabled = (viewportCamera == editor.camera);

            render();
        });

        editor.signals.viewportShadingChanged.add(() -> {
            var viewportShading:String = editor.viewportShading;

            switch (viewportShading) {
                case 'realistic':
                    pathtracer.init(scene, camera);
                case 'solid':
                    scene.overrideMaterial = null;
                case 'normals':
                    scene.overrideMaterial = new MeshNormalMaterial();
                case 'wireframe':
                    scene.overrideMaterial = new MeshBasicMaterial({ color: 0x000000, wireframe: true });
            }

            render();
        });

        //

        editor.signals.windowResize.add(() -> {
            updateAspectRatio();

            renderer.setSize(container.dom.offsetWidth, container.dom.offsetHeight);
            pathtracer.setSize(container.dom.offsetWidth, container.dom.offsetHeight);

            render();
        });

        editor.signals.showGridChanged.add(value -> {
            grid.visible = value;

            render();
        });

        editor.signals.showHelpersChanged.add(value -> {
            sceneHelpers.visible = value;
            transformControls.enabled = value;

            render();
        });

        editor.signals.cameraResetted.add(updateAspectRatio);
    }

    private function handleClick():Void {
        if (onDownPosition.distanceTo(onUpPosition) == 0) {
            var intersects:Array<Dynamic> = editor.selector.getPointerIntersects(onUpPosition, camera);
            editor.signals.intersectionsDetected.dispatch(intersects);

            render();
        }
    }

    private function getMousePosition(dom:Dynamic, x:Float, y:Float):Array<Float> {
        var rect:Dynamic = dom.getBoundingClientRect();
        return [(x - rect.left) / rect.width, (y - rect.top) / rect.height];
    }

    private function updateAspectRatio():Void {
        camera.aspect = container.dom.offsetWidth / container.dom.offsetHeight;
        camera.updateProjectionMatrix();
    }

    private var prevActionsInUse:Int = 0;

    private var clock:Clock = new Clock(); // only used for animations

    private function animate():Void {
        var mixer:Dynamic = editor.mixer;
        var delta:Float = clock.getDelta();

        var needsUpdate:Bool = false;

        // Animations

        var actions:Dynamic = mixer.stats.actions;

        if (actions.inUse > 0 || prevActionsInUse > 0) {
            prevActionsInUse = actions.inUse;

            mixer.update(delta);
            needsUpdate = true;

            if (editor.selected != null) {
                editor.selected.updateWorldMatrix(false, true);
                selectionBox.box.setFromObject(editor.selected, true);
            }
        }

        // ViewHelper

        if (viewHelper.animating) {
            viewHelper.update(delta);
            needsUpdate = true;
        }

        //

        if (renderer.xr.isPresenting) {
            needsUpdate = true;
        }

        if (needsUpdate) {
            render();
        }

        updatePT();
    }

    private function initPT():Void {
        if (editor.viewportShading == 'realistic') {
            pathtracer.init(scene, camera);
        }
    }

    private function updatePTBackground():Void {
        if (editor.viewportShading == 'realistic') {
            pathtracer.setBackground(scene.background, scene.backgroundBlurriness);
        }
    }

    private function updatePTEnvironment():Void {
        if (editor.viewportShading == 'realistic') {
            pathtracer.setEnvironment(scene.environment);
        }
    }

    private function updatePTMaterials():Void {
        if (editor.viewportShading == 'realistic') {
            pathtracer.updateMaterials();
        }
    }

    private function updatePT():Void {
        if (editor.viewportShading == 'realistic') {
            pathtracer.update();
        }
    }

    //

    private var startTime:Float = 0;
    private var endTime:Float = 0;

    private function render():Void {
        startTime = performance.now();

        //

        renderer.setViewport(0, 0, container.dom.offsetWidth, container.dom.offsetHeight);
        renderer.render(scene, editor.viewportCamera);

        //

        if (camera == editor.viewportCamera) {
            renderer.autoClear = false;
            if (grid.visible)
                renderer.render(grid, camera);
            if (sceneHelpers.visible)
                renderer.render(sceneHelpers, camera);
            if (!renderer.xr.isPresenting)
                viewHelper.render(renderer);
            renderer.autoClear = true;
        }

        //

        endTime = performance.now();
        editor.signals.sceneRendered.dispatch(endTime - startTime);
    }

    private function updateGridColors(grid1:GridHelper, grid2:GridHelper, colors:Array<Int>):Void {
        grid1.material = new LineBasicMaterial({ color: colors[0] });
        grid2.material = new LineBasicMaterial({ color: colors[1] });
    }

}