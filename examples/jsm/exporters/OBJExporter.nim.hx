import three.math.Color;
import three.math.Matrix3;
import three.math.Vector2;
import three.math.Vector3;

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

		function parseMesh(mesh:Dynamic) {

			var nbVertex:Int = 0;
			var nbNormals:Int = 0;
			var nbVertexUvs:Int = 0;

			var geometry:Dynamic = mesh.geometry;

			var normalMatrixWorld:Matrix3 = new Matrix3();

			// shortcuts
			var vertices:Dynamic = geometry.getAttribute('position');
			var normals:Dynamic = geometry.getAttribute('normal');
			var uvs:Dynamic = geometry.getAttribute('uv');
			var indices:Dynamic = geometry.getIndex();

			// name of the mesh object
			output += 'o ' + mesh.name + '\n';

			// name of the mesh material
			if (mesh.material && mesh.material.name) {

				output += 'usemtl ' + mesh.material.name + '\n';

			}

			// vertices

			if (vertices !== null) {

				for (i in 0...vertices.count) {

					vertex.fromBufferAttribute(vertices, i);

					// transform the vertex to world space
					vertex.applyMatrix4(mesh.matrixWorld);

					// transform the vertex to export format
					output += 'v ' + vertex.x + ' ' + vertex.y + ' ' + vertex.z + '\n';

					nbVertex++;

				}

			}

			// uvs

			if (uvs !== null) {

				for (i in 0...uvs.count) {

					uv.fromBufferAttribute(uvs, i);

					// transform the uv to export format
					output += 'vt ' + uv.x + ' ' + uv.y + '\n';

					nbVertexUvs++;

				}

			}

			// normals

			if (normals !== null) {

				normalMatrixWorld.getNormalMatrix(mesh.matrixWorld);

				for (i in 0...normals.count) {

					normal.fromBufferAttribute(normals, i);

					// transform the normal to world space
					normal.applyMatrix3(normalMatrixWorld).normalize();

					// transform the normal to export format
					output += 'vn ' + normal.x + ' ' + normal.y + ' ' + normal.z + '\n';

					nbNormals++;

				}

			}

			// faces

			if (indices !== null) {

				for (i in 0...indices.count) {

					for (m in 0...3) {

						var j:Int = indices.getX(i + m) + 1;

						face[m] = (indexVertex + j) + (normals || uvs ? '/' + (uvs ? (indexVertexUvs + j) : '') + (normals ? '/' + (indexNormals + j) : '') : '');

					}

					// transform the face to export format
					output += 'f ' + face.join(' ') + '\n';

				}

			} else {

				for (i in 0...vertices.count) {

					for (m in 0...3) {

						var j:Int = i + m + 1;

						face[m] = (indexVertex + j) + (normals || uvs ? '/' + (uvs ? (indexVertexUvs + j) : '') + (normals ? '/' + (indexNormals + j) : '') : '');

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

		function parseLine(line:Dynamic) {

			var nbVertex:Int = 0;

			var geometry:Dynamic = line.geometry;
			var type:String = line.type;

			// shortcuts
			var vertices:Dynamic = geometry.getAttribute('position');

			// name of the line object
			output += 'o ' + line.name + '\n';

			if (vertices !== null) {

				for (i in 0...vertices.count) {

					vertex.fromBufferAttribute(vertices, i);

					// transform the vertex to world space
					vertex.applyMatrix4(line.matrixWorld);

					// transform the vertex to export format
					output += 'v ' + vertex.x + ' ' + vertex.y + ' ' + vertex.z + '\n';

					nbVertex++;

				}

			}

			if (type === 'Line') {

				output += 'l ';

				for (j in 1...vertices.count) {

					output += (indexVertex + j) + ' ';

				}

				output += '\n';

			}

			if (type === 'LineSegments') {

				for (j in 1...vertices.count) {

					var k:Int = j + 1;

					output += 'l ' + (indexVertex + j) + ' ' + (indexVertex + k) + '\n';

				}

			}

			// update index
			indexVertex += nbVertex;

		}

		function parsePoints(points:Dynamic) {

			var nbVertex:Int = 0;

			var geometry:Dynamic = points.geometry;

			var vertices:Dynamic = geometry.getAttribute('position');
			var colors:Dynamic = geometry.getAttribute('color');

			output += 'o ' + points.name + '\n';

			if (vertices !== null) {

				for (i in 0...vertices.count) {

					vertex.fromBufferAttribute(vertices, i);
					vertex.applyMatrix4(points.matrixWorld);

					output += 'v ' + vertex.x + ' ' + vertex.y + ' ' + vertex.z;

					if (colors !== null) {

						color.fromBufferAttribute(colors, i).convertLinearToSRGB();

						output += ' ' + color.r + ' ' + color.g + ' ' + color.b;

					}

					output += '\n';

					nbVertex++;

				}

				output += 'p ';

				for (j in 1...vertices.count) {

					output += (indexVertex + j) + ' ';

				}

				output += '\n';

			}

			// update index
			indexVertex += nbVertex;

		}

		object.traverse(function(child:Dynamic) {

			if (child.isMesh === true) {

				parseMesh(child);

			}

			if (child.isLine === true) {

				parseLine(child);

			}

			if (child.isPoints === true) {

				parsePoints(child);

			}

		});

		return output;

	}

}