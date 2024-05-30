import math.Quaternion;
import math.Vector3;
import math.Matrix4;
import core.EventDispatcher;
import math.Euler;
import core.Layers;
import math.Matrix3;
import math.MathUtils;

class Object3D extends EventDispatcher {

    public static var DEFAULT_UP:Vector3 = new Vector3(0, 1, 0);
    public static var DEFAULT_MATRIX_AUTO_UPDATE:Bool = true;
    public static var DEFAULT_MATRIX_WORLD_AUTO_UPDATE:Bool = true;

    private static var _object3DId:Int = 0;

    private static var _v1:Vector3 = new Vector3();
    private static var _q1:Quaternion = new Quaternion();
    private static var _m1:Matrix4 = new Matrix4();
    private static var _target:Vector3 = new Vector3();

    private static var _position:Vector3 = new Vector3();
    private static var _scale:Vector3 = new Vector3();
    private static var _quaternion:Quaternion = new Quaternion();

    private static var _xAxis:Vector3 = new Vector3(1, 0, 0);
    private static var _yAxis:Vector3 = new Vector3(0, 1, 0);
    private static var _zAxis:Vector3 = new Vector3(0, 0, 1);

    private static var _addedEvent = { type: 'added' };
    private static var _removedEvent = { type: 'removed' };

    private static var _childaddedEvent = { type: 'childadded', child: null };
    private static var _childremovedEvent = { type: 'childremoved', child: null };

    public var id:Int;
    public var uuid:String;
    public var name:String = '';
    public var type:String = 'Object3D';
    public var parent:Object3D = null;
    public var children:Array<Object3D> = [];
    public var up:Vector3;
    public var position:Vector3;
    public var rotation:Euler;
    public var quaternion:Quaternion;
    public var scale:Vector3;
    public var modelViewMatrix:Matrix4 = new Matrix4();
    public var normalMatrix:Matrix3 = new Matrix3();
    public var matrix:Matrix4 = new Matrix4();
    public var matrixWorld:Matrix4 = new Matrix4();
    public var matrixAutoUpdate:Bool = Object3D.DEFAULT_MATRIX_AUTO_UPDATE;
    public var matrixWorldAutoUpdate:Bool = Object3D.DEFAULT_MATRIX_WORLD_AUTO_UPDATE;
    public var matrixWorldNeedsUpdate:Bool = false;
    public var layers:Layers = new Layers();
    public var visible:Bool = true;
    public var castShadow:Bool = false;
    public var receiveShadow:Bool = false;
    public var frustumCulled:Bool = true;
    public var renderOrder:Int = 0;
    public var animations:Array<Dynamic> = [];
    public var userData:Dynamic = {};

    public function new() {
        super();
        this.isObject3D = true;

        this.id = _object3DId++;
        this.uuid = MathUtils.generateUUID();

        this.up = Object3D.DEFAULT_UP.clone();

        this.position = new Vector3();
        this.rotation = new Euler();
        this.quaternion = new Quaternion();
        this.scale = new Vector3(1, 1, 1);

        var onRotationChange = () -> {
            quaternion.setFromEuler(rotation, false);
        };

        var onQuaternionChange = () -> {
            rotation.setFromQuaternion(quaternion, null, false);
        };

        rotation._onChange(onRotationChange);
        quaternion._onChange(onQuaternionChange);
    }

    public function onBeforeShadow() {}
    public function onAfterShadow() {}
    public function onBeforeRender() {}
    public function onAfterRender() {}

    public function applyMatrix4(matrix:Matrix4):Void {
        if (this.matrixAutoUpdate) this.updateMatrix();
        this.matrix.premultiply(matrix);
        this.matrix.decompose(this.position, this.quaternion, this.scale);
    }

    public function applyQuaternion(q:Quaternion):Object3D {
        this.quaternion.premultiply(q);
        return this;
    }

    public function setRotationFromAxisAngle(axis:Vector3, angle:Float):Void {
        this.quaternion.setFromAxisAngle(axis, angle);
    }

    public function setRotationFromEuler(euler:Euler):Void {
        this.quaternion.setFromEuler(euler, true);
    }

    public function setRotationFromMatrix(m:Matrix4):Void {
        this.quaternion.setFromRotationMatrix(m);
    }

    public function setRotationFromQuaternion(q:Quaternion):Void {
        this.quaternion.copy(q);
    }

    public function rotateOnAxis(axis:Vector3, angle:Float):Object3D {
        _q1.setFromAxisAngle(axis, angle);
        this.quaternion.multiply(_q1);
        return this;
    }

    public function rotateOnWorldAxis(axis:Vector3, angle:Float):Object3D {
        _q1.setFromAxisAngle(axis, angle);
        this.quaternion.premultiply(_q1);
        return this;
    }

    public function rotateX(angle:Float):Object3D {
        return this.rotateOnAxis(_xAxis, angle);
    }

    public function rotateY(angle:Float):Object3D {
        return this.rotateOnAxis(_yAxis, angle);
    }

    public function rotateZ(angle:Float):Object3D {
        return this.rotateOnAxis(_zAxis, angle);
    }

