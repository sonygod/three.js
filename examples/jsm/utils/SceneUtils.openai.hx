package three.js.utils;

import three.js.BufferAttribute;
import three.js.BufferGeometry;
import three.js.Color;
import three.js.Group;
import three.js.Matrix4;
import three.js.Mesh;
import three.js.Vector3;

import three.js.utils.BufferGeometryUtils;

class SceneUtils {
  static var _color:Color = new Color();
  static var _matrix:Matrix4 = new Matrix4();

  static function createMeshesFromInstancedMesh(instancedMesh:InstancedMesh) {
    var group = new Group();

    var count = instancedMesh.count;
    var geometry = instancedMesh.geometry;
    var material = instancedMesh.material;

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

  static function createMeshesFromMultiMaterialMesh(mesh:Mesh) {
    if (!Std.isOfType(mesh.material, Array)) {
      console.warn('THREE.SceneUtils.createMeshesFromMultiMaterialMesh(): The given mesh has no multiple materials.');
      return mesh;
    }

    var object = new Group();
    object.copy(mesh);

    // merge groups (which automatically sorts them)
    var geometry = mergeGroups(mesh.geometry);

    var index = geometry.index;
    var groups = geometry.groups;
    var attributeNames:Array<String> = [for (name in geometry.attributes.keys()) name];

    // create a mesh for each group by extracting the buffer data into a new geometry
    for (i in 0...groups.length) {
      var group = groups[i];

      var start = group.start;
      var end = start + group.count;

      var newGeometry = new BufferGeometry();
      var newMaterial = mesh.material[group.materialIndex];

      // process all buffer attributes
      for (j in 0...attributeNames.length) {
        var name = attributeNames[j];
        var attribute = geometry.attributes[name];
        var itemSize = attribute.itemSize;

        var newLength = group.count * itemSize;
        var type = attribute.array-elementType;

        var newArray:Array<Dynamic> = [for (i in 0...newLength) null];
        var newAttribute = new BufferAttribute(newArray, itemSize);

        for (k in start...end) {
          var ind = index.getX(k);

          if (itemSize >= 1) newAttribute.setX(k - start, attribute.getX(ind));
          if (itemSize >= 2) newAttribute.setY(k - start, attribute.getY(ind));
          if (itemSize >= 3) newAttribute.setZ(k - start, attribute.getZ(ind));
          if (itemSize >= 4) newAttribute.setW(k - start, attribute.getW(ind));
        }

        newGeometry.setAttribute(name, newAttribute);
      }

      var newMesh = new Mesh(newGeometry, newMaterial);
      object.add(newMesh);
    }

    return object;
  }

  static function createMultiMaterialObject(geometry:BufferGeometry, materials:Array<Material>) {
    var group = new Group();

    for (i in 0...materials.length) {
      group.add(new Mesh(geometry, materials[i]));
    }

    return group;
  }

  static function reduceVertices(object:Object3D, func:Int->Int->Int, initialValue:Int) {
    var value = initialValue;
    var vertex = new Vector3();

    object.updateWorldMatrix(true, true);

    object.traverseVisible(function(child:Object3D) {
      if (child.geometry != null) {
        var position = child.geometry.attributes.position;

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

            value = func(value, vertex);
          }
        }
      }
    });

    return value;
  }

  /**
   * @param {InstancedMesh}
   * @param {function(int, int):int}
   */
  static function sortInstancedMesh(mesh:InstancedMesh, compareFn:Int->Int->Int) {
    // store copy of instanced attributes for lookups
    var instanceMatrixRef = deepCloneAttribute(mesh.instanceMatrix);
    var instanceColorRef = mesh.instanceColor != null ? deepCloneAttribute(mesh.instanceColor) : null;

    var attributeRefs = new Map<String, BufferAttribute>();

    for (name in mesh.geometry.attributes.keys()) {
      var attribute = mesh.geometry.attributes[name];

      if (attribute.isInstancedBufferAttribute) {
        attributeRefs[name] = deepCloneAttribute(attribute);
      }
    }

    // compute sort order
    var tokens:Array<Int> = [for (i in 0...mesh.count) i];
    tokens.sort(compareFn);

    // apply sort order
    for (i in 0...tokens.length) {
      var refIndex = tokens[i];

      _matrix.fromArray(instanceMatrixRef.array, refIndex * mesh.instanceMatrix.itemSize);
      _matrix.toArray(mesh.instanceMatrix.array, i * mesh.instanceMatrix.itemSize);

      if (mesh.instanceColor != null) {
        _color.fromArray(instanceColorRef.array, refIndex * mesh.instanceColor.itemSize);
        _color.toArray(mesh.instanceColor.array, i * mesh.instanceColor.itemSize);
      }

      for (name in mesh.geometry.attributes.keys()) {
        var attribute = mesh.geometry.attributes[name];

        if (attribute.isInstancedBufferAttribute) {
          var attributeRef = attributeRefs[name];

          attribute.setX(i, attributeRef.getX(refIndex));
          if (attribute.itemSize > 1) attribute.setY(i, attributeRef.getY(refIndex));
          if (attribute.itemSize > 2) attribute.setZ(i, attributeRef.getZ(refIndex));
          if (attribute.itemSize > 3) attribute.setW(i, attributeRef.getW(refIndex));
        }
      }
    }
  }

  static function* traverseGenerator(object:Object3D) {
    yield object;

    var children:Array<Object3D> = object.children;

    for (i in 0...children.length) {
      yield* traverseGenerator(children[i]);
    }
  }

  static function* traverseVisibleGenerator(object:Object3D) {
    if (!object.visible) return;

    yield object;

    var children:Array<Object3D> = object.children;

    for (i in 0...children.length) {
      yield* traverseVisibleGenerator(children[i]);
    }
  }

  static function* traverseAncestorsGenerator(object:Object3D) {
    var parent:Object3D = object.parent;

    if (parent != null) {
      yield parent;
      yield* traverseAncestorsGenerator(parent);
    }
  }
}