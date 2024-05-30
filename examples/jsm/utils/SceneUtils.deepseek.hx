import three.BufferAttribute;
import three.BufferGeometry;
import three.Color;
import three.Group;
import three.Matrix4;
import three.Mesh;
import three.Vector3;

import SceneUtils.BufferGeometryUtils.*;

private static var _color = new Color();
private static var _matrix = new Matrix4();

public static function createMeshesFromInstancedMesh(instancedMesh:Mesh):Group {

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

public static function createMeshesFromMultiMaterialMesh(mesh:Mesh):Group {

	if (!(mesh.material is Array)) {

		trace('THREE.SceneUtils.createMeshesFromMultiMaterialMesh(): The given mesh has no multiple materials.');
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
			var type = attribute.array.constructor;

			var newArray = new type(newLength);
			var newAttribute = new BufferAttribute(newArray, itemSize);

			for (k in start...end, n in 0...group.count) {

				var ind = index.getX(k);

				if (itemSize >= 1) newAttribute.setX(n, attribute.getX(ind));
				if (itemSize >= 2) newAttribute.setY(n, attribute.getY(ind));
				if (itemSize >= 3) newAttribute.setZ(n, attribute.getZ(ind));
				if (itemSize >= 4) newAttribute.setW(n, attribute.getW(ind));

			}

			newGeometry.setAttribute(name, newAttribute);

		}

		var newMesh = new Mesh(newGeometry, newMaterial);
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

	var value = initialValue;
	var vertex = new Vector3();

	object.updateWorldMatrix(true, true);

	object.traverseVisible((child) -> {

		var geometry = child.geometry;

		if (geometry != null) {

			var position = geometry.attributes.position;

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
public static function sortInstancedMesh(mesh:Mesh, compareFn:Int->Int->Int):Void {

	// store copy of instanced attributes for lookups

	var instanceMatrixRef = deepCloneAttribute(mesh.instanceMatrix);
	var instanceColorRef = mesh.instanceColor ? deepCloneAttribute(mesh.instanceColor) : null;

	var attributeRefs = new Map();

	for (name in Reflect.fields(mesh.geometry.attributes)) {

		var attribute = mesh.geometry.attributes[name];

		if (attribute.isInstancedBufferAttribute) {

			attributeRefs.set(attribute, deepCloneAttribute(attribute));

		}

	}

	// compute sort order

	var tokens = [];

	for (i in 0...mesh.count) tokens.push(i);

	tokens.sort(compareFn);

	// apply sort order

	for (i in 0...tokens.length) {

		var refIndex = tokens[i];

		_matrix.fromArray(instanceMatrixRef.array, refIndex * mesh.instanceMatrix.itemSize);
		_matrix.toArray(mesh.instanceMatrix.array, i * mesh.instanceMatrix.itemSize);

		if (mesh.instanceColor) {

			_color.fromArray(instanceColorRef.array, refIndex * mesh.instanceColor.itemSize);
			_color.toArray(mesh.instanceColor.array, i * mesh.instanceColor.itemSize);

		}

		for (name in Reflect.fields(mesh.geometry.attributes)) {

			var attribute = mesh.geometry.attributes[name];

			if (attribute.isInstancedBufferAttribute) {

				var attributeRef = attributeRefs.get(attribute);

				attribute.setX(i, attributeRef.getX(refIndex));
				if (attribute.itemSize > 1) attribute.setY(i, attributeRef.getY(refIndex));
				if (attribute.itemSize > 2) attribute.setZ(i, attributeRef.getZ(refIndex));
				if (attribute.itemSize > 3) attribute.setW(i, attributeRef.getW(refIndex));

			}

		}

	}

}

/**
 * @param {Object3D} object Object to traverse.
 * @yields {Object3D} Objects that passed the filter condition.
 */
public static function traverseGenerator(object:Object3D):Iterator<Object3D> {

	yield object;

	var children = object.children;

	for (i in 0...children.length) {

		yield* traverseGenerator(children[i]);

	}

}

/**
 * @param {Object3D} object Object to traverse.
 * @yields {Object3D} Objects that passed the filter condition.
 */
public static function traverseVisibleGenerator(object:Object3D):Iterator<Object3D> {

	if (object.visible == false) return;

	yield object;

	var children = object.children;

	for (i in 0...children.length) {

		yield* traverseVisibleGenerator(children[i]);

	}

}

/**
 * @param {Object3D} object Object to traverse.
 * @yields {Object3D} Objects that passed the filter condition.
 */
public static function traverseAncestorsGenerator(object:Object3D):Iterator<Object3D> {

	var parent = object.parent;

	if (parent != null) {

		yield parent;

		yield* traverseAncestorsGenerator(parent);

	}

}