    public function translateOnAxis(axis:Vector3, distance:Float):Object3D {
        _v1.copy(axis).applyQuaternion(this.quaternion);
        this.position.add(_v1.multiplyScalar(distance));
        return this;
    }

    public function translateX(distance:Float):Object3D {
        return this.translateOnAxis(_xAxis, distance);
    }

    public function translateY(distance:Float):Object3D {
        return this.translateOnAxis(_yAxis, distance);
    }

    public function translateZ(distance:Float):Object3D {
        return this.translateOnAxis(_zAxis, distance);
    }

    public function localToWorld(vector:Vector3):Vector3 {
        this.updateWorldMatrix(true, false);
        return vector.applyMatrix4(this.matrixWorld);
    }

    public function worldToLocal(vector:Vector3):Vector3 {
        this.updateWorldMatrix(true, false);
        return vector.applyMatrix4(_m1.copy(this.matrixWorld).invert());
    }

    public function lookAt(x:Dynamic, y:Float, z:Float):Void {
        if (x.isVector3) {
            _target.copy(x);
        } else {
            _target.set(x, y, z);
        }

        var parent = this.parent;
        this.updateWorldMatrix(true, false);
        _position.setFromMatrixPosition(this.matrixWorld);

        if (this.isCamera || this.isLight) {
            _m1.lookAt(_position, _target, this.up);
        } else {
            _m1.lookAt(_target, _position, this.up);
        }

        this.quaternion.setFromRotationMatrix(_m1);

        if (parent != null) {
            _m1.extractRotation(parent.matrixWorld);
            _q1.setFromRotationMatrix(_m1);
            this.quaternion.premultiply(_q1.invert());
        }
    }

    public function add(object:Object3D):Object3D {
        if (arguments.length > 1) {
            for (i in 0...arguments.length) {
                this.add(arguments[i]);
            }
            return this;
        }

        if (object == this) {
            trace('THREE.Object3D.add: object can\'t be added as a child of itself.', object);
            return this;
        }

        if (object != null && object.isObject3D) {
            object.removeFromParent();
            object.parent = this;
            this.children.push(object);
            object.dispatchEvent(_addedEvent);

            _childaddedEvent.child = object;
            this.dispatchEvent(_childaddedEvent);
            _childaddedEvent.child = null;
        } else {
            trace('THREE.Object3D.add: object not an instance of THREE.Object3D.', object);
        }

        return this;
    }

    public function remove(object:Object3D):Object3D {
        if (arguments.length > 1) {
            for (i in 0...arguments.length) {
                this.remove(arguments[i]);
            }
            return this;
        }

        var index = this.children.indexOf(object);
        if (index != -1) {
            object.parent = null;
            this.children.splice(index, 1);
            object.dispatchEvent(_removedEvent);

            _childremovedEvent.child = object;
            this.dispatchEvent(_childremovedEvent);
            _childremovedEvent.child = null;
        }

        return this;
    }

    public function removeFromParent():Object3D {
        var parent = this.parent;
        if (parent != null) {
            parent.remove(this);
        }
        return this;
    }

    public function clear():Object3D {
        return this.remove(...this.children);
    }

    public function attach(object:Object3D):Object3D {
        this.updateWorldMatrix(true, false);
        _m1.copy(this.matrixWorld).invert();

        if (object.parent != null) {
            object.parent.updateWorldMatrix(true, false);
            _m1.multiply(object.parent.matrixWorld);
        }

        object.applyMatrix4(_m1);
        object.removeFromParent();
        this.add(object);

        return this;
    }

    public function getObjectById(id:Int):Object3D {
        return this.getObjectByProperty('id', id);
    }

    public function getObjectByName(name:String):Object3D {
        return this.getObjectByProperty('name', name);
    }

    public function getObjectByProperty(name:String, value:Dynamic):Object3D {
        if (this[name] == value) return this;

        for (child in this.children) {
            var object = child.getObjectByProperty(name, value);
            if (object != null) return object;
        }

        return null;
    }

    public function getWorldPosition(target:Vector3):Vector3 {
        this.updateWorldMatrix(true, false);
        return target.setFromMatrixPosition(this.matrixWorld);
    }

    public function getWorldQuaternion(target:Quaternion):Quaternion {
        this.updateWorldMatrix(true, false);
        this.matrixWorld.decompose(_position, target, _scale);
        return target;
    }

    public function getWorldScale(target:Vector3):Vector3 {
        this.updateWorldMatrix(true, false);
        this.matrixWorld.decompose(_position, _quaternion, target);
        return target;
    }

    public function getWorldDirection(target:Vector3):Vector3 {
        this.updateWorldMatrix(true, false);
        var e = this.matrixWorld.elements;
        return target.set(e[8], e[9], e[10]).normalize();
    }

    public function raycast(raycaster:Dynamic, intersects:Array<Dynamic>):Void {}

    public function traverse(callback:Dynamic->Void):Void {
        callback(this);
        for (child in this.children) {
            child.traverse(callback);
        }
    }

