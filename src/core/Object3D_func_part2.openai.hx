import js.Lib;

class Object3D {
    static public var DEFAULT_UP = new Vector3(0, 1, 0);
    static public var DEFAULT_MATRIX_AUTO_UPDATE = true;
    static public var DEFAULT_MATRIX_WORLD_AUTO_UPDATE = true;

    public var uuid:String;
    public var type:String;
    public var name:String;
    public var castShadow:Bool;
    public var receiveShadow:Bool;
    public var visible:Bool;
    public var frustumCulled:Bool;
    public var renderOrder:Int;
    public var userData:Dynamic;
    public var animations:Array<Dynamic>;
    public var matrix:Matrix4;
    public var matrixWorld:Matrix4;
    public var matrixAutoUpdate:Bool;
    public var matrixWorldAutoUpdate:Bool;
    public var matrixWorldNeedsUpdate:Bool;
    public var position:Vector3;
    public var rotation:Quaternion;
    public var scale:Vector3;
    public var up:Vector3;
    public var layers:Layers;
    public var children:Array<Object3D>;
    public var parent:Object3D;
    public var bindMatrix:Matrix4;
    public var bindMode:BindModes;
    public var skeleton:Skeleton;
    public var isInstancedMesh:Bool;
    public var count:Int;
    public var instanceMatrix:Matrix4;
    public var instanceColor:Color;
    public var isBatchedMesh:Bool;
    public var perObjectFrustumCulled:Bool;
    public var sortObjects:Bool;
    public var _drawRanges:Dynamic;
    public var _reservedRanges:Dynamic;
    public var _visibility:Dynamic;
    public var _active:Dynamic;
    public var _bounds:Dynamic;
    public var _maxGeometryCount:Dynamic;
    public var _maxVertexCount:Dynamic;
    public var _maxIndexCount:Dynamic;
    public var _geometryInitialized:Dynamic;
    public var _geometryCount:Dynamic;
    public var _matricesTexture:Dynamic;
    public var _colorsTexture:Dynamic;
    public var boundingSphere:Dynamic;
    public var boundingBox:Dynamic;
    public var background:Dynamic;
    public var environment:Dynamic;
    public var geometry:Dynamic;
    public var bindBone:Dynamic;
    public var bindInverse:Dynamic;
    public var material:Dynamic;
    public var cache:Dynamic;

    public function new() {
        uuid = null;
        type = "";
        name = "";
        castShadow = false;
        receiveShadow = false;
        visible = true;
        frustumCulled = true;
        renderOrder = 0;
        userData = {};
        animations = [];
        matrix = new Matrix4();
        matrixWorld = new Matrix4();
        matrixAutoUpdate = true;
        matrixWorldAutoUpdate = true;
        matrixWorldNeedsUpdate = false;
        position = new Vector3();
        rotation = new Quaternion();
        scale = new Vector3(1, 1, 1);
        up = new Vector3(0, 1, 0);
        layers = new Layers();
        children = [];
        parent = null;
        bindMatrix = new Matrix4();
        bindMode = BindModes.DEFAULT;
        skeleton = null;
        isInstancedMesh = false;
        count = 0;
        instanceMatrix = new Matrix4();
        instanceColor = null;
        isBatchedMesh = false;
        perObjectFrustumCulled = true;
        sortObjects = true;
        _drawRanges = {};
        _reservedRanges = {};
        _visibility = {};
        _active = {};
        _bounds = {};
        _maxGeometryCount = 0;
        _maxVertexCount = 0;
        _maxIndexCount = 0;
        _geometryInitialized = {};
        _geometryCount = {};
        _matricesTexture = null;
        _colorsTexture = null;
        boundingSphere = null;
        boundingBox = null;
        background = null;
        environment = null;
        geometry = null;
        bindBone = null;
        bindInverse = null;
        material = null;
        cache = null;
    }

    public function traverse(callback:Object3D->Void):Void {
        callback(this);

        for (child in children) {
            child.traverse(callback);
        }
    }

    public function traverseVisible(callback:Object3D->Void):Void {
        if (!visible) return;

        callback(this);

        for (child in children) {
            child.traverseVisible(callback);
        }
    }

    public function traverseAncestors(callback:Object3D->Void):Void {
        if (parent != null) {
            callback(parent);
            parent.traverseAncestors(callback);
        }
    }

    public function updateMatrix():Void {
        matrix.compose(position, quaternion, scale);
        matrixWorldNeedsUpdate = true;
    }

    public function updateMatrixWorld(force:Bool):Void {
        if (matrixAutoUpdate) updateMatrix();

        if (matrixWorldNeedsUpdate || force) {
            if (parent == null) {
                matrixWorld.copy(matrix);
            } else {
                matrixWorld.multiplyMatrices(parent.matrixWorld, matrix);
            }

            matrixWorldNeedsUpdate = false;
            force = true;
        }

        for (child in children) {
            if (child.matrixWorldAutoUpdate || force) {
                child.updateMatrixWorld(force);
            }
        }
    }

