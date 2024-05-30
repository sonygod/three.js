import three.math.Quaternion;
import three.math.Vector3;
import three.math.Matrix4;
import three.core.EventDispatcher;
import three.math.Euler;
import three.core.Layers;
import three.math.Matrix3;
import three.math.MathUtils;

class Object3D extends EventDispatcher {

    static var _object3DId:Int = 0;

    static var _v1:Vector3 = new Vector3();
    static var _q1:Quaternion = new Quaternion();
    static var _m1:Matrix4 = new Matrix4();
    static var _target:Vector3 = new Vector3();

    static var _position:Vector3 = new Vector3();
    static var _scale:Vector3 = new Vector3();
    static var _quaternion:Quaternion = new Quaternion();

    static var _xAxis:Vector3 = new Vector3(1, 0, 0);
    static var _yAxis:Vector3 = new Vector3(0, 1, 0);
    static var _zAxis:Vector3 = new Vector3(0, 0, 1);

    static var _addedEvent:Dynamic = { type: 'added' };
    static var _removedEvent:Dynamic = { type: 'removed' };

    static var _childaddedEvent:Dynamic = { type: 'childadded', child: null };
    static var _childremovedEvent:Dynamic = { type: 'childremoved', child: null };

    var isObject3D:Bool = true;

    var id:Int;
    var uuid:String;
    var name:String;
    var type:String;

    var parent:Null<Object3D>;
    var children:Array<Object3D>;

    var up:Vector3;

    var position:Vector3;
    var rotation:Euler;
    var quaternion:Quaternion;
    var scale:Vector3;

    var matrix:Matrix4;
    var matrixWorld:Matrix4;

    var matrixAutoUpdate:Bool;
    var matrixWorldAutoUpdate:Bool;
    var matrixWorldNeedsUpdate:Bool;

    var layers:Layers;
    var visible:Bool;

    var castShadow:Bool;
    var receiveShadow:Bool;

    var frustumCulled:Bool;
    var renderOrder:Int;

    var animations:Array<Dynamic>;

    var userData:Dynamic;

    public function new() {
        super();

        id = _object3DId++;
        uuid = MathUtils.generateUUID();
        name = '';
        type = 'Object3D';

        parent = null;
        children = [];

        up = Object3D.DEFAULT_UP.clone();

        position = new Vector3();
        rotation = new Euler();
        quaternion = new Quaternion();
        scale = new Vector3(1, 1, 1);

        function onRotationChange() {
            quaternion.setFromEuler(rotation, false);
        }

        function onQuaternionChange() {
            rotation.setFromQuaternion(quaternion, undefined, false);
        }

        rotation._onChange(onRotationChange);
        quaternion._onChange(onQuaternionChange);

        Object.defineProperties(this, {
            position: {
                configurable: true,
                enumerable: true,
                value: position
            },
            rotation: {
                configurable: true,
                enumerable: true,
                value: rotation
            },
            quaternion: {
                configurable: true,
                enumerable: true,
                value: quaternion
            },
            scale: {
                configurable: true,
                enumerable: true,
                value: scale
            },
            modelViewMatrix: {
                value: new Matrix4()
            },
            normalMatrix: {
                value: new Matrix3()
            }
        });

        matrix = new Matrix4();
        matrixWorld = new Matrix4();

        matrixAutoUpdate = Object3D.DEFAULT_MATRIX_AUTO_UPDATE;
        matrixWorldAutoUpdate = Object3D.DEFAULT_MATRIX_WORLD_AUTO_UPDATE;
        matrixWorldNeedsUpdate = false;

        layers = new Layers();
        visible = true;

        castShadow = false;
        receiveShadow = false;

        frustumCulled = true;
        renderOrder = 0;

        animations = [];

        userData = {};
    }

    public function onBeforeShadow(/* renderer, object, camera, shadowCamera, geometry, depthMaterial, group */) {}

    public function onAfterShadow(/* renderer, object, camera, shadowCamera, geometry, depthMaterial, group */) {}

    public function onBeforeRender(/* renderer, scene, camera, geometry, material, group */) {}

