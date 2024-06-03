import js.Browser.console;
import js.Lib;
import three.core.math.Vector3;
import three.core.object3D.Object3D;
import three.core.object3D.Mesh;
import three.materials.Material;
import three.materials.MeshBasicMaterial;
import three.geometries.BufferGeometry;
import three.geometries.SphereGeometry;
import three.objects.Raycaster;
import three.renderers.shaders.ShaderChunk;

class OculusHandPointerModel extends Object3D {

    public var hand:Dynamic;
    public var controller:Dynamic;
    public var motionController:Dynamic = null;
    public var envMap:Dynamic = null;
    public var mesh:Dynamic = null;
    public var pointerGeometry:BufferGeometry = null;
    public var pointerMesh:Mesh = null;
    public var pointerObject:Object3D = null;
    public var pinched:Bool = false;
    public var attached:Bool = false;
    public var cursorObject:Mesh = null;
    public var raycaster:Raycaster = null;
    public var xrInputSource:Dynamic = null;

    public function new(hand:Dynamic, controller:Dynamic) {
        super();
        this.hand = hand;
        this.controller = controller;
        this.hand.addEventListener('connected', Lib.bind(this, this._onConnected));
        this.hand.addEventListener('disconnected', Lib.bind(this, this._onDisconnected));
    }

    public function _onConnected(event:Dynamic) {
        var xrInputSource = event.data;
        if (xrInputSource.hand) {
            this.visible = true;
            this.xrInputSource = xrInputSource;
            this.createPointer();
        }
    }

    public function _onDisconnected() {
        this.visible = false;
        this.xrInputSource = null;
        if (this.pointerGeometry != null) this.pointerGeometry.dispose();
        if (this.pointerMesh != null && this.pointerMesh.material != null) this.pointerMesh.material.dispose();
        this.clear();
    }

    private function _drawVerticesRing(vertices:Array<Float>, baseVector:Vector3, ringIndex:Int) {
        var segmentVector = baseVector.clone();
        var i = 0;
        while (i < POINTER_SEGMENTS) {
            segmentVector.applyAxisAngle(ZAXIS, (Math.PI * 2) / POINTER_SEGMENTS);
            var vid = ringIndex * POINTER_SEGMENTS + i;
            vertices[3 * vid] = segmentVector.x;
            vertices[3 * vid + 1] = segmentVector.y;
            vertices[3 * vid + 2] = segmentVector.z;
            i++;
        }
    }

    private function _updatePointerVertices(rearRadius:Float) {
        var vertices = this.pointerGeometry.attributes.position.array;
        var frontFaceBase = new Vector3(POINTER_FRONT_RADIUS, 0, -1 * (POINTER_LENGTH - rearRadius));
        this._drawVerticesRing(vertices, frontFaceBase, 0);

        var rearBase = new Vector3(Math.sin((Math.PI * POINTER_HEMISPHERE_ANGLE) / 180) * rearRadius, Math.cos((Math.PI * POINTER_HEMISPHERE_ANGLE) / 180) * rearRadius, 0);
        var i = 0;
        while (i < POINTER_RINGS) {
            this._drawVerticesRing(vertices, rearBase, i + 1);
            rearBase.applyAxisAngle(YAXIS, (Math.PI * POINTER_HEMISPHERE_ANGLE) / 180 / (POINTER_RINGS * -2));
            i++;
        }

        var frontCenterIndex = POINTER_SEGMENTS * (1 + POINTER_RINGS);
        var rearCenterIndex = POINTER_SEGMENTS * (1 + POINTER_RINGS) + 1;
        var frontCenter = new Vector3(0, 0, -1 * (POINTER_LENGTH - rearRadius));
        vertices[frontCenterIndex * 3] = frontCenter.x;
        vertices[frontCenterIndex * 3 + 1] = frontCenter.y;
        vertices[frontCenterIndex * 3 + 2] = frontCenter.z;
        var rearCenter = new Vector3(0, 0, rearRadius);
        vertices[rearCenterIndex * 3] = rearCenter.x;
        vertices[rearCenterIndex * 3 + 1] = rearCenter.y;
        vertices[rearCenterIndex * 3 + 2] = rearCenter.z;

        this.pointerGeometry.setAttribute('position', new Float32Array(vertices));
    }