    public function updateWorldMatrix(updateParents:Bool, updateChildren:Bool):Void {
        var parent = this.parent;

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

    public function toJSON(meta:Dynamic):Dynamic {
        if (meta == null || Reflect.isString(meta)) {
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

            var output = {
                metadata: {
                    version: 4.6,
                    type: "Object",
                    generator: "Object3D.toJSON"
                }
            };
        }

        var object = {};

        object.uuid = uuid;
        object.type = type;

        if (name != "") object.name = name;
        if (castShadow) object.castShadow = true;
        if (receiveShadow) object.receiveShadow = true;
        if (!visible) object.visible = false;
        if (!frustumCulled) object.frustumCulled = false;
        if (renderOrder != 0) object.renderOrder = renderOrder;
        if (Reflect.fields(userData).length > 0) object.userData = JSON.parse(JSON.stringify(userData));

        object.layers = layers.mask;
        object.matrix = matrix.toArray();
        object.up = up.toArray();

        if (!matrixAutoUpdate) object.matrixAutoUpdate = false;

        if (isInstancedMesh) {
            object.type = "InstancedMesh";
            object.count = count;
            object.instanceMatrix = instanceMatrix.toJSON();
            if (instanceColor != null) object.instanceColor = instanceColor.toJSON();
        }

        if (isBatchedMesh) {
            object.type = "BatchedMesh";
            object.perObjectFrustumCulled = perObjectFrustumCulled;
            object.sortObjects = sortObjects;
            object.drawRanges = _drawRanges;
            object.reservedRanges = _reservedRanges;

            object.visibility = _visibility;
            object.active = _active;
            object.bounds = _bounds.map(function (bound) {
                return {
                    boxInitialized: bound.boxInitialized,
                    boxMin: bound.box.min.toArray(),
                    boxMax: bound.box.max.toArray(),

                    sphereInitialized: bound.sphereInitialized,
                    sphereRadius: bound.sphere.radius,
                    sphereCenter: bound.sphere.center.toArray()
                };
            });

            object.maxGeometryCount = _maxGeometryCount;
            object.maxVertexCount = _maxVertexCount;
            object.maxIndexCount = _maxIndexCount;

            object.geometryInitialized = _geometryInitialized;
            object.geometryCount = _geometryCount;

            object.matricesTexture = _matricesTexture.toJSON(meta);

            if (_colorsTexture != null) object.colorsTexture = _colorsTexture.toJSON(meta);

            if (boundingSphere != null) {
                object.boundingSphere = {
                    center: boundingSphere.center.toArray(),
                    radius: boundingSphere.radius
                };
            }

            if (boundingBox != null) {
                object.boundingBox = {
                    min: boundingBox.min.toArray(),
                    max: boundingBox.max.toArray()
                };
            }
        }

        function serialize(library:Dynamic, element:Dynamic):String {
            if (!library.exists(element.uuid)) {
                library.set(element.uuid, element.toJSON(meta));
            }

            return element.uuid;
        }

        if (Reflect.field(object, "type") == "Scene") {
            if (background != null) {
                if (background.isColor) {
                    object.background = background.toJSON();
                } else if (background.isTexture) {
                    object.background = background.toJSON(meta).uuid;
                }
            }

            if (environment != null && environment.isTexture && !Reflect.field(environment, "isRenderTargetTexture")) {
                object.environment = environment.toJSON(meta).uuid;
            }
        } else if (Reflect.field(object, "type") == "Mesh" || Reflect.field(object, "type") == "Line" || Reflect.field(object, "type") == "Points") {
            object.geometry = serialize(meta.geometries, geometry);

            if (Reflect.field(geometry.parameters, "shapes") != null) {
                var shapes = geometry.parameters.shapes;

                if (Array.isArray(shapes)) {
                    for (shape in shapes) {
                        serialize(meta.shapes, shape);
                    }
                } else {
                    serialize(meta.shapes, shapes);
                }
            }
        }

        if (Reflect.field(object, "type") == "SkinnedMesh") {
            object.bindMode = bindMode;
            object.bindMatrix = bindMatrix.toArray();

            if (skeleton != null) {
                serialize(meta.skeletons, skeleton);
                object.skeleton = skeleton.uuid;
            }
        }

        if (material != null) {
            if (Array.isArray(material)) {
                var uuids = [];

                for (mat in material) {
                    uuids.push(serialize(meta.materials, mat));
                }

                object.material = uuids;
            } else {
                object.material = serialize(meta.materials, material);
            }
        }

        if (children.length > 0) {
            object.children = [];

            for (child in children) {
                object.children.push(child.toJSON(meta).object);
            }
        }

        if (animations.length > 0) {
            object.animations = [];

            for (anim in animations) {
                object.animations.push(serialize(meta.animations, anim));
            }
        }

        if (Reflect.field(meta, "geometries") != null && Reflect.field(meta, "materials") != null && Reflect.field(meta, "textures") != null && Reflect.field(meta, "images") != null && Reflect.field(meta, "shapes") != null && Reflect.field(meta, "skeletons") != null && Reflect.field(meta, "animations") != null && Reflect.field(meta, "nodes") != null) {
            output.geometries = extractFromCache(meta.geometries);
            output.materials = extractFromCache(meta.materials);
            output.textures = extractFromCache(meta.textures);
            output.images = extractFromCache(meta.images);
            output.shapes = extractFromCache(meta.shapes);
            output.skeletons = extractFromCache(meta.skeletons);
            output.animations = extractFromCache(meta.animations);
            output.nodes = extractFromCache(meta.nodes);
        }

        output.object = object;
        return output;
    }

    public function clone(recursive:Bool = true):Object3D {
        return new this.constructor().copy(this, recursive);
    }

    public function copy(source:Object3D, recursive:Bool = true):Object3D {
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

        if (recursive) {
            for (child in source.children) {
                add(child.clone());
            }
        }

        return this;
    }

    private function extractFromCache(cache:Dynamic):Array<Dynamic> {
        var values = [];

        for (key in cache) {
            var data = cache[key];
            Reflect.deleteField(data, "metadata");
            values.push(data);
        }

        return values;
    }
}