    public function onAfterRender(/* renderer, scene, camera, geometry, material, group */) {}

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
        _q1.setFromAxisAngle(axis, angle);
        quaternion.multiply(_q1);
        return this;
    }

    public function rotateOnWorldAxis(axis:Vector3, angle:Float) {
        _q1.setFromAxisAngle(axis, angle);
        quaternion.premultiply(_q1);
        return this;
    }

    public function rotateX(angle:Float) {
        return rotateOnAxis(_xAxis, angle);
    }

    public function rotateY(angle:Float) {
        return rotateOnAxis(_yAxis, angle);
    }

    public function rotateZ(angle:Float) {
        return rotateOnAxis(_zAxis, angle);
    }

    public function translateOnAxis(axis:Vector3, distance:Float) {
        _v1.copy(axis).applyQuaternion(quaternion);
        position.add(_v1.multiplyScalar(distance));
        return this;
    }

    public function translateX(distance:Float) {
        return translateOnAxis(_xAxis, distance);
    }

    public function translateY(distance:Float) {
        return translateOnAxis(_yAxis, distance);
    }

    public function translateZ(distance:Float) {
        return translateOnAxis(_zAxis, distance);
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
        const parent = this.parent;
        updateWorldMatrix(true, false);
        _position.setFromMatrixPosition(matrixWorld);
        if (this.isCamera || this.isLight) {
            _m1.lookAt(_position, _target, up);
        } else {
            _m1.lookAt(_target, _position, up);
        }
        quaternion.setFromRotationMatrix(_m1);
        if (parent) {
            _m1.extractRotation(parent.matrixWorld);
            _q1.setFromRotationMatrix(_m1);
            quaternion.premultiply(_q1.invert());
        }
    }

    public function add(object:Object3D) {
        if (arguments.length > 1) {
            for (i in 0...arguments.length) {
                add(arguments[i]);
            }
            return this;
        }
        if (object === this) {
            console.error('THREE.Object3D.add: object can\'t be added as a child of itself.', object);
            return this;
        }
        if (object && object.isObject3D) {
            object.removeFromParent();
            object.parent = this;
            children.push(object);
            object.dispatchEvent(_addedEvent);
            _childaddedEvent.child = object;
            dispatchEvent(_childaddedEvent);
            _childaddedEvent.child = null;
        } else {
            console.error('THREE.Object3D.add: object not an instance of THREE.Object3D.', object);
        }
        return this;
    }

    public function remove(object:Object3D) {
        if (arguments.length > 1) {
            for (i in 0...arguments.length) {
                remove(arguments[i]);
            }
            return this;
        }
        const index = children.indexOf(object);
        if (index !== -1) {
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
        const parent = this.parent;
        if (parent !== null) {
            parent.remove(this);
        }
        return this;
    }

    public function clear() {
        return remove(...children);
    }

    public function attach(object:Object3D) {
        updateWorldMatrix(true, false);
        _m1.copy(matrixWorld).invert();
        if (object.parent !== null) {
            object.parent.updateWorldMatrix(true, false);
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
        if (this[name] === value) return this;
        for (i in 0...children.length) {
            const child = children[i];
            const object = child.getObjectByProperty(name, value);
            if (object !== undefined) {
                return object;
            }
        }
        return undefined;
    }

    public function getObjectsByProperty(name:String, value:Dynamic, result:Array<Dynamic>) {
        if (this[name] === value) result.push(this);
        const children = this.children;
        for (i in 0...children.length) {
            children[i].getObjectsByProperty(name, value, result);
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
        const e = matrixWorld.elements;
        return target.set(e[8], e[9], e[10]).normalize();
    }

    public function raycast(/* raycaster, intersects */) {}

    public function traverse(callback:Dynamic) {
        callback(this);
        const children = this.children;
        for (i in 0...children.length) {
            children[i].traverse(callback);
        }
    }

    public function traverseVisible(callback:Dynamic) {
        if (visible === false) return;
        callback(this);
        const children = this.children;
        for (i in 0...children.length) {
            children[i].traverseVisible(callback);
        }
    }

    public function traverseAncestors(callback:Dynamic) {
        const parent = this.parent;
        if (parent !== null) {
            callback(parent);
            parent.traverseAncestors(callback);
        }
    }

    public function updateMatrix() {
        matrix.compose(position, quaternion, scale);
        matrixWorldNeedsUpdate = true;
    }

    public function updateMatrixWorld(force:Bool) {
        if (matrixAutoUpdate) updateMatrix();
        if (matrixWorldNeedsUpdate || force) {
            if (parent === null) {
                matrixWorld.copy(matrix);
            } else {
                matrixWorld.multiplyMatrices(parent.matrixWorld, matrix);
            }
            matrixWorldNeedsUpdate = false;
            force = true;
        }
        // update children
        const children = this.children;
        for (i in 0...children.length) {
            const child = children[i];
            if (child.matrixWorldAutoUpdate === true || force === true) {
                child.updateMatrixWorld(force);
            }
        }
    }

    public function updateWorldMatrix(updateParents:Bool, updateChildren:Bool) {
        const parent = this.parent;
        if (updateParents === true && parent !== null && parent.matrixWorldAutoUpdate === true) {
            parent.updateWorldMatrix(true, false);
        }
        if (matrixAutoUpdate) updateMatrix();
        if (parent === null) {
            matrixWorld.copy(matrix);
        } else {
            matrixWorld.multiplyMatrices(parent.matrixWorld, matrix);
        }
        // update children
        if (updateChildren === true) {
            const children = this.children;
            for (i in 0...children.length) {
                const child = children[i];
                if (child.matrixWorldAutoUpdate === true) {
                    child.updateWorldMatrix(false, true);
                }
            }
        }
    }

    public function toJSON(meta:Dynamic) {
        // meta is a string when called from JSON.stringify
        const isRootObject = (meta === undefined || typeof meta === 'string');
        const output = {};
        // meta is a hash used to collect geometries, materials.
        // not providing it implies that this is the root object
        // being serialized.
        if (isRootObject) {
            // initialize meta obj
            meta = {
                geometries: {},
                materials: {},
                textures: {},
                images: {},
                shapes: {},
                skeletons: {},
                animations: {},
                nodes: {}
            };
            output.metadata = {
                version: 4.6,
                type: 'Object',
                generator: 'Object3D.toJSON'
            };
        }
        // standard Object3D serialization
        const object = {};
        object.uuid = this.uuid;
        object.type = this.type;
        if (name !== '') object.name = name;
        if (castShadow === true) object.castShadow = true;
        if (receiveShadow === true) object.receiveShadow = true;
        if (visible === false) object.visible = false;
        if (frustumCulled === false) object.frustumCulled = false;
        if (renderOrder !== 0) object.renderOrder = renderOrder;
        if (Object.keys(userData).length > 0) object.userData = userData;
        object.layers = layers.mask;
        object.matrix = matrix.toArray();
        object.up = up.toArray();
        if (matrixAutoUpdate === false) object.matrixAutoUpdate = false;
        // object specific properties
        if (isInstancedMesh) {
            object.type = 'InstancedMesh';
            object.count = count;
            object.instanceMatrix = instanceMatrix.toJSON();
            if (instanceColor !== null) object.instanceColor = instanceColor.toJSON();
        }
        if (isBatchedMesh) {
            object.type = 'BatchedMesh';
            object.perObjectFrustumCulled = perObjectFrustumCulled;
            object.sortObjects = sortObjects;
            object.drawRanges = _drawRanges;
            object.reservedRanges = _reservedRanges;
            object.visibility = _visibility;
            object.active = _active;
            object.bounds = _bounds.map(bound => ({
                boxInitialized: bound.boxInitialized,
                boxMin: bound.box.min.toArray(),
                boxMax: bound.box.max.toArray(),
                sphereInitialized: bound.sphereInitialized,
                sphereRadius: bound.sphere.radius,
                sphereCenter: bound.sphere.center.toArray()
            }));
            object.maxGeometryCount = _maxGeometryCount;
            object.maxVertexCount = _maxVertexCount;
            object.maxIndexCount = _maxIndexCount;
            object.geometryInitialized = _geometryInitialized;
            object.geometryCount = _geometryCount;
            object.matricesTexture = _matricesTexture.toJSON(meta);
            if (_colorsTexture !== null) object.colorsTexture = _colorsTexture.toJSON(meta);
            if (boundingSphere !== null) {
                object.boundingSphere = {
                    center: boundingSphere.center.toArray(),
                    radius: boundingSphere.radius
                };
            }
            if (boundingBox !== null) {
                object.boundingBox = {
                    min: boundingBox.min.toArray(),
                    max: boundingBox.max.toArray()
                };
            }
        }
        function serialize(library, element) {
            if (library[element.uuid] === undefined) {
                library[element.uuid] = element.toJSON(meta);
            }
            return element.uuid;
        }
        if (isScene) {
            if (background) {
                if (background.isColor) {
                    object.background = background.toJSON();
                } else if (background.isTexture) {
                    object.background = background.toJSON(meta).uuid;
                }
            }
            if (environment && environment.isTexture && environment.isRenderTargetTexture !== true) {
                object.environment = environment.toJSON(meta).uuid;
            }
        } else if (isMesh || isLine || isPoints) {
            object.geometry = serialize(meta.geometries, geometry);
            const parameters = geometry.parameters;
            if (parameters !== undefined && parameters.shapes !== undefined) {
                const shapes = parameters.shapes;
                if (Array.isArray(shapes)) {
                    for (i in 0...shapes.length) {
                        const shape = shapes[i];
                        serialize(meta.shapes, shape);
                    }
                } else {
                    serialize(meta.shapes, shapes);
                }
            }
        }
        if (isSkinnedMesh) {
            object.bindMode = bindMode;
            object.bindMatrix = bindMatrix.toArray();
            if (skeleton !== undefined) {
                serialize(meta.skeletons, skeleton);
                object.skeleton = skeleton.uuid;
            }
        }
        if (material !== undefined) {
            if (Array.isArray(material)) {
                const uuids = [];
                for (i in 0...material.length) {
                    uuids.push(serialize(meta.materials, material[i]));
                }
                object.material = uuids;
            } else {
                object.material = serialize(meta.materials, material);
            }
        }
        //
        if (children.length > 0) {
            object.children = [];
            for (i in 0...children.length) {
                object.children.push(children[i].toJSON(meta).object);
            }
        }
        //
        if (animations.length > 0) {
            object.animations = [];
            for (i in 0...animations.length) {
                const animation = animations[i];
                object.animations.push(serialize(meta.animations, animation));
            }
        }
        if (isRootObject) {
            const geometries = extractFromCache(meta.geometries);
            const materials = extractFromCache(meta.materials);
            const textures = extractFromCache(meta.textures);
            const images = extractFromCache(meta.images);
            const shapes = extractFromCache(meta.shapes);
            const skeletons = extractFromCache(meta.skeletons);
            const animations = extractFromCache(meta.animations);
            const nodes = extractFromCache(meta.nodes);
            if (geometries.length > 0) output.geometries = geometries;
            if (materials.length > 0) output.materials = materials;
            if (textures.length > 0) output.textures = textures;
            if (images.length > 0) output.images = images;
            if (shapes.length > 0) output.shapes = shapes;
            if (skeletons.length > 0) output.skeletons = skeletons;
            if (animations.length > 0) output.animations = animations;
            if (nodes.length > 0) output.nodes = nodes;
        }
        output.object = object;
        return output;
        // extract data from the cache hash
        // remove metadata on each item
        // and return as array
        function extractFromCache(cache) {
            const values = [];
            for (key in cache) {
                const data = cache[key];
                delete data.metadata;
                values.push(data);
            }
            return values;
        }
    }

    public function clone(recursive:Bool) {
        return new this.constructor().copy(this, recursive);
    }

    public function copy(source:Object3D, recursive:Bool = true) {
        name = source.name;
        up.copy(source.up);
        position.copy(source.position);
        rotation.order = source.rotation.order;
        quaternion.copy(source.quaternion);
        scale.copy(source.scale);
        matrix.copy(source.matrix);
        matrixWorld.copy(source.matrixWorld);
        matrixAutoUpdate = source.matrixAutoUpdate;
        matrixWorldAutoUpdate = source.matrixWorldAutoUpdate;
        matrixWorldNeedsUpdate = source.matrixWorldNeedsUpdate;
        layers.mask = source.layers.mask;
        visible = source.visible;
        castShadow = source.castShadow;
        receiveShadow = source.receiveShadow;
        frustumCulled = source.frustumCulled;
        renderOrder = source.renderOrder;
        animations = source.animations.slice();
        userData = JSON.parse(JSON.stringify(source.userData));
        if (recursive === true) {
            for (i in 0...source.children.length) {
                const child = source.children[i];
                add(child.clone());
            }
        }
        return this;
    }

    static var DEFAULT_UP:Vector3 = new Vector3(0, 1, 0);
    static var DEFAULT_MATRIX_AUTO_UPDATE:Bool = true;
    static var DEFAULT_MATRIX_WORLD_AUTO_UPDATE:Bool = true;

}