import Quaternion from '../math/Quaternion.hx';
import Vector3 from '../math/Vector3.hx';
import Matrix4 from '../math/Matrix4.hx';
import EventDispatcher from './EventDispatcher.hx';
import Euler from '../math/Euler.hx';
import Layers from './Layers.hx';
import Matrix3 from '../math/Matrix3.hx';
import MathUtils from '../math/MathUtils.hx';

let _object3DId: Int = 0;

const _v1: Vector3 = new Vector3();
const _q1: Quaternion = new Quaternion();
const _m1: Matrix4 = new Matrix4();
const _target: Vector3 = new Vector3();

const _position: Vector3 = new Vector3();
const _scale: Vector3 = new Vector3();
const _quaternion: Quaternion = new Quaternion();

const _xAxis: Vector3 = new Vector3(1, 0, 0);
const _yAxis: Vector3 = new Vector3(0, 1, 0);
const _zAxis: Vector3 = new Vector3(0, 0, 1);

const _addedEvent = { type: 'added' };
const _removedEvent = { type: 'removed' };

const _childaddedEvent = { type: 'childadded', child: null };
const _childremovedEvent = { type: 'childremoved', child: null };

class Object3D extends EventDispatcher {
    public isObject3D: Bool;
    public id: Int;
    public uuid: String;
    public name: String;
    public type: String;
    public parent: Object3D;
    public children: Array<Object3D>;
    public up: Vector3;
    public position: Vector3;
    public rotation: Euler;
    public quaternion: Quaternion;
    public scale: Vector3;
    public modelViewMatrix: Matrix4;
    public normalMatrix: Matrix3;
    public matrix: Matrix4;
    public matrixWorld: Matrix4;
    public matrixAutoUpdate: Bool;
    public matrixWorldAutoUpdate: Bool;
    public matrixWorldNeedsUpdate: Bool;
    public layers: Layers;
    public visible: Bool;
    public castShadow: Bool;
    public receiveShadow: Bool;
    public frustumCulled: Bool;
    public renderOrder: Int;
    public animations: Array<Dynamic>;
    public userData: Map<String, Dynamic>;

    public function new() {
        super();
        this.isObject3D = true;
        this.id = _object3DId++;
        this.uuid = MathUtils.generateUUID();
        this.name = '';
        this.type = 'Object3D';
        this.parent = null;
        this.children = [];
        this.up = Object3D.DEFAULT_UP.clone();
        this.position = new Vector3();
        this.rotation = new Euler();
        this.quaternion = new Quaternion();
        this.scale = new Vector3(1, 1, 1);
        this.modelViewMatrix = new Matrix4();
        this.normalMatrix = new Matrix3();
        this.matrix = new Matrix4();
        this.matrixWorld = new Matrix4();
        this.matrixAutoUpdate = Object3D.DEFAULT_MATRIX_AUTO_UPDATE;
        this.matrixWorldAutoUpdate = Object3D.DEFAULT_MATRIX_WORLD_AUTO_UPDATE;
        this.matrixWorldNeedsUpdate = false;
        this.layers = new Layers();
        this.visible = true;
        this.castShadow = false;
        this.receiveShadow = false;
        this.frustumCulled = true;
        this.renderOrder = 0;
        this.animations = [];
        this.userData = new Map();
    }

    public function onBeforeShadow() {}

    public function onAfterShadow() {}

    public function onBeforeRender() {}

    public function onAfterRender() {}

    public function applyMatrix4(matrix: Matrix4) {
        if (this.matrixAutoUpdate) {
            this.updateMatrix();
        }
        this.matrix.premultiply(matrix);
        this.matrix.decompose(this.position, this.quaternion, this.scale);
    }

    public function applyQuaternion(q: Quaternion) {
        this.quaternion.premultiply(q);
        return this;
    }

    public function setRotationFromAxisAngle(axis: Vector3, angle: Float) {
        this.quaternion.setFromAxisAngle(axis, angle);
    }

    public function setRotationFromEuler(euler: Euler) {
        this.quaternion.setFromEuler(euler, true);
    }

    public function setRotationFromMatrix(m: Matrix4) {
        this.quaternion.setFromRotationMatrix(m);
    }

    public function setRotationFromQuaternion(q: Quaternion) {
        this.quaternion.copy(q);
    }

    public function rotateOnAxis(axis: Vector3, angle: Float) {
        _q1.setFromAxisAngle(axis, angle);
        this.quaternion.multiply(_q1);
        return this;
    }

