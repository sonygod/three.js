package three.js.examples.jsm.controls;

import three.js.Lib;
import three.js.math.Euler;
import three.js.math.Matrix4;
import three.js.math.Quaternion;
import three.js.math.Sphere;
import three.js.math.Vector2;
import three.js.math.Vector3;
import three.js.objects.Group;
import three.js.renderers.EventDispatcher;

class ArcballControls extends EventDispatcher {
    public var camera:three.js.Camera;
    public var domElement:HTMLElement;
    public var scene:three.js.Scene;

    // ...

    public function new(camera:three.js.Camera, domElement:HTMLElement, scene:three.js.Scene = null) {
        super();
        this.camera = camera;
        this.domElement = domElement;
        this.scene = scene;
        // ...

        this.setCamera(camera);

        if (scene != null) {
            scene.add(this._gizmos);
        }

        this.domElement.style.touchAction = 'none';
        this._devPxRatio = Lib.window.devicePixelRatio;

        this.initializeMouseActions();

        this._onContextMenu = onContextMenu.bind(this);
        this._onWheel = onWheel.bind(this);
        this._onPointerUp = onPointerUp.bind(this);
        this._onPointerMove = onPointerMove.bind(this);
        this._onPointerDown = onPointerDown.bind(this);
        this._onPointerCancel = onPointerCancel.bind(this);
        this._onWindowResize = onWindowResize.bind(this);

        this.domElement.addEventListener('contextmenu', this._onContextMenu);
        this.domElement.addEventListener('wheel', this._onWheel);
        this.domElement.addEventListener('pointerdown', this._onPointerDown);
        this.domElement.addEventListener('pointercancel', this._onPointerCancel);

        Lib.window.addEventListener('resize', this._onWindowResize);
    }

    public function onSinglePanStart(event:Dynamic, operation:String):Void {
        // ...
    }

    public function onSinglePanMove(event:Dynamic, opState:Int):Void {
        // ...
    }
}