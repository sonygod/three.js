import three.Matrix4;
import three.Vector3;
import three.Quaternion;
import three.InstancedMesh;
import three.InstancedBufferAttribute;
import three.Object3D;

class GLTFMeshGpuInstancing {

	public var name:String;
	public var parser:Dynamic;

	public function new(parser) {

		this.name = "EXT_MESH_GPU_INSTANCING";
		this.parser = parser;

	}

	public function createNodeMesh(nodeIndex:Int):Null<Dynamic> {

		var json = this.parser.json;
		var nodeDef = json.nodes[nodeIndex];

		if (nodeDef.extensions == null || nodeDef.extensions[this.name] == null || nodeDef.mesh == null) {

			return null;

		}

		var meshDef = json.meshes[nodeDef.mesh];

		// No Points or Lines + Instancing support yet
		for (primitive in meshDef.primitives) {

			if (primitive.mode != three.Constants.Triangles &&
				primitive.mode != three.Constants.TriangleStrip &&
				primitive.mode != three.Constants.TriangleFan &&
				primitive.mode != null) {

				return null;

			}

		}

		var extensionDef:Dynamic = nodeDef.extensions[this.name];
		var attributesDef:Dynamic = extensionDef.attributes;

		// @TODO: Can we support InstancedMesh + SkinnedMesh?

		var pending:Array<js.lib.Promise<Dynamic>> = [];
		var attributes:Dynamic = {};

		for (key in Reflect.fields(attributesDef)) {

			pending.push(this.parser.getDependency('accessor', attributesDef[key]).then(function(accessor) {

				attributes[key] = accessor;
				return attributes[key];

			}));

		}

		if (pending.length < 1) {

			return null;

		}

		pending.push(this.parser.createNodeMesh(nodeIndex));

		return js.lib.Promise.all(pending).then(function(results:Array<Dynamic>):Dynamic {

			var nodeObject:Dynamic = results.pop();
			var meshes:Array<Dynamic> = (nodeObject.isGroup) ? nodeObject.children : [nodeObject];
			var count:Int = results[0].count; // All attribute counts should be same
			var instancedMeshes:Array<Dynamic> = [];

			for (mesh in meshes) {

				// Temporal variables
				var m = new Matrix4();
				var p = new Vector3();
				var q = new Quaternion();
				var s = new Vector3(1, 1, 1);

				var instancedMesh:Dynamic = new InstancedMesh(mesh.geometry, mesh.material, count);

				for (i in 0...count) {

					if (attributes.TRANSLATION != null) {

						p.fromBufferAttribute(attributes.TRANSLATION, i);

					}

					if (attributes.ROTATION != null) {

						q.fromBufferAttribute(attributes.ROTATION, i);

					}

					if (attributes.SCALE != null) {

						s.fromBufferAttribute(attributes.SCALE, i);

					}

					instancedMesh.setMatrixAt(i, m.compose(p, q, s));

				}

				// Add instance attributes to the geometry, excluding TRS.
				for (attributeName in Reflect.fields(attributes)) {

					if (attributeName == "_COLOR_0") {

						var attr:Dynamic = attributes[attributeName];
						instancedMesh.instanceColor = new InstancedBufferAttribute(attr.array, attr.itemSize, attr.normalized);

					} else if (attributeName != 'TRANSLATION' &&
						attributeName != 'ROTATION' &&
						attributeName != 'SCALE') {

						mesh.geometry.setAttribute(attributeName, attributes[attributeName]);

					}

				}

				// Just in case
				Object3D.prototype.copy.call(instancedMesh, mesh);

				this.parser.assignFinalMaterial(instancedMesh);

				instancedMeshes.push(instancedMesh);

			}

			if (nodeObject.isGroup) {

				nodeObject.clear();
				nodeObject.add.apply(nodeObject, instancedMeshes);

				return nodeObject;

			}

			return instancedMeshes[0];

		});

	}

}