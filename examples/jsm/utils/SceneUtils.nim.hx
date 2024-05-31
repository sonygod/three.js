import three.js.examples.jsm.utils.BufferGeometryUtils;
import three.js.examples.jsm.utils.SceneUtils;
import three.js.examples.jsm.utils.BufferGeometryUtils.*;
import three.js.examples.jsm.utils.SceneUtils.*;
import three.js.examples.jsm.utils.BufferGeometryUtils.mergeGroups;
import three.js.examples.jsm.utils.BufferGeometryUtils.deepCloneAttribute;
import three.js.examples.jsm.utils.SceneUtils.createMeshesFromInstancedMesh;
import three.js.examples.jsm.utils.SceneUtils.createMeshesFromMultiMaterialMesh;
import three.js.examples.jsm.utils.SceneUtils.createMultiMaterialObject;
import three.js.examples.jsm.utils.SceneUtils.reduceVertices;
import three.js.examples.jsm.utils.SceneUtils.sortInstancedMesh;
import three.js.examples.jsm.utils.SceneUtils.traverseGenerator;
import three.js.examples.jsm.utils.SceneUtils.traverseVisibleGenerator;
import three.js.examples.jsm.utils.SceneUtils.traverseAncestorsGenerator;
import three.js.examples.jsm.utils.BufferGeometryUtils.mergeGroups;
import three.js.examples.jsm.utils.BufferGeometryUtils.deepCloneAttribute;
import three.js.examples.jsm.utils.SceneUtils.createMeshesFromInstancedMesh;
import three.js.examples.jsm.utils.SceneUtils.createMeshesFromMultiMaterialMesh;
import three.js.examples.jsm.utils.SceneUtils.createMultiMaterialObject;
import three.js.examples.jsm.utils.SceneUtils.reduceVertices;
import three.js.examples.jsm.utils.SceneUtils.sortInstancedMesh;
import three.js.examples.jsm.utils.SceneUtils.traverseGenerator;
import three.js.examples.jsm.utils.SceneUtils.traverseVisibleGenerator;
import three.js.examples.jsm.utils.SceneUtils.traverseAncestorsGenerator;

class SceneUtils {
	static function createMeshesFromInstancedMesh(instancedMesh:InstancedMesh):Group {
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
		group.updateMatrixWorld();
		return group;
	}

	static function createMeshesFromMultiMaterialMesh(mesh:Mesh):Group {
		if (!Array.isArray(mesh.material)) {
			console.warn('THREE.SceneUtils.createMeshesFromMultiMaterialMesh(): The given mesh has no multiple materials.');
			return mesh;
		}
		var object = new Group();
		object.copy(mesh);
		var geometry = mergeGroups(mesh.geometry);
		var index = geometry.index;
		var groups = geometry.groups;
		var attributeNames = Reflect.fields(geometry.attributes);
		for (i in 0...groups.length) {
			var group = groups[i];
			var start = group.start;
			var end = start + group.count;
			var newGeometry = new BufferGeometry();
			var newMaterial = mesh.material[group.materialIndex];
			for (j in 0...attributeNames.length) {
				var name = attributeNames[j];
				var attribute = geometry.attributes[name];
				var itemSize = attribute.itemSize;
				var newLength = group.count * itemSize;
				var type = attribute.array.constructor;
				var newArray = new type(newLength);
				var newAttribute = new BufferAttribute(newArray, itemSize);
				for (k in start...end) {
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

	static function createMultiMaterialObject(geometry:BufferGeometry, materials:Array<Material>):Group {
		var group = new Group();
		for (i in 0...materials.length) {
			group.add(new Mesh(geometry, materials[i]));
		}
		return group;
	}

	static function reduceVertices(object:Object3D, func:Dynamic, initialValue:Dynamic):Dynamic {
		var value = initialValue;
		var vertex = new Vector3();
		object.updateWorldMatrix(true, true);
		object.traverseVisible((child) => {
			var geometry = child.geometry;
			if (geometry !== undefined) {
				var position = geometry.attributes.position;
				if (position !== undefined) {
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

	static function sortInstancedMesh(mesh:InstancedMesh, compareFn:Dynamic):Void {
		var instanceMatrixRef = deepCloneAttribute(mesh.instanceMatrix);
		var instanceColorRef = mesh.instanceColor ? deepCloneAttribute(mesh.instanceColor) : null;
		var attributeRefs = new Map<BufferAttribute, BufferAttribute>();
		for (name in mesh.geometry.attributes) {
			var attribute = mesh.geometry.attributes[name];
			if (attribute.isInstancedBufferAttribute) {
				attributeRefs.set(attribute, deepCloneAttribute(attribute));
			}
		}
		var tokens = [];
		for (i in 0...mesh.count) tokens.push(i);
		tokens.sort(compareFn);
		for (i in 0...tokens.length) {
			var refIndex = tokens[i];
			_matrix.fromArray(instanceMatrixRef.array, refIndex * mesh.instanceMatrix.itemSize);
			_matrix.toArray(mesh.instanceMatrix.array, i * mesh.instanceMatrix.itemSize);
			if (mesh.instanceColor) {
				_color.fromArray(instanceColorRef.array, refIndex * mesh.instanceColor.itemSize);
				_color.toArray(mesh.instanceColor.array, i * mesh.instanceColor.itemSize);
			}
			for (name in mesh.geometry.attributes) {
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

	static function* traverseGenerator(object:Object3D):Iterator<Object3D> {
		yield object;
		var children = object.children;
		for (i in 0...children.length) {
			yield* traverseGenerator(children[i]);
		}
	}

	static function* traverseVisibleGenerator(object:Object3D):Iterator<Object3D> {
		if (object.visible == false) return;
		yield object;
		var children = object.children;
		for (i in 0...children.length) {
			yield* traverseVisibleGenerator(children[i]);
		}
	}

	static function* traverseAncestorsGenerator(object:Object3D):Iterator<Object3D> {
		var parent = object.parent;
		if (parent != null) {
			yield parent;
			yield* traverseAncestorsGenerator(parent);
		}
	}
}