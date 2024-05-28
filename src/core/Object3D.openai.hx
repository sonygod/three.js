package three.math;

import three.events.EventDispatcher;

class Object3D extends EventDispatcher {
    public var isObject3D:Bool = true;
    public var id:Int = _object3DId++;
    public var uuid:String = MathUtils.generateUUID();
    public var name:String = '';
    public var type:String = 'Object3D';
    public var parent:Object3D;
    public var children:Array<Object3D> = [];
    public var up:Vector3 = Vector3.DEFAULT_UP.clone();
    public var position:Vector3 = new Vector3();
    public var quaternion:Quaternion = new Quaternion();
    public var scale:Vector3 = new Vector3(1, 1, 1);
    public var matrix:Matrix4 = new Matrix4();
    public var matrixWorld:Matrix4 = new Matrix4();
    public var matrixAutoUpdate:Bool = true;
    public var matrixWorldAutoUpdate:Bool = true;
    public var matrixWorldNeedsUpdate:Bool = false;
    public var layers:Layers = new Layers();
    public var visible:Bool = true;
    public var castShadow:Bool = false;
    public var receiveShadow:Bool = false;
    public var frustumCulled:Bool = true;
    public var renderOrder:Int = 0;
    public var animations:Array<Dynamic> = [];

    public function new() {
        super();
        Object.defineProperty(this, "id", { value: _object3DId++ });
        rotation.onChange = onRotationChange;
        quaternion.onChange = onQuaternionChange;
    }

    private function onRotationChange() {
        quaternion.setFromEuler(rotation, false);
    }

    private function onQuaternionChange() {
        rotation.setFromQuaternion(quaternion, undefined, false);
    }

    public function applyMatrix4(matrix:Matrix4) {
        if (matrixAutoUpdate) updateMatrix();
        matrix.premultiply(matrix);
        matrix.decompose(position, quaternion, scale);
    }

    public function applyQuaternion(q:Quaternion) {
        quaternion.premultiply(q);
        return this;
    }

    public function setRotationFromAxisAngle(axis:Vector3, angle:Float) {
        quaternion.setFromAxisAngle(axis, angle);
    }

    public function setRotationFromEuler(euler:Euler) {
        quaternion.setFromEuler(euler, true);
    }

    public function setRotationFromMatrix(m:Matrix4) {
        quaternion.setFromRotationMatrix(m);
    }

    public function setRotationFromQuaternion(q:Quaternion) {
        quaternion.copy(q);
    }

    public function rotateOnAxis(axis:Vector3, angle:Float) {
        quaternion.multiply(new Quaternion().setFromAxisAngle(axis, angle));
        return this;
    }

    public function rotateOnWorldAxis(axis:Vector3, angle:Float) {
        quaternion.premultiply(new Quaternion().setFromAxisAngle(axis, angle));
        return this;
    }

    public function rotateX(angle:Float) {
        return rotateOnAxis(new Vector3(1, 0, 0), angle);
    }

    public function rotateY(angle:Float) {
        return rotateOnAxis(new Vector3(0, 1, 0), angle);
    }

    public function rotateZ(angle:Float) {
        return rotateOnAxis(new Vector3(0, 0, 1), angle);
    }

    public function translateOnAxis(axis:Vector3, distance:Float) {
        axis.multiplyScalar(distance);
        position.add(axis);
        return this;
    }

    public function translateX(distance:Float) {
        return translateOnAxis(new Vector3(1, 0, 0), distance);
    }

    public function translateY(distance:Float) {
        return translateOnAxis(new Vector3(0, 1, 0), distance);
    }

    public function translateZ(distance:Float) {
        return translateOnAxis(new Vector3(0, 0, 1), distance);
    }

    public function localToWorld(vector:Vector3) {
        updateWorldMatrix(true, false);
        return vector.applyMatrix4(matrixWorld);
    }

    public function worldToLocal(vector:Vector3) {
        updateWorldMatrix(true, false);
        return vector.applyMatrix4(_m1.copy(matrixWorld).invert());
    }

    public function lookAt(x:Float, y:Float, z:Float) {
        _target.set(x, y, z);
        updateWorldMatrix(true, false);
        position.setFromMatrixPosition(matrixWorld);
        _m1.lookAt(position, _target, up);
        quaternion.setFromRotationMatrix(_m1);
        if (parent != null) {
            _m1.extractRotation(parent.matrixWorld);
            quaternion.premultiply(new Quaternion().setFromRotationMatrix(_m1).invert());
        }
    }

    public function add(object:Object3D) {
        object.removeFromParent();
        object.parent = this;
        children.push(object);
        object.dispatchEvent(_addedEvent);
        _childaddedEvent.child = object;
        dispatchEvent(_childaddedEvent);
        _childaddedEvent.child = null;
        return this;
    }

