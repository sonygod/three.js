package three.js.examples.webxr;

import three.js.Lib;

class OculusHandPointerModel extends Object3D {
    public var hand:Dynamic;
    public var controller:Dynamic;
    public var motionController:Null<Dynamic>;
    public var envMap:Null<Dynamic>;
    public var mesh:Null<Dynamic>;
    public var pointerGeometry:Null<BufferGeometry>;
    public var pointerMesh:Null<Mesh>;
    public var pointerObject:Null<Object3D>;
    public var pinched:Bool;
    public var attached:Bool;
    public var cursorObject:Null<Object3D>;
    public var raycaster:Null<Raycaster>;
    public var xrInputSource:Null<Dynamic>;

    private var _onConnected:Dynamic;
    private var _onDisconnected:Dynamic;

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

        _onConnected = function(event:Dynamic) {
            if (event.data.hand) {
                visible = true;
                xrInputSource = event.data;
                createPointer();
            }
        };

        _onDisconnected = function() {
            visible = false;
            xrInputSource = null;
            if (pointerGeometry != null) pointerGeometry.dispose();
            if (pointerMesh != null && pointerMesh.material != null) pointerMesh.material.dispose();
            clear();
        };

        hand.addEventListener('connected', _onConnected);
        hand.addEventListener('disconnected', _onDisconnected);
    }

    private function _drawVerticesRing(vertices:Array<Float>, baseVector:Vector3, ringIndex:Int) {
        var segmentVector:Vector3 = baseVector.clone();
        for (i in 0...POINTER_SEGMENTS) {
            segmentVector.applyAxisAngle(ZAXIS, Math.PI * 2 / POINTER_SEGMENTS);
            var vid:Int = ringIndex * POINTER_SEGMENTS + i;
            vertices[3 * vid] = segmentVector.x;
            vertices[3 * vid + 1] = segmentVector.y;
            vertices[3 * vid + 2] = segmentVector.z;
        }
    }

    private function _updatePointerVertices(rearRadius:Float) {
        var vertices:Array<Float> = pointerGeometry.getAttribute('position').array;
        // first ring for front face
        var frontFaceBase:Vector3 = new Vector3(
            POINTER_FRONT_RADIUS,
            0,
            -1 * (POINTER_LENGTH - rearRadius)
        );
        _drawVerticesRing(vertices, frontFaceBase, 0);

        // rings for rear hemisphere
        var rearBase:Vector3 = new Vector3(
            Math.sin(Math.PI * POINTER_HEMISPHERE_ANGLE / 180) * rearRadius,
            Math.cos(Math.PI * POINTER_HEMISPHERE_ANGLE / 180) * rearRadius,
            0
        );
        for (i in 0...POINTER_RINGS) {
            _drawVerticesRing(vertices, rearBase, i + 1);
            rearBase.applyAxisAngle(YAXIS, Math.PI * POINTER_HEMISPHERE_ANGLE / 180 / (POINTER_RINGS * -2));
        }

        // front and rear face center vertices
        var frontCenterIndex:Int = POINTER_SEGMENTS * (1 + POINTER_RINGS);
        var rearCenterIndex:Int = POINTER_SEGMENTS * (1 + POINTER_RINGS) + 1;
        var frontCenter:Vector3 = new Vector3(
            0,
            0,
            -1 * (POINTER_LENGTH - rearRadius)
        );
        vertices[frontCenterIndex * 3] = frontCenter.x;
        vertices[frontCenterIndex * 3 + 1] = frontCenter.y;
        vertices[frontCenterIndex * 3 + 2] = frontCenter.z;
        var rearCenter:Vector3 = new Vector3(0, 0, rearRadius);
        vertices[rearCenterIndex * 3] = rearCenter.x;
        vertices[rearCenterIndex * 3 + 1] = rearCenter.y;
        vertices[rearCenterIndex * 3 + 2] = rearCenter.z;

        pointerGeometry.setAttribute('position', new Float32BufferAttribute(vertices, 3));
    }

    public function createPointer() {
        var i:Int, j:Int;
        var vertices:Array<Float> = [for (i in 0...(POINTER_RINGS + 1) * POINTER_SEGMENTS + 2) 0.0];
        var indices:Array<Int> = [];
        pointerGeometry = new BufferGeometry();
        pointerGeometry.setAttribute('position', new Float32BufferAttribute(vertices, 3));

        _updatePointerVertices(POINTER_REAR_RADIUS);

        // construct faces to connect rings
        for (i in 0...POINTER_RINGS) {
            for (j in 0...POINTER_SEGMENTS - 1) {
                indices.push(i * POINTER_SEGMENTS + j);
                indices.push(i * POINTER_SEGMENTS + j + 1);
                indices.push((i + 1) * POINTER_SEGMENTS + j);
                indices.push(i * POINTER_SEGMENTS + j + 1);
                indices.push((i + 1) * POINTER_SEGMENTS + j + 1);
                indices.push((i + 1) * POINTER_SEGMENTS + j);
            }
            indices.push((i + 1) * POINTER_SEGMENTS - 1);
            indices.push(i * POINTER_SEGMENTS);
            indices.push((i + 2) * POINTER_SEGMENTS - 1);
            indices.push(i * POINTER_SEGMENTS);
            indices.push((i + 1) * POINTER_SEGMENTS);
            indices.push((i + 2) * POINTER_SEGMENTS - 1);
        }

        // construct front and rear face
        var frontCenterIndex:Int = POINTER_SEGMENTS * (1 + POINTER_RINGS);
        var rearCenterIndex:Int = POINTER_SEGMENTS * (1 + POINTER_RINGS) + 1;

        for (i in 0...POINTER_SEGMENTS - 1) {
            indices.push(frontCenterIndex);
            indices.push(i + 1);
            indices.push(i);
            indices.push(rearCenterIndex);
            indices.push(i + POINTER_SEGMENTS * POINTER_RINGS);
            indices.push(i + POINTER_SEGMENTS * POINTER_RINGS + 1);
        }
        indices.push(frontCenterIndex);
        indices.push(0);
        indices.push(POINTER_SEGMENTS - 1);
        indices.push(rearCenterIndex);
        indices.push(POINTER_SEGMENTS * (POINTER_RINGS + 1) - 1);
        indices.push(POINTER_SEGMENTS * POINTER_RINGS);

        var material:MeshBasicMaterial = new MeshBasicMaterial();
        material.transparent = true;
        material.opacity = POINTER_OPACITY_MIN;

        pointerGeometry.setIndex(indices);

        pointerMesh = new Mesh(pointerGeometry, material);

        pointerMesh.position.set(0, 0, -1 * POINTER_REAR_RADIUS);
        pointerObject = new Object3D();
        pointerObject.add(pointerMesh);

        raycaster = new Raycaster();

        // create cursor
        var cursorGeometry:SphereGeometry = new SphereGeometry(CURSOR_RADIUS, 10, 10);
        var cursorMaterial:MeshBasicMaterial = new MeshBasicMaterial();
        cursorMaterial.transparent = true;
        cursorMaterial.opacity = POINTER_OPACITY_MIN;

        cursorObject = new Mesh(cursorGeometry, cursorMaterial);
        pointerObject.add(cursorObject);

        add(pointerObject);
    }

    private function _updateRaycaster() {
        if (raycaster != null) {
            var pointerMatrix:Matrix4 = pointerObject.matrixWorld;
            var tempMatrix:Matrix4 = new Matrix4();
            tempMatrix.identity().extractRotation(pointerMatrix);
            raycaster.ray.origin.setFromMatrixPosition(pointerMatrix);
            raycaster.ray.direction.set(0, 0, -1).applyMatrix4(tempMatrix);
        }
    }

    public function _updatePointer() {
        pointerObject.visible = controller.visible;
        var indexTip:Vector3 = hand.joints['index-finger-tip'].position;
        var thumbTip:Vector3 = hand.joints['thumb-tip'].position;
        var distance:Float = indexTip.distanceTo(thumbTip);
        var position:Vector3 = indexTip.clone().add(thumbTip).multiplyScalar(0.5);
        pointerObject.position.copy(position);
        pointerObject.quaternion.copy(controller.quaternion);

        pinched = distance <= PINCH_THRESHOLD;

        var pinchScale:Float = (distance - PINCH_MIN) / (PINCH_MAX - PINCH_MIN);
        var focusScale:Float = (distance - PINCH_MIN) / (PINCH_THRESHOLD - PINCH_MIN);
        if (pinchScale > 1) {
            _updatePointerVertices(POINTER_REAR_RADIUS);
            pointerMesh.position.set(0, 0, -1 * POINTER_REAR_RADIUS);
            pointerMesh.material.opacity = POINTER_OPACITY_MIN;
        } else if (pinchScale > 0) {
            var rearRadius:Float = (POINTER_REAR_RADIUS - POINTER_REAR_RADIUS_MIN) * pinchScale + POINTER_REAR_RADIUS_MIN;
            _updatePointerVertices(rearRadius);
            if (focusScale < 1) {
                pointerMesh.position.set(
                    0,
                    0,
                    -1 * rearRadius - (1 - focusScale) * POINTER_ADVANCE_MAX
                );
                pointerMesh.material.opacity =
                    POINTER_OPACITY_MIN + (1 - focusScale) * (POINTER_OPACITY_MAX - POINTER_OPACITY_MIN);
            } else {
                pointerMesh.position.set(0, 0, -1 * rearRadius);
                pointerMesh.material.opacity = POINTER_OPACITY_MIN;
            }
        } else {
            _updatePointerVertices(POINTER_REAR_RADIUS_MIN);
            pointerMesh.position.set(
                0,
                0,
                -1 * POINTER_REAR_RADIUS_MIN - POINTER_ADVANCE_MAX
            );
            pointerMesh.material.opacity = POINTER_OPACITY_MAX;
        }

        cursorObject.material.opacity = pointerMesh.material.opacity;
    }

    override public function updateMatrixWorld(force:Bool) {
        super.updateMatrixWorld(force);
        if (pointerGeometry != null) {
            _updatePointer();
            _updateRaycaster();
        }
    }

    public function isPinched():Bool {
        return pinched;
    }

    public function setAttached(attached:Bool) {
        this.attached = attached;
    }

    public function isAttached():Bool {
        return attached;
    }

    public function intersectObject(object:Dynamic, recursive:Bool = true):Array<Intersection> {
        if (raycaster != null) {
            return raycaster.intersectObject(object, recursive);
        }
        return [];
    }

    public function intersectObjects(objects:Array<Dynamic>, recursive:Bool = true):Array<Intersection> {
        if (raycaster != null) {
            return raycaster.intersectObjects(objects, recursive);
        }
        return [];
    }

    public function checkIntersections(objects:Array<Dynamic>, recursive:Bool = false) {
        if (raycaster != null && !attached) {
            var intersections:Array<Intersection> = raycaster.intersectObjects(objects, recursive);
            var direction:Vector3 = new Vector3(0, 0, -1);
            if (intersections.length > 0) {
                var intersection:Intersection = intersections[0];
                var distance:Float = intersection.distance;
                cursorObject.position.copy(direction.multiplyScalar(distance));
            } else {
                cursorObject.position.copy(direction.multiplyScalar(CURSOR_MAX_DISTANCE));
            }
        }
    }

    public function setCursor(distance:Float) {
        var direction:Vector3 = new Vector3(0, 0, -1);
        if (raycaster != null && !attached) {
            cursorObject.position.copy(direction.multiplyScalar(distance));
        }
    }

    public function dispose() {
        _onDisconnected();
        hand.removeEventListener('connected', _onConnected);
        hand.removeEventListener('disconnected', _onDisconnected);
    }
}