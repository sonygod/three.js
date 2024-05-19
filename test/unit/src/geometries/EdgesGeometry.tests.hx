package three.js.test.unit.src.geometries;

import three.js.geometries.EdgesGeometry;
import three.js.core.BufferGeometry;
import three.js.core.BufferAttribute;
import three.js.math.Vector3;

// DEBUGGING
import three.js.scenes.Scene;
import three.js.objects.Mesh;
import three.js.objects.LineSegments;
import three.js.materials.LineBasicMaterial;
import three.js.renderers.WebGLRenderer;
import three.js.cameras.PerspectiveCamera;

class EdgesGeometryTests {
	//
	// HELPERS
	//

	static function testEdges(vertList:Array<Vector3>, idxList:Array<Int>, numAfter:Int, assert:Dynamic) {
		var geoms:Array<BufferGeometry> = createGeometries(vertList, idxList);

		for (i in 0...geoms.length) {
			var geom = geoms[i];
			var numBefore = idxList.length;
			assert.equal(countEdges(geom), numBefore, 'Edges before!');
			var egeom = new EdgesGeometry(geom);
			assert.equal(countEdges(egeom), numAfter, 'Edges after!');
			output(geom, egeom);
		}
	}

	static function createGeometries(vertList:Array<Vector3>, idxList:Array<Int>) {
		var geomIB = createIndexedBufferGeometry(vertList, idxList);
		var geomDC = addDrawCalls(geomIB.clone());
		return [geomIB, geomDC];
	}

	static function createIndexedBufferGeometry(vertList:Array<Vector3>, idxList:Array<Int>) {
		var geom = new BufferGeometry();
		var indexTable = [];
		var numTris = idxList.length / 3;
		var numVerts = 0;

		var indices = new Uint32Array(numTris * 3);
		var vertices = new Float32Array(vertList.length * 3);

		for (i in 0...numTris) {
			for (j in 0...3) {
				var idx = idxList[3 * i + j];
				if (indexTable[idx] == null) {
					var v = vertList[idx];
					vertices[3 * numVerts] = v.x;
					vertices[3 * numVerts + 1] = v.y;
					vertices[3 * numVerts + 2] = v.z;
					indexTable[idx] = numVerts;
					numVerts++;
				}
				indices[3 * i + j] = indexTable[idx];
			}
		}

		vertices = vertices.subarray(0, 3 * numVerts);

		geom.setIndex(new BufferAttribute(indices, 1));
		geom.setAttribute('position', new BufferAttribute(vertices, 3));
		return geom;
	}

	static function addDrawCalls(geometry:BufferGeometry) {
		var numTris = geometry.index.count / 3;

		for (i in 0...numTris) {
			var start = i * 3;
			var count = 3;
			geometry.addGroup(start, count);
		}

		return geometry;
	}

	static function countEdges(geom:BufferGeometry) {
		if (Std.is(geom, EdgesGeometry)) {
			return geom.getAttribute('position').count / 2;
		}

		if (geom.faces != null) {
			return geom.faces.length * 3;
		}

		var indices = geom.index;
		if (indices != null) {
			return indices.count;
		}

		return geom.getAttribute('position').count;
	}

	//
	// DEBUGGING
	//

	static var DEBUG = false;
	static var renderer:WebGLRenderer;
	static var camera:PerspectiveCamera;
	static var scene = new Scene();
	static var xoffset = 0;

	static function output(geom:BufferGeometry, egeom:EdgesGeometry) {
		if (!DEBUG) return;

		if (renderer == null) initDebug();

		var mesh = new Mesh(geom);
		var edges = new LineSegments(egeom, new LineBasicMaterial({ color: 'black' }));

		mesh.position.x = xoffset;
		edges.position.x = xoffset++;
		scene.add(mesh);
		scene.add(edges);

		if (scene.children.length % 8 == 0) {
			xoffset += 2;
		}
	}

	static function initDebug() {
		renderer = new WebGLRenderer({ antialias: true });
		var width = 600;
		var height = 480;

		renderer.setSize(width, height);
		renderer.setClearColor(0xCCCCCC);

		camera = new PerspectiveCamera(45, width / height, 1, 100);
		camera.position.x = 30;
		camera.position.z = 40;
		camera.lookAt(new Vector3(30, 0, 0));

		js.Lib.document.body.appendChild(renderer.domElement);

		var controls = new THREE.OrbitControls(camera, renderer.domElement); // TODO: please do something for that -_-'
		controls.target = new Vector3(30, 0, 0);

		animate();

		function animate() {
			js.Lib.requestAnimationFrame(animate);

			controls.update();
			renderer.render(scene, camera);
		}
	}

	public static function main() {
		QUnit.module('Geometries', () => {
			QUnit.module('EdgesGeometry', () => {
				var vertList = [
					new Vector3(0, 0, 0),
					new Vector3(1, 0, 0),
					new Vector3(1, 1, 0),
					new Vector3(0, 1, 0),
					new Vector3(1, 1, 1),
				];

				// INHERITANCE
				QUnit.test('Extending', (assert) => {
					var object = new EdgesGeometry();
					assert.ok(object instanceof BufferGeometry, 'EdgesGeometry extends from BufferGeometry');
				});

				// INSTANCING
				QUnit.test('Instancing', (assert) => {
					var object = new EdgesGeometry();
					assert.ok(object, 'Can instantiate an EdgesGeometry.');
				});

				// PROPERTIES
				QUnit.test('type', (assert) => {
					var object = new EdgesGeometry();
					assert.ok(object.type == 'EdgesGeometry', 'EdgesGeometry.type should be EdgesGeometry');
				});

				QUnit.todo('parameters', (assert) => {
					assert.ok(false, 'everything\'s gonna be alright');
				});

				// OTHERS
				QUnit.test('singularity', (assert) => {
					testEdges(vertList, [1, 1, 1], 0, assert);
				});

				QUnit.test('needle', (assert) => {
					testEdges(vertList, [0, 0, 1], 0, assert);
				});

				QUnit.test('single triangle', (assert) => {
					testEdges(vertList, [0, 1, 2], 3, assert);
				});

				QUnit.test('two isolated triangles', (assert) => {
					var vertList = [
						new Vector3(0, 0, 0),
						new Vector3(1, 0, 0),
						new Vector3(1, 1, 0),
						new Vector3(0, 0, 1),
						new Vector3(1, 0, 1),
						new Vector3(1, 1, 1),
					];

					testEdges(vertList, [0, 1, 2, 3, 4, 5], 6, assert);
				});

				QUnit.test('two flat triangles', (assert) => {
					testEdges(vertList, [0, 1, 2, 0, 2, 3], 4, assert);
				});

				QUnit.test('two flat triangles, inverted', (assert) => {
					testEdges(vertList, [0, 1, 2, 0, 3, 2], 5, assert);
				});

				QUnit.test('two non-coplanar triangles', (assert) => {
					testEdges(vertList, [0, 1, 2, 0, 4, 2], 5, assert);
				});

				QUnit.test('three triangles, coplanar first', (assert) => {
					testEdges(vertList, [0, 2, 3, 0, 1, 2, 0, 4, 2], 7, assert);
				});

				QUnit.test('three triangles, coplanar last', (assert) => {
					testEdges(vertList, [0, 1, 2, 0, 4, 2, 0, 2, 3], 6, assert); // Should be 7
				});

				QUnit.test('tetrahedron', (assert) => {
					testEdges(vertList, [0, 1, 2, 0, 1, 4, 0, 4, 2, 1, 2, 4], 6, assert);
				});
			});
		});
	}
}