    public function traverseVisible(callback:Dynamic->Void):Void {
        if (this.visible == false) return;
        callback(this);
        for (child in this.children) {
            child.traverseVisible(callback);
        }
    }

    public function traverseAncestors(callback:Dynamic->Void):Void {
        var parent = this.parent;
        if (parent != null) {
            callback(parent);
            parent.traverseAncestors(callback);
        }
    }

    public function updateMatrix():Void {
        this.matrix.compose(this.position, this.quaternion, this.scale);
        this.matrixWorldNeedsUpdate = true;
    }

    public function updateMatrixWorld(force:Bool = false):Void {
        if (this.matrixAutoUpdate) this.updateMatrix();

        if (this.matrixWorldNeedsUpdate || force) {
            if (this.parent == null) {
                this.matrixWorld.copy(this.matrix);
            } else {
                this.matrixWorld.multiplyMatrices(this.parent.matrixWorld, this.matrix);
            }

            this.matrixWorldNeedsUpdate = false;
            force = true;
        }

        for (child in this.children) {
            child.updateMatrixWorld(force);
        }
    }

    public function updateWorldMatrix(updateParents:Bool, updateChildren:Bool):Void {
        var parent = this.parent;
        if (updateParents && parent != null) {
            parent.updateWorldMatrix(true, false);
        }

        if (this.matrixAutoUpdate) this.updateMatrix();

        if (this.parent == null) {
            this.matrixWorld.copy(this.matrix);
        } else {
            this.matrixWorld.multiplyMatrices(this.parent.matrixWorld, this.matrix);
        }

        if (updateChildren) {
            for (child in this.children) {
                child.updateWorldMatrix(false, true);
            }
        }
    }

    public function toJSON(meta:Dynamic = null):Dynamic {
        var isRootObject = (meta == null || meta is String);

        if (isRootObject) {
            meta = {
                geometries: {},
                materials: {},
                textures: {},
                images: {},
                shapes: {}
            };
        }

        var data = {
            metadata: {
                version: 4.5,
                type: 'Object',
                generator: 'Object3D.toJSON'
            }
        };

        data.uuid = this.uuid;
        data.type = this.type;

        if (this.name != '') data.name = this.name;
        if (this.castShadow) data.castShadow = true;
        if (this.receiveShadow) data.receiveShadow = true;
        if (this.visible == false) data.visible = false;
        if (this.frustumCulled == false) data.frustumCulled = false;
        if (this.renderOrder != 0) data.renderOrder = this.renderOrder;
        if (Reflect.fields(this.userData).length > 0) data.userData = this.userData;

        data.layers = this.layers.mask;
        data.matrix = this.matrix.toArray();

        if (this.children.length > 0) {
            data.children = [];
            for (child in this.children) {
                data.children.push(child.toJSON(meta).object);
            }
        }

        if (isRootObject) {
            var geometries = Reflect.fields(meta.geometries);
            if (geometries.length > 0) data.geometries = geometries.map(function(key) return meta.geometries[key]);
            var materials = Reflect.fields(meta.materials);
            if (materials.length > 0) data.materials = materials.map(function(key) return meta.materials[key]);
            var textures = Reflect.fields(meta.textures);
            if (textures.length > 0) data.textures = textures.map(function(key) return meta.textures[key]);
            var images = Reflect.fields(meta.images);
            if (images.length > 0) data.images = images.map(function(key) return meta.images[key]);
            var shapes = Reflect.fields(meta.shapes);
            if (shapes.length > 0) data.shapes = shapes.map(function(key) return meta.shapes[key]);
        }

        return { object: data, geometries: meta.geometries, materials: meta.materials, textures: meta.textures, images: meta.images, shapes: meta.shapes };
    }

    public function clone(recursive:Bool = true):Object3D {
        return new Object3D().copy(this, recursive);
    }

    public function copy(source:Object3D, recursive:Bool = true):Object3D {
        this.name = source.name;

        this.up.copy(source.up);

        this.position.copy(source.position);
        this.rotation.order = source.rotation.order;
        this.quaternion.copy(source.quaternion);
        this.scale.copy(source.scale);

        this.matrix.copy(source.matrix);
        this.matrixWorld.copy(source.matrixWorld);

        this.matrixAutoUpdate = source.matrixAutoUpdate;
        this.matrixWorldAutoUpdate = source.matrixWorldAutoUpdate;
        this.matrixWorldNeedsUpdate = source.matrixWorldNeedsUpdate;

        this.layers.mask = source.layers.mask;
        this.visible = source.visible;

        this.castShadow = source.castShadow;
        this.receiveShadow = source.receiveShadow;

        this.frustumCulled = source.frustumCulled;
        this.renderOrder = source.renderOrder;

        this.userData = haxe.Json.parse(haxe.Json.stringify(source.userData));

        if (recursive) {
            for (child in source.children) {
                this.add(child.clone());
            }
        }

        return this;
    }

    public function get children():Array<Object3D> {
        return this._children;
    }

    public function set children(value:Array<Object3D>):Void {
        this._children = value;
    }
}