    public function rotateOnWorldAxis(axis: Vector3, angle: Float) {
        _q1.setFromAxisAngle(axis, angle);
        this.quaternion.premultiply(_q1);
        return this;
    }

    public function rotateX(angle: Float) {
        return this.rotateOnAxis(_xAxis, angle);
    }

    public function rotateY(angle: Float) {
        return this.rotateOnAxis(_yAxis, angle);
    }

    public function rotateZ(angle: Float) {
        return this.rotateOnAxis(_zAxis, angle);
    }

    public function translateOnAxis(axis: Vector3, distance: Float) {
        _v1.copy(axis).applyQuaternion(this.quaternion);
        this.position.add(_v1.multiplyScalar(distance));
        return this;
    }

    public function translateX(distance: Float) {
        return this.translateOnAxis(_xAxis, distance);
    }

    public function translateY(distance: Float) {
        return this.translateOnAxis(_yAxis, distance);
    }

    public function translateZ(distance: Float) {
        return this.translateOnAxis(_zAxis, distance);
    }

    public function localToWorld(vector: Vector3) {
        this.updateWorldMatrix(true, false);
        return vector.applyMatrix4(this.matrixWorld);
    }

    public function worldToLocal(vector: Vector3) {
        this.updateWorldMatrix(true, false);
        return vector.applyMatrix4(_m1.copy(this.matrixWorld).invert());
    }

