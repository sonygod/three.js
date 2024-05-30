import js.three.BufferAttribute;
import js.three.BufferGeometry;
import js.three.Color;
import js.three.Group;
import js.three.Matrix4;
import js.three.Mesh;
import js.three.Vector3;

function createMeshesFromInstancedMesh(instancedMesh:Mesh):Group {
    var group = new Group();
    var count = instancedMesh.count;
    var geometry = instancedMesh.geometry;
    var material = instancedMesh.material;
    var mesh:Mesh;
    var i:Int;

    for (i = 0; i < count; i++) {
        mesh = new Mesh(geometry, material);
        instancedMesh.getMatrixAt(i, mesh.matrix);
        mesh.matrix.decompose(mesh.position, mesh.quaternion, mesh.scale);
        group.add(mesh);
    }

    group.copy(instancedMesh);
    group.updateMatrixWorld();

    return group;
}

function createMeshesFromMultiMaterialMesh(mesh:Mesh):Group {
    if (!Std.is(mesh.material, Array)) {
        trace("THREE.SceneUtils.createMeshesFromMultiMaterialMesh(): The given mesh has no multiple materials.");
        return mesh;
    }

    var object = new Group();
    object.copy(mesh);

    // merge groups (which automatically sorts them)
    var geometry = mergeGroups(mesh.geometry);

    var index = geometry.index;
    var groups = geometry.groups;
    var attributeNames = Reflect.fields(geometry.attributes);

    // create a mesh for each group by extracting the buffer data into a new geometry
    var group:Dynamic;
    var start:Int;
    var end:Int;
    var newGeometry:BufferGeometry;
    var newMaterial:Dynamic;
    var name:String;
    var attribute:Dynamic;
    var itemSize:Int;
    var newLength:Int;
    var type:Dynamic;
    var newArray:Dynamic;
    var newAttribute:BufferAttribute;
    var newMesh:Mesh;
    var j:Int;
    var k:Int;
    var n:Int;

    for (j = 0; j < groups.length; j++) {
        group = groups[j];
        start = group.start;
        end = start + group.count;
        newGeometry = new BufferGeometry();
        newMaterial = mesh.material[group.materialIndex];

        // process all buffer attributes
        for (k = 0; k < attributeNames.length; k++) {
            name = attributeNames[k];
            attribute = geometry.attributes[name];
            itemSize = attribute.itemSize;
            newLength = group.count * itemSize;
            type = Reflect.field(attribute.array, "constructor");
            newArray = Type.createInstance(type, [newLength]);
            newAttribute = new BufferAttribute(newArray, itemSize);

            for (k = start, n = 0; k < end; k++, n++) {
                if (itemSize >= 1) newAttribute.setX(n, attribute.getX(index.getX(k)));
                if (itemSize >= 2) newAttribute.setY(n, attribute.getY(index.getX(k)));
                if (itemSize >= 3) newAttribute.setZ(n, attribute.getZ(index.getX(k)));
                if (itemSize >= 4) newAttribute.setW(n, attribute.getW(index.getX(k)));
            }

            newGeometry.setAttribute(name, newAttribute);
        }

        newMesh = new Mesh(newGeometry, newMaterial);
        object.add(newMesh);
    }

    return object;
}

function createMultiMaterialObject(geometry:BufferGeometry, materials:Array<Dynamic>):Group {
    var group = new Group();
    var i:Int;
    var l:Int;

    for (i = 0, l = materials.length; i < l; i++) {
        group.add(new Mesh(geometry, materials[i]));
    }

    return group;
}

function reduceVertices(object:Dynamic, func:Dynamic, initialValue:Dynamic):Dynamic {
    var value = initialValue;
    var vertex = new Vector3();

    object.updateWorldMatrix(true, true);

    object.traverseVisible((child) -> {
        var geometry = child.geometry;

        if (geometry != null) {
            var position = geometry.attributes.position;

            if (position != null) {
                var i:Int;
                var l:Int;

                for (i = 0, l = position.count; i < l; i++) {
                    if (child.isMesh) {
                        child.getVertexPosition(i, vertex);
                    } else {
                        vertex.fromBufferAttribute(position, i);
                    }

                    if (!child.isSkinnedMesh) {
                        vertex.applyMatrix4(child.matrixWorld);
                    }

                    value = func(value, vertex);
                }
            }
        }
    });

    return value;
}

