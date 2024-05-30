import three.js.examples.jsm.controls.ArcballControls;
import three.js.examples.jsm.controls.ArcballControls.STATE;
import three.js.examples.jsm.controls.ArcballControls.INPUT;
import three.js.examples.jsm.controls.ArcballControls.EventDispatcher;
import three.js.examples.jsm.controls.ArcballControls.GridHelper;
import three.js.examples.jsm.controls.ArcballControls.EllipseCurve;
import three.js.examples.jsm.controls.ArcballControls.BufferGeometry;
import three.js.examples.jsm.controls.ArcballControls.Line;
import three.js.examples.jsm.controls.ArcballControls.LineBasicMaterial;
import three.js.examples.jsm.controls.ArcballControls.Raycaster;
import three.js.examples.jsm.controls.ArcballControls.Group;
import three.js.examples.jsm.controls.ArcballControls.Box3;
import three.js.examples.jsm.controls.ArcballControls.Sphere;
import three.js.examples.jsm.controls.ArcballControls.Quaternion;
import three.js.examples.jsm.controls.ArcballControls.Vector2;
import three.js.examples.jsm.controls.ArcballControls.Vector3;
import three.js.examples.jsm.controls.ArcballControls.Matrix4;
import three.js.examples.jsm.controls.ArcballControls.MathUtils;
import three.js.examples.jsm.controls.ArcballControls.Event;

class Main {
    static function main() {
        var camera = new ArcballControls.Camera();
        var domElement = new ArcballControls.HTMLElement();
        var scene = new ArcballControls.Scene();

        var arcballControls = new ArcballControls(camera, domElement, scene);

        arcballControls.onSinglePanStart(new Event("start"), "PAN");
        arcballControls.onSinglePanMove(new Event("move"), STATE.PAN);
    }
}