    public function remove(object:Object3D) {
        const index:Int = children.indexOf(object);
        if (index != -1) {
            object.parent = null;
            children.splice(index, 1);
            object.dispatchEvent(_removedEvent);
            _childremovedEvent.child = object;
            dispatchEvent(_childremovedEvent);
            _childremovedEvent.child = null;
        }
        return this;
    }

    public function removeFromParent() {
        if (parent != null) {
            parent.remove(this);
        }
        return this;
    }

    public function clear() {
        return remove(...children);
    }

    public function attach(object:Object3D) {
        object.updateMatrix();
        _m1.copy(matrixWorld).invert();
        if (object.parent != null) {
            _m1.multiply(object.parent.matrixWorld);
        }
        object.applyMatrix4(_m1);
        object.removeFromParent();
        object.parent = this;
        children.push(object);
        object.updateWorldMatrix(false, true);
        object.dispatchEvent(_addedEvent);
        _childaddedEvent.child = object;
        dispatchEvent(_childaddedEvent);
        _childaddedEvent.child = null;
        return this;
    }

    public function getObjectById(id:Int) {
        return getObjectByProperty('id', id);
    }

    public function getObjectByName(name:String) {
        return getObjectByProperty('name', name);
    }

    public function getObjectByProperty(name:String, value:Dynamic) {
        if (Reflect.hasField(this, name) && Reflect.field(this, name) == value) {
            return this;
        }
        for (child in children) {
            const object:Object3D = child.getObjectByProperty(name, value);
            if (object != null) {
                return object;
            }
        }
        return null;
    }

    public function getObjectsByProperty(name:String, value:Dynamic, result:Array<Object3D> = []) {
        if (Reflect.hasField(this, name) && Reflect.field(this, name) == value) {
            result.push(this);
        }
        for (child in children) {
            child.getObjectsByProperty(name, value, result);
        }
        return result;
    }

    public function getWorldPosition(target:Vector3) {
        updateWorldMatrix(true, false);
        return target.setFromMatrixPosition(matrixWorld);
    }

    public function getWorldQuaternion(target:Quaternion) {
        updateWorldMatrix(true, false);
        matrixWorld.decompose(_position, target, _scale);
        return target;
    }

    public function getWorldScale(target:Vector3) {
        updateWorldMatrix(true, false);
        matrixWorld.decompose(_position, _quaternion, target);
        return target;
    }

    public function getWorldDirection(target:Vector3) {
        updateWorldMatrix(true, false);
        const e:Array<Float> = matrixWorld.elements;
        return target.set(e[8], e[9], e[10]).normalize();
    }

    public function raycast(raycaster:Raycaster, intersects:Array<Dynamic>) {
        // todo: implement raycasting
    }

    public function traverse(callback:Dynamic->Void) {
        callback(this);
        for (child in children) {
            child.traverse(callback);
        }
    }

    public function traverseVisible(callback:Dynamic->Void) {
        if (visible) {
            callback(this);
            for (child in children) {
                child.traverseVisible(callback);
            }
        }
    }

    public function traverseAncestors(callback:Dynamic->Void) {
        if (parent != null) {
            callback(parent);
            parent.traverseAncestors(callback);
        }
    }

    public function updateMatrix() {
        matrix.compose(position, quaternion, scale);
        matrixWorldNeedsUpdate = true;
    }

    public function updateMatrixWorld(force:Bool = false) {
        if (matrixAutoUpdate) updateMatrix();
        if (matrixWorldNeedsUpdate || force) {
            if (parent == null) {
                matrixWorld.copy(matrix);
            } else {
                matrixWorld.multiplyMatrices(parent.matrixWorld, matrix);
            }
            matrixWorldNeedsUpdate = false;
            for (child in children) {
                if (child.matrixWorldAutoUpdate || force) {
                    child.updateMatrixWorld(force);
                }
            }
        }
    }

    public function updateWorldMatrix(updateParents:Bool, updateChildren:Bool) {
        if (updateParents && parent != null && parent.matrixWorldAutoUpdate) {
            parent.updateWorldMatrix(true, false);
        }
        if (matrixAutoUpdate) updateMatrix();
        if (parent == null) {
            matrixWorld.copy(matrix);
        } else {
            matrixWorld.multiplyMatrices(parent.matrixWorld, matrix);
        }
        if (updateChildren) {
            for (child in children) {
                if (child.matrixWorldAutoUpdate) {
                    child.updateWorldMatrix(false, true);
                }
            }
        }
    }

    public function toJSON(meta:Dynamic = null) {
        // omitting implementation for brevity
    }

    public function clone(recursive:Bool = true) {
        return new Object3D().copy(this, recursive);
    }

    public function copy(source:Object3D, recursive:Bool = true) {
        // omitting implementation for brevity
    }
}

// Static properties
Object3D.DEFAULT_UP = Vector3.DEFAULT_UP.clone();
Object3D.DEFAULT_MATRIX_AUTO_UPDATE = true;
Object3D.DEFAULT_MATRIX_WORLD_AUTO_UPDATE = true;