    public function lookAt(x: Dynamic, y: Float, z: Float) {
        if (x is Vector3) {
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

    public function add(object: Object3D) {
        if (arguments.length > 1) {
            for (obj in arguments) {
                this.add(obj);
            }
            return this;
        }
        if (object == this) {
            throw 'Object3D cannot be added as a child of itself.';
        }
        if (Std.is(object, Object3D)) {
            object.removeFromParent();
            object.parent = this;
            this.children.push(object);
            object.dispatchEvent(_addedEvent);
            _childaddedEvent.child = object;
            this.dispatchEvent(_childaddedEvent);
            _childaddedEvent.child = null;
        } else {
            throw 'Object is not an instance of Object3D.';
        }
        return this;
    }

    public function remove(object: Object3D) {
        if (arguments.length > 1) {
            for (obj in arguments) {
                this.remove(obj);
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

    public function removeFromParent() {
        var parent = this.parent;
        if (parent != null) {
            parent.remove(this);
        }
        return this;
    }

    public function clear() {
        return this.remove(...this.children);
    }

    public function attach(object: Object3D) {
        this.updateWorldMatrix(true, false);
        _m1.copy(this.matrixWorld).invert();
        if (object.parent != null) {
            object.parent.updateWorldMatrix(true, false);
            _m1.multiply(object.parent.matrixWorld);
        }
        object.applyMatrix4(_m1);
        object.removeFromParent();
        object.parent = this;
        this.children.push(object);
        object.updateWorldMatrix(false, true);
        object.dispatchEvent(_addedEvent);
        _childaddedEvent.child = object;
        this.dispatchEvent(_childaddedEvent);
        _childaddedEvent.child = null;
        return this;
    }

    public function getObjectById(id: Int) {
        return this.getObjectByProperty('id', id);
    }

    public function getObjectByName(name: String) {
        return this.getObjectByProperty('name', name);
    }

    public function getObjectByProperty(name: String, value: Dynamic) {
        if (this[name] == value) {
            return this;
        }
        for (child in this.children) {
            var result = child.getObjectByProperty(name, value);
            if (result != null) {
                return result;
            }
        }
        return null;
    }

    public function getObjectsByProperty(name: String, value: Dynamic, result: Array<Dynamic>) {
        if (this[name] == value) {
            result.push(this);
        }
        for (child in this.children) {
            child.getObjectsByProperty(name, value, result);
        }
        return result;
    }

    public function getWorldPosition(target: Vector3) {
        this.updateWorldMatrix(true, false);
        return target.setFromMatrixPosition(this.matrixWorld);
    }

    public function getWorldQuaternion(target: Quaternion) {
        this.updateWorldMatrix(true, false);
        this.matrixWorld.decompose(_position, target, _scale);
        return target;
    }

    public function getWorldScale(target: Vector3) {
        this.updateWorldMatrix(true, false);
        this.matrixWorld.decompose(_position, _quaternion, target);
        return target;
    }

    public function getWorldDirection(target: Vector3) {
        this.updateWorldMatrix(true, false);
        var e = this.matrixWorld.elements;
        return target.set(e[8], e[9], e[10]).normalize();
    }

    public function raycast() {}

    public function traverse(callback: Dynamic -> Void) {
        callback(this);
        for (child in this.children) {
            child.traverse(callback);
        }
    }

    public function traverseVisible(callback: Dynamic -> Void) {
        if (!this.visible) {
            return;
        }
        callback(this);
        for (child in this.children) {
            child.traverseVisible(callback);
        }
    }

    public function traverseAncestors(callback: Dynamic -> Void) {
        var parent = this.parent;
        if (parent != null) {
            callback(parent);
            parent.traverseAncestors(callback);
        }
    }

    public function updateMatrix() {
        this.matrix.compose(this.position, this.quaternion, this.scale);
        this.matrixWorldNeedsUpdate = true;
    }

    public function updateMatrixWorld(force: Bool) {
        if (this.matrixAutoUpdate) {
            this.updateMatrix();
        }
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
            if (child.matrixWorldAutoUpdate || force) {
                child.updateMatrixWorld(force);
            }
        }
    }

    public function updateWorldMatrix(updateParents: Bool, updateChildren: Bool) {
        var parent = this.parent;
        if (updateParents && parent != null && parent.matrixWorldAutoUpdate) {
            parent.updateWorldMatrix(true, false);
        }
        if (this.matrixAutoUpdate) {
            this.updateMatrix();
        }
        if (this.parent == null) {
            this.matrixWorld.copy(this.matrix);
        } else {
            this.matrixWorld.multiplyMatrices(this.parent.matrixWorld, this.matrix);
        }
        if (updateChildren) {
            for (child in this.children) {
                if (child.matrixWorldAutoUpdate) {
                    child.updateWorldMatrix(false, true);
                }
            }
        }
    }

    public function toJSON(meta: Dynamic) {
        var isRootObject = (meta == null || typeof meta == 'string');
        var output = new Map();
        if (isRootObject) {
            meta = {
                geometries: new Map(),
                materials: new Map(),
                textures: new Map(),
                images: new Map(),
                shapes: new Map(),
                skeletons: new Map(),
                animations: new Map(),
                nodes: new Map()
            };
            output.metadata = {
                version: 4.6,
                type: 'Object',
                generator: 'Object3D.toJSON'
            };
        }
        var object = new Map();
        object.uuid = this.uuid;
        object.type = this.type;
        if (this.name != '') {
            object.name = this.name;
        }
        if (this.castShadow) {
            object.castShadow = true;
        }
        if (this.receiveShadow) {
            object.receiveShadow = true;
        }
        if (!this.visible) {
            object.visible = false;
        }
        if (!this.frustumCulled) {
            object.frustumCulled = false;
        }
        if (this.renderOrder != 0) {
            object.renderOrder = this.renderOrder;
        }
        if (this.userData.keys.length > 0) {
            object.userData = this.userData;
        }
        object.layers = this.layers.mask;
        object.matrix = this.matrix.toArray();
        object.up = this.up.toArray();
        if (!this.matrixAutoUpdate) {
            object.matrixAutoUpdate = false;
        }
        if (this.isInstancedMesh) {
            object.type = 'InstancedMesh';
            object.count = this.count;
            object.instanceMatrix = this.instanceMatrix.toJSON();
            if (this.instanceColor != null) {
                object.instanceColor = this.instanceColor.toJSON();
            }
        }
        if (this.isBatchedMesh) {
            object.type = 'BatchedMesh';
            object.perObjectFrustumCulled = this.perObjectFrustumCulled;
            object.sortObjects = this.sortObjects;
            object.drawRanges = this._drawRanges;
            object.reservedRanges = this._reservedRanges;
            object.visibility = this._visibility;
            object.active = this._active;
            object.bounds = this._bounds.map(bound => {
                return {
                    boxInitialized: bound.boxInitialized,
                    boxMin: bound.box.min.toArray(),
                    boxMax: bound.box.max.toArray(),
                    sphereInitialized: bound.sphereInitialized,
                    sphereRadius: bound.sphere.radius,
                    sphereCenter: bound.sphere.center.toArray()
                };
            });
            object.maxGeometryCount = this._maxGeometryCount;
            object.maxVertexCount = this._maxVertexCount;
            object.maxIndexCount = this._maxIndexCount;
            object.geometryInitialized = this._geometryInitialized;
            object.geometryCount = this._geometryCount;
            object.matricesTexture = this._matricesTexture.toJSON(meta);
            if (this._colorsTexture != null) {
                object.colorsTexture = this._colorsTexture.toJSON(meta);
            }
            if (this.boundingSphere != null) {
                object.boundingSphere = {
                    center: this.boundingSphere.center.toArray(),
                    radius: this.boundingSphere.radius
                };
            }
            if (this.boundingBox != null) {
                object.boundingBox = {
                    min: this.boundingBox.min.toArray(),
                    max: this.boundingBox.max.toArray()
                };
            }
        }
        function serialize(library: Map<String, Dynamic>, element: Dynamic) {
            if (!library.exists(element.uuid)) {
                library[element.uuid] = element.toJSON(meta);
            }
            return element.uuid;
        }
        if (this.isScene) {
            if (this.background != null) {
                if (this.background.isColor) {
                    object.background = this.background.toJSON();
                } else if (this.background.isTexture) {
                    object.background = this
                    .toJSON(meta).uuid;
                }
            }
            if (this.environment != null && this.environment.isTexture && !this.environment.isRenderTargetTexture) {
                object.environment = this.environment.toJSON(meta).uuid;
            }
        } else if (this.isMesh || this.isLine || this.isPoints) {
            object.geometry = serialize(meta.geometries, this.geometry);
            var parameters = this.geometry.parameters;
            if (parameters != null && parameters.shapes != null) {
                var shapes = parameters.shapes;
                if (shapes is Array<Dynamic>) {
                    for (shape in shapes) {
                        serialize(meta.shapes, shape);
                    }
                } else {
                    serialize(meta.shapes, shapes);
                }
            }
        }
        if (this.isSkinnedMesh) {
            object.bindMode = this.bindMode;
            object.bindMatrix = this.bindMatrix.toArray();
            if (this.skeleton != null) {
                serialize(meta.skeletons, this.skeleton);
                object.skeleton = this.skeleton.uuid;
            }
        }
        if (this.material != null) {
            if (this.material is Array<Dynamic>) {
                var uuids = [];
                for (material in this.material) {
                    uuids.push(serialize(meta.materials, material));
                }
                object.material = uuids;
            } else {
                object.material = serialize(meta.materials, this.material);
            }
        }
        if (this.children.length > 0) {
            object.children = [];
            for (child in this.children) {
                object.children.push(child.toJSON(meta).object);
            }
        }
        if (this.animations.length > 0) {
            object.animations = [];
            for (animation in this.animations) {
                object.animations.push(serialize(meta.animations, animation));
            }
        }
        if (isRootObject) {
            var geometries = extractFromCache(meta.geometries);
            var materials = extractFromCache(meta.materials);
            var textures = extractFromCache(meta.textures);
            var images = extractFromCache(meta.images);
            var shapes = extractFromCache(meta.shapes);
            var skeletons = extractFromCache(meta.skeletons);
            var animations = extractFromCache(meta.animations);
            var nodes = extractFromCache(meta.nodes);
            if (geometries.length > 0) {
                output.geometries = geometries;
            }
            if (materials.length > 0) {
                output.materials = materials;
            }
            if (textures.length > 0) {
                output.textures = textures;
            }
            if (images.length > 0) {
                output.images = images;
            }
            if (shapes.length > 0) {
                output.shapes = shapes;
            }
            if (skeletons.length > 0) {
                output.skeletons = skeletons;
            }
            if (animations.length > 0) {
                output.animations = animations;
            }
            if (nodes.length > 0) {
                output.nodes = nodes;
            }
        }
        output.object = object;
        return output;
        function extractFromCache(cache: Map<String, Dynamic>) {
            var values = [];
            for (key in cache) {
                var data = cache[key];
                delete data.metadata;
                values.push(data);
            }
            return values;
        }
    }
    public function clone(recursive: Bool = true) {
        return new this.constructor().copy(this, recursive);
    }
    public function copy(source: Object3D, recursive: Bool = true) {
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
        this.animations = source.animations.copy();
        this.userData = source.userData.copy();
        if (recursive) {
            for (child in source.children) {
                this.add(child.clone());
            }
        }
        return this;
    }
}
static var DEFAULT_UP: Vector3 = new Vector3(0, 1, 0);
static var DEFAULT_MATRIX_AUTO_UPDATE: Bool = true;
static var DEFAULT_MATRIX_WORLD_AUTO_UPDATE: Bool = true;