function sortInstancedMesh(mesh:Mesh, compareFn:Dynamic):Void {
    // store copy of instanced attributes for lookups
    var instanceMatrixRef = deepCloneAttribute(mesh.instanceMatrix);
    var instanceColorRef:Dynamic;

    if (mesh.instanceColor != null) {
        instanceColorRef = deepCloneAttribute(mesh.instanceColor);
    }

    var attributeRefs = new Map();
    var name:String;
    var attribute:Dynamic;

    for (name in mesh.geometry.attributes) {
        attribute = mesh.geometry.attributes[name];

        if (attribute.isInstancedBufferAttribute) {
            attributeRefs.set(attribute, deepCloneAttribute(attribute));
        }
    }

    // compute sort order
    var tokens = [];
    var i:Int;

    for (i = 0; i < mesh.count; i++) {
        tokens.push(i);
    }

    tokens.sort(compareFn);

    // apply sort order
    var refIndex:Int;
    var _matrix = new Matrix4();
    var _color = new Color();

    for (i = 0; i < tokens.length; i++) {
        refIndex = tokens[i];

        _matrix.fromArray(instanceMatrixRef.array, refIndex * mesh.instanceMatrix.itemSize);
        _matrix.toArray(mesh.instanceMatrix.array, i * mesh.instanceMatrix.itemSize);

        if (mesh.instanceColor != null) {
            _color.fromArray(instanceColorRef.array, refIndex * mesh.instanceColor.itemSize);
            _color.toArray(mesh.instanceColor.array, i * mesh.instanceColor.itemSize);
        }

        for (name in mesh.geometry.attributes) {
            attribute = mesh.geometry.attributes[name];

            if (attribute.isInstancedBufferAttribute) {
                var attributeRef = attributeRefs.get(attribute);

                attribute.setX(i, attributeRef.getX(refIndex));

                if (attribute.itemSize > 1) {
                    attribute.setY(i, attributeRef.getY(refIndex));
                }

                if (attribute.itemSize > 2) {
                    attribute.setZ(i, attributeRef.getZ(refIndex));
                }

                if (attribute.itemSize > 3) {
                    attribute.setW(i, attributeRef.getW(refIndex));
                }
            }
        }
    }
}

function* traverseGenerator(object:Dynamic):Iterator<Dynamic> {
    yield object;

    var children = object.children;
    var i:Int;
    var l:Int;

    for (i = 0, l = children.length; i < l; i++) {
        yield* traverseGenerator(children[i]);
    }
}

function* traverseVisibleGenerator(object:Dynamic):Iterator<Dynamic> {
    if (object.visible == false) {
        return;
    }

    yield object;

    var children = object.children;
    var i:Int;
    var l:Int;

    for (i = 0, l = children.length; i < l; i++) {
        yield* traverseVisibleGenerator(children[i]);
    }
}

function* traverseAncestorsGenerator(object:Dynamic):Iterator<Dynamic> {
    var parent = object.parent;

    if (parent != null) {
        yield parent;
        yield* traverseAncestorsGenerator(parent);
    }
}

class BufferGeometryUtils {
    public static function createMeshesFromInstancedMesh(instancedMesh:Mesh):Group {
        return createMeshesFromInstancedMesh(instancedMesh);
    }

    public static function createMeshesFromMultiMaterialMesh(mesh:Mesh):Group {
        return createMeshesFromMultiMaterialMesh(mesh);
    }

    public static function createMultiMaterialObject(geometry:BufferGeometry, materials:Array<Dynamic>):Group {
        return createMultiMaterialObject(geometry, materials);
    }

    public static function reduceVertices(object:Dynamic, func:Dynamic, initialValue:Dynamic):Dynamic {
        return reduceVertices(object, func, initialValue);
    }

    public static function sortInstancedMesh(mesh:Mesh, compareFn:Dynamic):Void {
        sortInstancedMesh(mesh, compareFn);
    }

    public static function* traverseGenerator(object:Dynamic):Iterator<Dynamic> {
        yield* traverseGenerator(object);
    }

    public static function* traverseVisibleGenerator(object:Dynamic):Iterator<Dynamic> {
        yield* traverseVisibleGenerator(object);
    }

    public static function* traverseAncestorsGenerator(object:Dynamic):Iterator<Dynamic> {
        yield* traverseAncestorsGenerator(object);
    }
}