    public function createPointer() {
        var vertices = new Array<Float>((POINTER_RINGS + 1) * POINTER_SEGMENTS + 2 * 3).fill(0);
        var indices = new Array<Int>();
        this.pointerGeometry = new BufferGeometry();

        this.pointerGeometry.setAttribute('position', new Float32Array(vertices));

        this._updatePointerVertices(POINTER_REAR_RADIUS);

        var i = 0;
        while (i < POINTER_RINGS) {
            var j = 0;
            while (j < POINTER_SEGMENTS - 1) {
                indices.push(i * POINTER_SEGMENTS + j, i * POINTER_SEGMENTS + j + 1, (i + 1) * POINTER_SEGMENTS + j);
                indices.push(i * POINTER_SEGMENTS + j + 1, (i + 1) * POINTER_SEGMENTS + j + 1, (i + 1) * POINTER_SEGMENTS + j);
                j++;
            }
            indices.push((i + 1) * POINTER_SEGMENTS - 1, i * POINTER_SEGMENTS, (i + 2) * POINTER_SEGMENTS - 1);
            indices.push(i * POINTER_SEGMENTS, (i + 1) * POINTER_SEGMENTS, (i + 2) * POINTER_SEGMENTS - 1);
            i++;
        }

        var frontCenterIndex = POINTER_SEGMENTS * (1 + POINTER_RINGS);
        var rearCenterIndex = POINTER_SEGMENTS * (1 + POINTER_RINGS) + 1;

        i = 0;
        while (i < POINTER_SEGMENTS - 1) {
            indices.push(frontCenterIndex, i + 1, i);
            indices.push(rearCenterIndex, i + POINTER_SEGMENTS * POINTER_RINGS, i + POINTER_SEGMENTS * POINTER_RINGS + 1);
            i++;
        }

        indices.push(frontCenterIndex, 0, POINTER_SEGMENTS - 1);
        indices.push(rearCenterIndex, POINTER_SEGMENTS * (POINTER_RINGS + 1) - 1, POINTER_SEGMENTS * POINTER_RINGS);

        var material = new MeshBasicMaterial();
        material.transparent = true;
        material.opacity = POINTER_OPACITY_MIN;

        this.pointerGeometry.setIndex(indices);

        this.pointerMesh = new Mesh(this.pointerGeometry, material);

        this.pointerMesh.position.set(0, 0, -1 * POINTER_REAR_RADIUS);
        this.pointerObject = new Object3D();
        this.pointerObject.add(this.pointerMesh);

        this.raycaster = new Raycaster();

        var cursorGeometry = new SphereGeometry(CURSOR_RADIUS, 10, 10);
        var cursorMaterial = new MeshBasicMaterial();
        cursorMaterial.transparent = true;
        cursorMaterial.opacity = POINTER_OPACITY_MIN;

        this.cursorObject = new Mesh(cursorGeometry, cursorMaterial);
        this.pointerObject.add(this.cursorObject);

        this.add(this.pointerObject);
    }

    private function _updateRaycaster() {
        if (this.raycaster != null) {
            var pointerMatrix = this.pointerObject.matrixWorld;
            var tempMatrix = new Matrix4();
            tempMatrix.identity().extractRotation(pointerMatrix);
            this.raycaster.ray.origin.setFromMatrixPosition(pointerMatrix);
            this.raycaster.ray.direction.set(0, 0, -1).applyMatrix4(tempMatrix);
        }
    }

