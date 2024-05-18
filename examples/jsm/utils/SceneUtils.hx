Here is the converted Haxe code:
```
package three.js.examples.jsm.utils;

import three.BufferAttribute;
import three.BufferGeometry;
import three.Color;
import three.Group;
import three.Matrix4;
import three.Mesh;
import three.Vector3;

class SceneUtils {
    private static var _color:Color = new Color();
    private static var _matrix:Matrix4 = new Matrix4();

    public static function createMeshesFromInstancedMesh(instancedMesh:InstancedMesh):Group {
        var group = new Group();

        var count:Int = instancedMesh.count;
        var geometry:BufferGeometry = instancedMesh.geometry;
        var material:Material = instancedMesh.material;

        for (i in 0...count) {
            var mesh = new Mesh(geometry, material);
            instancedMesh.getMatrixAt(i, mesh.matrix);
            mesh.matrix.decompose(mesh.position, mesh.quaternion, mesh.scale);
            group.add(mesh);
        }

        group.copy(instancedMesh);
        group.updateMatrixWorld(); // ensure correct world matrices of meshes
        return group;
    }

    public static function createMeshesFromMultiMaterialMesh(mesh:Mesh):Group {
        if (!Array.isArray(mesh.material)) {
            Console.warn('THREE.SceneUtils.createMeshesFromMultiMaterialMesh(): The given mesh has no multiple materials.');
            return mesh;
        }

        var object = new Group();
        object.copy(mesh);

        var geometry:BufferGeometry = mergeGroups(mesh.geometry);

        var index:BufferAttribute = geometry.index;
        var groups:Array<BufferGeometry> = geometry.groups;
        var attributeNames:Array<String> = [for (name in geometry.attributes.keys()) name];

        for (i in 0...groups.length) {
            var group:BufferGeometry = groups[i];
            var start:Int = group.start;
            var end:Int = start + group.count;

            var newGeometry:BufferGeometry = new BufferGeometry();
            var newMaterial:Material = mesh.material[group.materialIndex];

            for (j in 0...attributeNames.length) {
                var name:String = attributeNames[j];
                var attribute:BufferAttribute = geometry.attributes[name];
                var itemSize:Int = attribute.itemSize;

                var newLength:Int = group.count * itemSize;
                var type:Class<Dynamic> = attribute.array.constructor;

                var newArray:Array<Dynamic> = Type.createInstance(type, newLength);
                var newAttribute:BufferAttribute = new BufferAttribute(newArray, itemSize);

                for (k in start...end) {
                    var ind:Int = index.getX(k);
                    if (itemSize >= 1) newAttribute.setX(k - start, attribute.getX(ind));
                    if (itemSize >= 2) newAttribute.setY(k - start, attribute.getY(ind));
                    if (itemSize >= 3) newAttribute.setZ(k - start, attribute.getZ(ind));
                    if (itemSize >= 4) newAttribute.setW(k - start, attribute.getW(ind));
                }

                newGeometry.setAttribute(name, newAttribute);
            }

            var newMesh:Mesh = new Mesh(newGeometry, newMaterial);
            object.add(newMesh);
        }

        return object;
    }

    public static function createMultiMaterialObject(geometry:BufferGeometry, materials:Array<Material>):Group {
        var group = new Group();

        for (i in 0...materials.length) {
            group.add(new Mesh(geometry, materials[i]));
        }

        return group;
    }

    public static function reduceVertices(object:Object3D, func:Int->Int->Int, initialValue:Int):Int {
        var value:Int = initialValue;
        var vertex:Vector3 = new Vector3();

        object.updateWorldMatrix(true, true);

        iterateVisible(object, function(child:Object3D) {
            var geometry:BufferGeometry = child.geometry;

            if (geometry != null) {
                var position:BufferAttribute = geometry.attributes.get('position');

                if (position != null) {
                    for (i in 0...position.count) {
                        if (child.isMesh) {
                            child.getVertexPosition(i, vertex);
                        } else {
                            vertex.fromBufferAttribute(position, i);
                        }

                        if (!child.isSkinnedMesh) {
                            vertex.applyMatrix4(child.matrixWorld);
                        }

                        value = func(value, vertex.x);
                    }
                }
            }
        });

        return value;
    }

    public static function sortInstancedMesh(mesh:InstancedMesh, compareFn:Int->Int->Int) {
        var instanceMatrixRef:BufferAttribute = deepCloneAttribute(mesh.instanceMatrix);
        var instanceColorRef:BufferAttribute = mesh.instanceColor != null ? deepCloneAttribute(mesh.instanceColor) : null;

        var attributeRefs:Map<String, BufferAttribute> = new Map();

        for (name in mesh.geometry.attributes.keys()) {
            var attribute:BufferAttribute = mesh.geometry.attributes[name];

            if (attribute.isInstancedBufferAttribute) {
                attributeRefs[name] = deepCloneAttribute(attribute);
            }
        }

        var tokens:Array<Int> = [for (i in 0...mesh.count) i];
        tokens.sort(compareFn);

        for (i in 0...tokens.length) {
            var refIndex:Int = tokens[i];

            _matrix.fromArray(instanceMatrixRef.array, refIndex * mesh.instanceMatrix.itemSize);
            _matrix.toArray(mesh.instanceMatrix.array, i * mesh.instanceMatrix.itemSize);

            if (mesh.instanceColor != null) {
                _color.fromArray(instanceColorRef.array, refIndex * mesh.instanceColor.itemSize);
                _color.toArray(mesh.instanceColor.array, i * mesh.instanceColor.itemSize);
            }

            for (name in mesh.geometry.attributes.keys()) {
                var attribute:BufferAttribute = mesh.geometry.attributes[name];

                if (attribute.isInstancedBufferAttribute) {
                    var attributeRef:BufferAttribute = attributeRefs[name];

                    attribute.setX(i, attributeRef.getX(refIndex));
                    if (attribute.itemSize > 1) attribute.setY(i, attributeRef.getY(refIndex));
                    if (attribute.itemSize > 2) attribute.setZ(i, attributeRef.getZ(refIndex));
                    if (attribute.itemSize > 3) attribute.setW(i, attributeRef.getW(refIndex));
                }
            }
        }
    }

    public static function traverseGenerator(object:Object3D):Iterator<Object3D> {
        return new TraverseGenerator(object);
    }

    public static function traverseVisibleGenerator(object:Object3D):Iterator<Object3D> {
        return new TraverseVisibleGenerator(object);
    }

    public static function traverseAncestorsGenerator(object:Object3D):Iterator<Object3D> {
        return new TraverseAncestorsGenerator(object);
    }
}

class TraverseGenerator {
    private var object:Object3D;
    private var iterator:Iterator<Object3D>;

    public function new(object:Object3D) {
        this.object = object;
        this.iterator = iterate(object);
    }

    public function hasNext():Bool {
        return iterator.hasNext();
    }

    public function next():Object3D {
        return iterator.next();
    }
}

class TraverseVisibleGenerator extends TraverseGenerator {
    override public function hasNext():Bool {
        return iterator.hasNext();
    }

    override public function next():Object3D {
        return iterator.next();
    }
}

class TraverseAncestorsGenerator extends TraverseGenerator {
    override public function hasNext():Bool {
        return iterator.hasNext();
    }

    override public function next():Object3D {
        return iterator.next();
    }
}

private function iterate(object:Object3D):Iterator<Object3D> {
    return new Iterator<Object3D>(function():Object3D {
        var child:Object3D = null;

        while (child == null) {
            if (object.visible) {
                child = object;
            }

            object = object.parent;
            if (object == null) break;
        }

        return child;
    });
}

private function iterateVisible(object:Object3D):Void {
    if (!object.visible) return;

    iterate(object);

    for (child in object.children) {
        iterateVisible(child);
    }
}

private function iterateAncestors(object:Object3D):Void {
    while (object != null) {
        iterate(object);
        object = object.parent;
    }
}
```
Note that I had to make some assumptions about the Haxe types and classes, as they are not always explicitly defined in the JavaScript code. Additionally, I had to create some Haxe classes and iterators to mimic the behavior of the JavaScript generators.