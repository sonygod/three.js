import three.THREE;

class OculusHandPointerModel extends THREE.Object3D {

    static var PINCH_MAX:Float = 0.05;
    static var PINCH_THRESHOLD:Float = 0.02;
    static var PINCH_MIN:Float = 0.01;
    static var POINTER_ADVANCE_MAX:Float = 0.02;
    static var POINTER_OPACITY_MAX:Float = 1;
    static var POINTER_OPACITY_MIN:Float = 0.4;
    static var POINTER_FRONT_RADIUS:Float = 0.002;
    static var POINTER_REAR_RADIUS:Float = 0.01;
    static var POINTER_REAR_RADIUS_MIN:Float = 0.003;
    static var POINTER_LENGTH:Float = 0.035;
    static var POINTER_SEGMENTS:Int = 16;
    static var POINTER_RINGS:Int = 12;
    static var POINTER_HEMISPHERE_ANGLE:Float = 110;
    static var YAXIS:THREE.Vector3 = new THREE.Vector3( 0, 1, 0 );
    static var ZAXIS:THREE.Vector3 = new THREE.Vector3( 0, 0, 1 );

    static var CURSOR_RADIUS:Float = 0.02;
    static var CURSOR_MAX_DISTANCE:Float = 1.5;

    var hand:Dynamic;
    var controller:Dynamic;
    var motionController:Dynamic;
    var envMap:Dynamic;
    var mesh:Dynamic;
    var pointerGeometry:Dynamic;
    var pointerMesh:Dynamic;
    var pointerObject:Dynamic;
    var pinched:Bool;
    var attached:Bool;
    var cursorObject:Dynamic;
    var raycaster:Dynamic;
    var xrInputSource:Dynamic;

    public function new(hand:Dynamic, controller:Dynamic) {
        super();
        this.hand = hand;
        this.controller = controller;
        this.motionController = null;
        this.envMap = null;
        this.mesh = null;
        this.pointerGeometry = null;
        this.pointerMesh = null;
        this.pointerObject = null;
        this.pinched = false;
        this.attached = false;
        this.cursorObject = null;
        this.raycaster = null;
        this.hand.addEventListener('connected', this._onConnected);
        this.hand.addEventListener('disconnected', this._onDisconnected);
    }

    private function _onConnected(event:Dynamic):Void {
        this.xrInputSource = event.data;
        if (this.xrInputSource.hand) {
            this.visible = true;
            this.createPointer();
        }
    }

    private function _onDisconnected():Void {
        this.visible = false;
        this.xrInputSource = null;
        if (this.pointerGeometry) this.pointerGeometry.dispose();
        if (this.pointerMesh && this.pointerMesh.material) this.pointerMesh.material.dispose();
        this.clear();
    }

    private function _drawVerticesRing(vertices:Array<Float>, baseVector:THREE.Vector3, ringIndex:Int):Void {
        var segmentVector:THREE.Vector3 = baseVector.clone();
        for (i in 0...POINTER_SEGMENTS) {
            segmentVector.applyAxisAngle(ZAXIS, (Math.PI * 2) / POINTER_SEGMENTS);
            var vid:Int = ringIndex * POINTER_SEGMENTS + i;
            vertices[3 * vid] = segmentVector.x;
            vertices[3 * vid + 1] = segmentVector.y;
            vertices[3 * vid + 2] = segmentVector.z;
        }
    }

    private function _updatePointerVertices(rearRadius:Float):Void {
        var vertices:Array<Float> = this.pointerGeometry.attributes.position.array;
        var frontFaceBase:THREE.Vector3 = new THREE.Vector3(
            POINTER_FRONT_RADIUS,
            0,
            -1 * (POINTER_LENGTH - rearRadius)
        );
        this._drawVerticesRing(vertices, frontFaceBase, 0);
        var rearBase:THREE.Vector3 = new THREE.Vector3(
            Math.sin((Math.PI * POINTER_HEMISPHERE_ANGLE) / 180) * rearRadius,
            Math.cos((Math.PI * POINTER_HEMISPHERE_ANGLE) / 180) * rearRadius,
            0
        );
        for (i in 0...POINTER_RINGS) {
            this._drawVerticesRing(vertices, rearBase, i + 1);
            rearBase.applyAxisAngle(
                YAXIS,
                (Math.PI * POINTER_HEMISPHERE_ANGLE) / 180 / (POINTER_RINGS * -2)
            );
        }
        var frontCenterIndex:Int = POINTER_SEGMENTS * (1 + POINTER_RINGS);
        var rearCenterIndex:Int = POINTER_SEGMENTS * (1 + POINTER_RINGS) + 1;
        var frontCenter:THREE.Vector3 = new THREE.Vector3(
            0,
            0,
            -1 * (POINTER_LENGTH - rearRadius)
        );
        vertices[frontCenterIndex * 3] = frontCenter.x;
        vertices[frontCenterIndex * 3 + 1] = frontCenter.y;
        vertices[frontCenterIndex * 3 + 2] = frontCenter.z;
        var rearCenter:THREE.Vector3 = new THREE.Vector3(0, 0, rearRadius);
        vertices[rearCenterIndex * 3] = rearCenter.x;
        vertices[rearCenterIndex * 3 + 1] = rearCenter.y;
        vertices[rearCenterIndex * 3 + 2] = rearCenter.z;
        this.pointerGeometry.setAttribute(
            'position',
            new THREE.Float32BufferAttribute(vertices, 3)
        );
    }

