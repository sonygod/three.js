import three.math.Matrix3;
import three.math.Vector3;
import three.core.Object3D;
import three.core.Mesh;
import three.core.Points;
import three.geometries.BufferGeometry;
import three.materials.Material;
import three.math.Color;

/**
 * https://github.com/gkjohnson/ply-exporter-js
 *
 * Usage:
 *  const exporter = new PLYExporter();
 *
 *  // second argument is a list of options
 *  exporter.parse(mesh, data => console.log(data), { binary: true, excludeAttributes: [ 'color' ], littleEndian: true });
 *
 * Format Definition:
 * http://paulbourke.net/dataformats/ply/
 */
class PLYExporter {

	public function new() {}

	public function parse( object:Object3D, onDone:Dynamic->Void, options:Dynamic = null ):Dynamic {

		// Iterate over the valid meshes in the object
		function traverseMeshes( cb:Mesh->BufferGeometry->Void ):Void {
			object.traverse(function( child ) {
				if (cast child : Mesh) {
					cb(child, child.geometry);
				} else if (cast child : Points) {
					cb(child, child.geometry);
				}
			});
		}

		// Default options
		var defaultOptions = {
			binary: false,
			excludeAttributes: [], // normal, uv, color, index
			littleEndian: false
		};

		options = options != null ? options : defaultOptions;

		var excludeAttributes = options.excludeAttributes;
		var includeIndices = true;
		var includeNormals = false;
		var includeColors = false;
		var includeUVs = false;

		// count the vertices, check which properties are used,
		// and cache the BufferGeometry
		var vertexCount = 0;
		var faceCount = 0;

		object.traverse(function( child ) {
			if (cast child : Mesh) {
				var mesh = child;
				var geometry = mesh.geometry;
				var vertices = geometry.getAttribute( 'position' );
				var normals = geometry.getAttribute( 'normal' );
				var uvs = geometry.getAttribute( 'uv' );
				var colors = geometry.getAttribute( 'color' );
				var indices = geometry.getIndex();

				if (vertices == null) {
					return;
				}

				vertexCount += vertices.count;
				faceCount += indices != null ? indices.count / 3 : vertices.count / 3;

				if (normals != null) includeNormals = true;
				if (uvs != null) includeUVs = true;
				if (colors != null) includeColors = true;

			} else if (cast child : Points) {
				var mesh = child;
				var geometry = mesh.geometry;
				var vertices = geometry.getAttribute( 'position' );
				var normals = geometry.getAttribute( 'normal' );
				var colors = geometry.getAttribute( 'color' );

				vertexCount += vertices.count;

				if (normals != null) includeNormals = true;
				if (colors != null) includeColors = true;

				includeIndices = false;
			}
		});

		var tempColor = new Color();
		includeIndices = includeIndices && excludeAttributes.indexOf( 'index' ) == -1;
		includeNormals = includeNormals && excludeAttributes.indexOf( 'normal' ) == -1;
		includeColors = includeColors && excludeAttributes.indexOf( 'color' ) == -1;
		includeUVs = includeUVs && excludeAttributes.indexOf( 'uv' ) == -1;


		if (includeIndices && faceCount != Math.floor(faceCount)) {
			// point cloud meshes will not have an index array and may not have a
			// number of vertices that is divisble by 3 (and therefore representable
			// as triangles)
			console.error(
				'PLYExporter: Failed to generate a valid PLY file with triangle indices because the ' +
				'number of indices is not divisible by 3.'
			);

			return null;
		}

		var indexByteCount = 4;

		var header =
			'ply\n' +
			`format ${ options.binary ? ( options.littleEndian ? 'binary_little_endian' : 'binary_big_endian' ) : 'ascii' } 1.0\n` +
			`element vertex ${vertexCount}\n` +

			// position
			'property float x\n' +
			'property float y\n' +
			'property float z\n';

		if (includeNormals) {
			// normal
			header +=
				'property float nx\n' +
				'property float ny\n' +
				'property float nz\n';
		}

		if (includeUVs) {
			// uvs
			header +=
				'property float s\n' +
				'property float t\n';
		}

		if (includeColors) {
			// colors
			header +=
				'property uchar red\n' +
				'property uchar green\n' +
				'property uchar blue\n';
		}

		if (includeIndices) {
			// faces
			header +=
				`element face ${faceCount}\n` +
				'property list uchar int vertex_index\n';
		}

		header += 'end_header\n';


		// Generate attribute data
		var vertex = new Vector3();
		var normalMatrixWorld = new Matrix3();
		var result = null;

		if (options.binary) {
			// Binary File Generation
			var headerBin = haxe.io.Bytes.ofString(header);

			// 3 position values at 4 bytes
			// 3 normal values at 4 bytes
			// 3 color channels with 1 byte
			// 2 uv values at 4 bytes
			var vertexListLength = vertexCount * ( 4 * 3 + ( includeNormals ? 4 * 3 : 0 ) + ( includeColors ? 3 : 0 ) + ( includeUVs ? 4 * 2 : 0 ) );

			// 1 byte shape desciptor
			// 3 vertex indices at ${indexByteCount} bytes
			var faceListLength = includeIndices ? faceCount * ( indexByteCount * 3 + 1 ) : 0;
			var output = new haxe.io.BytesBuffer(headerBin.length + vertexListLength + faceListLength);
			output.addBytes(headerBin);

			var vOffset = headerBin.length;
			var fOffset = headerBin.length + vertexListLength;
			var writtenVertices = 0;
			traverseMeshes(function( mesh:Mesh, geometry:BufferGeometry ) {
				var vertices = geometry.getAttribute( 'position' );
				var normals = geometry.getAttribute( 'normal' );
				var uvs = geometry.getAttribute( 'uv' );
				var colors = geometry.getAttribute( 'color' );
				var indices = geometry.getIndex();

				normalMatrixWorld.getNormalMatrix(mesh.matrixWorld);

				for (var i = 0; i < vertices.count; i++) {
					vertex.fromBufferAttribute(vertices, i);
					vertex.applyMatrix4(mesh.matrixWorld);

					// Position information
					output.setFloat(vOffset, vertex.x);
					vOffset += 4;

					output.setFloat(vOffset, vertex.y);
					vOffset += 4;

					output.setFloat(vOffset, vertex.z);
					vOffset += 4;

					// Normal information
					if (includeNormals) {
						if (normals != null) {
							vertex.fromBufferAttribute(normals, i);
							vertex.applyMatrix3(normalMatrixWorld).normalize();

							output.setFloat(vOffset, vertex.x);
							vOffset += 4;

							output.setFloat(vOffset, vertex.y);
							vOffset += 4;

							output.setFloat(vOffset, vertex.z);
							vOffset += 4;
						} else {
							output.setFloat(vOffset, 0);
							vOffset += 4;

							output.setFloat(vOffset, 0);
							vOffset += 4;

							output.setFloat(vOffset, 0);
							vOffset += 4;
						}
					}

					// UV information
					if (includeUVs) {
						if (uvs != null) {
							output.setFloat(vOffset, uvs.getX(i));
							vOffset += 4;

							output.setFloat(vOffset, uvs.getY(i));
							vOffset += 4;
						} else {
							output.setFloat(vOffset, 0);
							vOffset += 4;

							output.setFloat(vOffset, 0);
							vOffset += 4;
						}
					}

					// Color information
					if (includeColors) {
						if (colors != null) {
							tempColor.fromBufferAttribute(colors, i).convertLinearToSRGB();

							output.setByte(vOffset, Math.floor(tempColor.r * 255));
							vOffset += 1;

							output.setByte(vOffset, Math.floor(tempColor.g * 255));
							vOffset += 1;

							output.setByte(vOffset, Math.floor(tempColor.b * 255));
							vOffset += 1;
						} else {
							output.setByte(vOffset, 255);
							vOffset += 1;

							output.setByte(vOffset, 255);
							vOffset += 1;

							output.setByte(vOffset, 255);
							vOffset += 1;
						}
					}
				}

				if (includeIndices) {
					// Create the face list
					if (indices != null) {
						for (var i = 0; i < indices.count; i += 3) {
							output.setByte(fOffset, 3);
							fOffset += 1;

							output.setInt(fOffset, indices.getX(i + 0) + writtenVertices);
							fOffset += indexByteCount;

							output.setInt(fOffset, indices.getX(i + 1) + writtenVertices);
							fOffset += indexByteCount;

							output.setInt(fOffset, indices.getX(i + 2) + writtenVertices);
							fOffset += indexByteCount;
						}
					} else {
						for (var i = 0; i < vertices.count; i += 3) {
							output.setByte(fOffset, 3);
							fOffset += 1;

							output.setInt(fOffset, writtenVertices + i);
							fOffset += indexByteCount;

							output.setInt(fOffset, writtenVertices + i + 1);
							fOffset += indexByteCount;

							output.setInt(fOffset, writtenVertices + i + 2);
							fOffset += indexByteCount;
						}
					}
				}

				// Save the amount of verts we've already written so we can offset
				// the face index on the next mesh
				writtenVertices += vertices.count;
			});

			result = output.getBytes();
		} else {
			// Ascii File Generation
			// count the number of vertices
			var writtenVertices = 0;
			var vertexList = '';
			var faceList = '';

			traverseMeshes(function( mesh:Mesh, geometry:BufferGeometry ) {
				var vertices = geometry.getAttribute( 'position' );
				var normals = geometry.getAttribute( 'normal' );
				var uvs = geometry.getAttribute( 'uv' );
				var colors = geometry.getAttribute( 'color' );
				var indices = geometry.getIndex();

				normalMatrixWorld.getNormalMatrix(mesh.matrixWorld);

				// form each line
				for (var i = 0; i < vertices.count; i++) {
					vertex.fromBufferAttribute(vertices, i);
					vertex.applyMatrix4(mesh.matrixWorld);

					// Position information
					var line =
						vertex.x + ' ' +
						vertex.y + ' ' +
						vertex.z;

					// Normal information
					if (includeNormals) {
						if (normals != null) {
							vertex.fromBufferAttribute(normals, i);
							vertex.applyMatrix3(normalMatrixWorld).normalize();

							line += ' ' +
								vertex.x + ' ' +
								vertex.y + ' ' +
								vertex.z;
						} else {
							line += ' 0 0 0';
						}
					}

					// UV information
					if (includeUVs) {
						if (uvs != null) {
							line += ' ' +
								uvs.getX(i) + ' ' +
								uvs.getY(i);
						} else {
							line += ' 0 0';
						}
					}

					// Color information
					if (includeColors) {
						if (colors != null) {
							tempColor.fromBufferAttribute(colors, i).convertLinearToSRGB();

							line += ' ' +
								Math.floor(tempColor.r * 255) + ' ' +
								Math.floor(tempColor.g * 255) + ' ' +
								Math.floor(tempColor.b * 255);
						} else {
							line += ' 255 255 255';
						}
					}

					vertexList += line + '\n';
				}

				// Create the face list
				if (includeIndices) {
					if (indices != null) {
						for (var i = 0; i < indices.count; i += 3) {
							faceList += `3 ${ indices.getX(i + 0) + writtenVertices }`;
							faceList += ` ${ indices.getX(i + 1) + writtenVertices }`;
							faceList += ` ${ indices.getX(i + 2) + writtenVertices }\n`;
						}
					} else {
						for (var i = 0; i < vertices.count; i += 3) {
							faceList += `3 ${ writtenVertices + i } ${ writtenVertices + i + 1 } ${ writtenVertices + i + 2 }\n`;
						}
					}

					faceCount += indices != null ? indices.count / 3 : vertices.count / 3;
				}

				writtenVertices += vertices.count;
			});

			result = `${ header }${vertexList}${ includeIndices ? `${faceList}\n` : '\n' }`;
		}

		if (onDone != null) {
			window.requestAnimationFrame(function() { onDone(result); });
		}

		return result;
	}
}