    private function _updatePointer() {
        this.pointerObject.visible = this.controller.visible;
        var indexTip = this.hand.joints['index-finger-tip'];
        var thumbTip = this.hand.joints['thumb-tip'];
        var distance = indexTip.position.distanceTo(thumbTip.position);
        var position = indexTip.position.clone().add(thumbTip.position).multiplyScalar(0.5);
        this.pointerObject.position.copy(position);
        this.pointerObject.quaternion.copy(this.controller.quaternion);

        this.pinched = distance <= PINCH_THRESHOLD;

        var pinchScale = (distance - PINCH_MIN) / (PINCH_MAX - PINCH_MIN);
        var focusScale = (distance - PINCH_MIN) / (PINCH_THRESHOLD - PINCH_MIN);
        if (pinchScale > 1) {
            this._updatePointerVertices(POINTER_REAR_RADIUS);
            this.pointerMesh.position.set(0, 0, -1 * POINTER_REAR_RADIUS);
            this.pointerMesh.material.opacity = POINTER_OPACITY_MIN;
        } else if (pinchScale > 0) {
            var rearRadius = (POINTER_REAR_RADIUS - POINTER_REAR_RADIUS_MIN) * pinchScale + POINTER_REAR_RADIUS_MIN;
            this._updatePointerVertices(rearRadius);
            if (focusScale < 1) {
                this.pointerMesh.position.set(0, 0, -1 * rearRadius - (1 - focusScale) * POINTER_ADVANCE_MAX);
                this.pointerMesh.material.opacity = POINTER_OPACITY_MIN + (1 - focusScale) * (POINTER_OPACITY_MAX - POINTER_OPACITY_MIN);
            } else {
                this.pointerMesh.position.set(0, 0, -1 * rearRadius);
                this.pointerMesh.material.opacity = POINTER_OPACITY_MIN;
            }
        } else {
            this._updatePointerVertices(POINTER_REAR_RADIUS_MIN);
            this.pointerMesh.position.set(0, 0, -1 * POINTER_REAR_RADIUS_MIN - POINTER_ADVANCE_MAX);
            this.pointerMesh.material.opacity = POINTER_OPACITY_MAX;
        }

        this.cursorObject.material.opacity = this.pointerMesh.material.opacity;
    }

    override public function updateMatrixWorld(force:Bool = false) {
        super.updateMatrixWorld(force);
        if (this.pointerGeometry != null) {
            this._updatePointer();
            this._updateRaycaster();
        }
    }

    public function isPinched():Bool {
        return this.pinched;
    }

    public function setAttached(attached:Bool) {
        this.attached = attached;
    }

    public function isAttached():Bool {
        return this.attached;
    }

    public function intersectObject(object:Object3D, recursive:Bool = true):Array<Intersection> {
        if (this.raycaster != null) {
            return this.raycaster.intersectObject(object, recursive);
        }
        return null;
    }

    public function intersectObjects(objects:Array<Object3D>, recursive:Bool = true):Array<Intersection> {
        if (this.raycaster != null) {
            return this.raycaster.intersectObjects(objects, recursive);
        }
        return null;
    }

    public function checkIntersections(objects:Array<Object3D>, recursive:Bool = false) {
        if (this.raycaster != null && !this.attached) {
            var intersections = this.raycaster.intersectObjects(objects, recursive);
            var direction = new Vector3(0, 0, -1);
            if (intersections.length > 0) {
                var intersection = intersections[0];
                var distance = intersection.distance;
                this.cursorObject.position.copy(direction.multiplyScalar(distance));
            } else {
                this.cursorObject.position.copy(direction.multiplyScalar(CURSOR_MAX_DISTANCE));
            }
        }
    }

    public function setCursor(distance:Float) {
        var direction = new Vector3(0, 0, -1);
        if (this.raycaster != null && !this.attached) {
            this.cursorObject.position.copy(direction.multiplyScalar(distance));
        }
    }

    public function dispose() {
        this._onDisconnected();
        this.hand.removeEventListener('connected', Lib.bind(this, this._onConnected));
        this.hand.removeEventListener('disconnected', Lib.bind(this, this._onDisconnected));
    }
}

// Constants
var PINCH_MAX = 0.05;
var PINCH_THRESHOLD = 0.02;
var PINCH_MIN = 0.01;
var POINTER_ADVANCE_MAX = 0.02;
var POINTER_OPACITY_MAX = 1;
var POINTER_OPACITY_MIN = 0.4;
var POINTER_FRONT_RADIUS = 0.002;
var POINTER_REAR_RADIUS = 0.01;
var POINTER_REAR_RADIUS_MIN = 0.003;
var POINTER_LENGTH = 0.035;
var POINTER_SEGMENTS = 16;
var POINTER_RINGS = 12;
var POINTER_HEMISPHERE_ANGLE = 110;
var YAXIS = new Vector3(0, 1, 0);
var ZAXIS = new Vector3(0, 0, 1);
var CURSOR_RADIUS = 0.02;
var CURSOR_MAX_DISTANCE = 1.5;