    private function createPointer():Void {
        var vertices:Array<Float> = new Array(((POINTER_RINGS + 1) * POINTER_SEGMENTS + 2) * 3).fill(0);
        var indices:Array<Int> = [];
        this.pointerGeometry = new THREE.BufferGeometry();
        this.pointerGeometry.setAttribute(
            'position',
            new THREE.Float32BufferAttribute(vertices, 3)
        );
        this._updatePointerVertices(POINTER_REAR_RADIUS);
        for (i in 0...POINTER_RINGS) {
            for (j in 0...POINTER_SEGMENTS - 1) {
                indices.push(
                    i * POINTER_SEGMENTS + j,
                    i * POINTER_SEGMENTS + j + 1,
                    (i + 1) * POINTER_SEGMENTS + j
                );
                indices.push(
                    i * POINTER_SEGMENTS + j + 1,
                    (i + 1) * POINTER_SEGMENTS + j + 1,
                    (i + 1) * POINTER_SEGMENTS + j
                );
            }
            indices.push(
                (i + 1) * POINTER_SEGMENTS - 1,
                i * POINTER_SEGMENTS,
                (i + 2) * POINTER_SEGMENTS - 1
            );
            indices.push(
                i * POINTER_SEGMENTS,
                (i + 1) * POINTER_SEGMENTS,
                (i + 2) * POINTER_SEGMENTS - 1
            );
        }
        var frontCenterIndex:Int = POINTER_SEGMENTS * (1 + POINTER_RINGS);
        var rearCenterIndex:Int = POINTER_SEGMENTS * (1 + POINTER_RINGS) + 1;
        for (i in 0...POINTER_SEGMENTS - 1) {
            indices.push(frontCenterIndex, i + 1, i);
            indices.push(
                rearCenterIndex,
                i + POINTER_SEGMENTS * POINTER_RINGS,
                i + POINTER_SEGMENTS * POINTER_RINGS + 1
            );
        }
        indices.push(frontCenterIndex, 0, POINTER_SEGMENTS - 1);
        indices.push(
            rearCenterIndex,
            POINTER_SEGMENTS * (POINTER_RINGS + 1) - 1,
            POINTER_SEGMENTS * POINTER_RINGS
        );
        var material:THREE.MeshBasicMaterial = new THREE.MeshBasicMaterial();
        material.transparent = true;
        material.opacity = POINTER_OPACITY_MIN;
        this.pointerGeometry.setIndex(indices);
        this.pointerMesh = new THREE.Mesh(this.pointerGeometry, material);
        this.pointerMesh.position.set(0, 0, -1 * POINTER_REAR_RADIUS);
        this.pointerObject = new THREE.Object3D();
        this.pointerObject.add(this.pointerMesh);
        this.raycaster = new THREE.Raycaster();
        var cursorGeometry:THREE.SphereGeometry = new THREE.SphereGeometry(CURSOR_RADIUS, 10, 10);
        var cursorMaterial:THREE.MeshBasicMaterial = new THREE.MeshBasicMaterial();
        cursorMaterial.transparent = true;
        cursorMaterial.opacity = POINTER_OPACITY_MIN;
        this.cursorObject = new THREE.Mesh(cursorGeometry, cursorMaterial);
        this.pointerObject.add(this.cursorObject);
        this.add(this.pointerObject);
    }

    private function _updateRaycaster():Void {
        if (this.raycaster) {
            var pointerMatrix:THREE.Matrix4 = this.pointerObject.matrixWorld;
            var tempMatrix:THREE.Matrix4 = new THREE.Matrix4();
            tempMatrix.identity().extractRotation(pointerMatrix);
            this.raycaster.ray.origin.setFromMatrixPosition(pointerMatrix);
            this.raycaster.ray.direction.set(0, 0, -1).applyMatrix4(tempMatrix);
        }
    }

