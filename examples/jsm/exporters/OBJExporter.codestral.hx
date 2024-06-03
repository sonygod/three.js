import js.Browser.document;
import three.js.math.Color;
import three.js.math.Matrix3;
import three.js.math.Vector2;
import three.js.math.Vector3;

class OBJExporter {

	public function parse(object:Dynamic):String {

		var output:String = '';

		var indexVertex:Int = 0;
		var indexVertexUvs:Int = 0;
		var indexNormals:Int = 0;

		var vertex:Vector3 = new Vector3();
		var color:Color = new Color();
		var normal:Vector3 = new Vector3();
		var uv:Vector2 = new Vector2();

		var face:Array<String> = [];

		function parseMesh(mesh:Dynamic):Void {

			var nbVertex:Int = 0;
			var nbNormals:Int = 0;
			var nbVertexUvs:Int = 0;

			var geometry = mesh.geometry;

			var normalMatrixWorld:Matrix3 = new Matrix3();

			// shortcuts
			var vertices = geometry.getAttribute('position');
			var normals = geometry.getAttribute('normal');
			var uvs = geometry.getAttribute('uv');
			var indices = geometry.getIndex();

			// name of the mesh object
			output += 'o ' + mesh.name + '\n';

			// name of the mesh material
			if (mesh.material != null && Reflect.hasField(mesh.material, "name")) {

				output += 'usemtl ' + mesh.material.name + '\n';

			}

			// vertices

			if (vertices != null) {

				for (var i:Int = 0; i < vertices.count; i++) {

					vertex.fromBufferAttribute(vertices, i);

					// transform the vertex to world space
					vertex.applyMatrix4(mesh.matrixWorld);

					// transform the vertex to export format
					output += 'v ' + vertex.x + ' ' + vertex.y + ' ' + vertex.z + '\n';
					nbVertex++;
				}

			}

			// uvs

			if (uvs != null) {

				for (var i:Int = 0; i < uvs.count; i++) {

					uv.fromBufferAttribute(uvs, i);

					// transform the uv to export format
					output += 'vt ' + uv.x + ' ' + uv.y + '\n';
					nbVertexUvs++;
				}

			}

			// normals

			if (normals != null) {

				normalMatrixWorld.getNormalMatrix(mesh.matrixWorld);

				for (var i:Int = 0; i < normals.count; i++) {

					normal.fromBufferAttribute(normals, i);

					// transform the normal to world space
					normal.applyMatrix3(normalMatrixWorld).normalize();

					// transform the normal to export format
					output += 'vn ' + normal.x + ' ' + normal.y + ' ' + normal.z + '\n';
					nbNormals++;
				}

			}

			// faces

			if (indices != null) {

				for (var i:Int = 0; i < indices.count; i += 3) {

					for (var m:Int = 0; m < 3; m++) {

						var j = indices.getX(i + m) + 1;

						face[m] = (indexVertex + j) + (normals != null || uvs != null ? '/' + (uvs != null ? (indexVertexUvs + j).toString() : '') + (normals != null ? '/' + (indexNormals + j).toString() : '') : '');

					}

					// transform the face to export format
					output += 'f ' + face.join(' ') + '\n';

				}

			} else {

				for (var i:Int = 0; i < vertices.count; i += 3) {

					for (var m:Int = 0; m < 3; m++) {

						var j = i + m + 1;

						face[m] = (indexVertex + j) + (normals != null || uvs != null ? '/' + (uvs != null ? (indexVertexUvs + j).toString() : '') + (normals != null ? '/' + (indexNormals + j).toString() : '') : '');

					}

					// transform the face to export format
					output += 'f ' + face.join(' ') + '\n';

				}

			}

			// update index
			indexVertex += nbVertex;
			indexVertexUvs += nbVertexUvs;
			indexNormals += nbNormals;

		}

		// parseLine and parsePoints functions are omitted for brevity
		// as they require similar adjustments to the JavaScript code

		// traverse
		object.traverse(function (child:Dynamic) {

			if (Reflect.hasField(child, "isMesh") && child.isMesh) {

				parseMesh(child);

			}

			// Add similar conditions for parseLine and parsePoints functions

		});

		return output;

	}

}