    private function _updatePointer():Void {
        this.pointerObject.visible = this.controller.visible;
        var indexTip:Dynamic = this.hand.joints['index-finger-tip'];
        var thumbTip:Dynamic = this.hand.joints['thumb-tip'];
        var distance:Float = indexTip.position.distanceTo(thumbTip.position);
        var position:THREE.Vector3 = indexTip.position
            .clone()
            .add(thumbTip.position)
            .multiplyScalar(0.5);
        this.pointerObject.position.copy(position);
        this.pointerObject.quaternion.copy(this.controller.quaternion);
        this.pinched = distance <= PINCH_THRESHOLD;
        var pinchScale:Float = (distance - PINCH_MIN) / (PINCH_MAX - PINCH_MIN);
        var focusScale:Float = (distance - PINCH_MIN) / (PINCH_THRESHOLD - PINCH_MIN);
        if (pinchScale > 1) {
            this._updatePointerVertices(POINTER_REAR_RADIUS);
            this.pointerMesh.position.set(0, 0, -1 * POINTER_REAR_RADIUS);
            this.pointerMesh.material.opacity = POINTER_OPACITY_MIN;
        } else if (pinchScale > 0) {
            var rearRadius:Float =
                (POINTER_REAR_RADIUS - POINTER_REAR_RADIUS_MIN) * pinchScale + POINTER_REAR_RADIUS_MIN;
            this._updatePointerVertices(rearRadius);
            if (focusScale < 1) {
                this.pointerMesh.position.set(
                    0,
                    0,
                    -1 * rearRadius - (1 - focusScale) * POINTER_ADVANCE_MAX
                );
                this.pointerMesh.material.opacity =
                    POINTER_OPACITY_MIN + (1 - focusScale) * (POINTER_OPACITY_MAX - POINTER_OPACITY_MIN);
            } else {
                this.pointerMesh.position.set(0, 0, -1 * rearRadius);
                this.pointerMesh.material.opacity = POINTER_OPACITY_MIN;
            }
        } else {
            this._updatePointerVertices(POINTER_REAR_RADIUS_MIN);
            this.pointerMesh.position.set(
                0,
                0,
                -1 * POINTER_REAR_RADIUS_MIN - POINTER_ADVANCE_MAX
            );
            this.pointerMesh.material.opacity = POINTER_OPACITY_MAX;
        }
        this.cursorObject.material.opacity = this.pointerMesh.material.opacity;
    }

    override function updateMatrixWorld(force:Bool):Void {
        super.updateMatrixWorld(force);
        if (this.pointerGeometry) {
            this._updatePointer();
            this._updateRaycaster();
        }
    }

    public function isPinched():Bool {
        return this.pinched;
    }

    public function setAttached(attached:Bool):Void {
        this.attached = attached;
    }

    public function isAttached():Bool {
        return this.attached;
    }

    public function intersectObject(object:Dynamic, recursive:Bool = true):Array<Dynamic> {
        if (this.raycaster) {
            return this.raycaster.intersectObject(object, recursive);
        }
        return [];
    }

    public function intersectObjects(objects:Array<Dynamic>, recursive:Bool = true):Array<Dynamic> {
        if (this.raycaster) {
            return this.raycaster.intersectObjects(objects, recursive);
        }
        return [];
    }

    public function checkIntersections(objects:Array<Dynamic>, recursive:Bool = false):Void {
        if (this.raycaster && !this.attached) {
            var intersections:Array<Dynamic> = this.raycaster.intersectObjects(objects, recursive);
            var direction:THREE.Vector3 = new THREE.Vector3(0, 0, -1);
            if (intersections.length > 0) {
                var intersection:Dynamic = intersections[0];
                var distance:Float = intersection.distance;
                this.cursorObject.position.copy(direction.multiplyScalar(distance));
            } else {
                this.cursorObject.position.copy(direction.multiplyScalar(CURSOR_MAX_DISTANCE));
            }
        }
    }

    public function setCursor(distance:Float):Void {
        var direction:THREE.Vector3 = new THREE.Vector3(0, 0, -1);
        if (this.raycaster && !this.attached) {
            this.cursorObject.position.copy(direction.multiplyScalar(distance));
        }
    }

    public function dispose():Void {
        this._onDisconnected();
        this.hand.removeEventListener('connected', this._onConnected);
        this.hand.removeEventListener('disconnected', this._onDisconnected);
    }

}