import haxe.unit.TestCase;

import three.geo.EdgesGeometry;
import three.core.BufferGeometry;
import three.core.BufferAttribute;
import three.math.Vector3;

class TestEdgesGeometry extends TestCase {
    override public function new() {
        super();

        QUnit.module("Geometries", () => {
            QUnit.module("EdgesGeometry", () => {
                var vertList:Array<Vector3> = [
                    new Vector3(0, 0, 0),
                    new Vector3(1, 0, 0),
                    new Vector3(1, 1, 0),
                    new Vector3(0, 1, 0),
                    new Vector3(1, 1, 1)
                ];

                // INHERITANCE
                QUnit.test("Extending", (assert) => {
                    var object:EdgesGeometry = new EdgesGeometry();
                    assert.ok(object instanceof BufferGeometry, 'EdgesGeometry extends from BufferGeometry');
                });

                // INSTANCING
                QUnit.test("Instancing", (assert) => {
                    var object:EdgesGeometry = new EdgesGeometry();
                    assert.ok(object != null, 'Can instantiate an EdgesGeometry.');
                });

                // PROPERTIES
                QUnit.test("type", (assert) => {
                    var object:EdgesGeometry = new EdgesGeometry();
                    assert.ok(object.type == "EdgesGeometry", 'EdgesGeometry.type should be EdgesGeometry');
                });

                QUnit.todo("parameters", (assert) => {
                    assert.ok(false, "everything's gonna be alright");
                });

                // OTHERS
                QUnit.test("singularity", (assert) => {
                    testEdges(vertList, [1, 1, 1], 0, assert);
                });

                QUnit.test("needle", (assert) => {
                    testEdges(vertList, [0, 0, 1], 0, assert);
                });

                QUnit.test("single triangle", (assert) => {
                    testEdges(vertList, [0, 1, 2], 3, assert);
                });

                QUnit.test("two isolated triangles", (assert) => {
                    var vertList:Array<Vector3> = [
                        new Vector3(0, 0, 0),
                        new Vector3(1, 0, 0),
                        new Vector3(1, 1, 0),
                        new Vector3(0, 0, 1),
                        new Vector3(1, 0, 1),
                        new Vector3(1, 1, 1)
                    ];
                    testEdges(vertList, [0, 1, 2, 3, 4, 5], 6, assert);
                });

                QUnit.test("two flat triangles", (assert) => {
                    testEdges(vertList, [0, 1, 2, 0, 2, 3], 4, assert);
                });

                QUnit.test("two flat triangles, inverted", (assert) => {
                    testEdges(vertList, [0, 1, 2, 0, 3, 2], 5, assert);
                });

                QUnit.test("two non-coplanar triangles", (assert) => {
                    testEdges(vertList, [0, 1, 2, 0, 4, 2], 5, assert);
                });

                QUnit.test("three triangles, coplanar first", (assert) => {
                    testEdges(vertList, [0, 2, 3, 0, 1, 2, 0, 4, 2], 7, assert);
                });

                QUnit.test("three triangles, coplanar last", (assert) => {
                    testEdges(vertList, [0, 1, 2, 0, 4, 2, 0, 2, 3], 6, assert); // Should be 7
                });

                QUnit.test("tetrahedron", (assert) => {
                    testEdges(vertList, [0, 1, 2, 0, 1, 4, 0, 4, 2, 1, 2, 4], 6, assert);
                });
            });
        });
    }

    function createGeometries(vertList:Array<Vector3>, idxList:Array<Int>):Array<BufferGeometry> {
        var geomIB:BufferGeometry = createIndexedBufferGeometry(vertList, idxList);
        var geomDC:BufferGeometry = addDrawCalls(geomIB.clone());
        return [geomIB, geomDC];
    }

    function createIndexedBufferGeometry(vertList:Array<Vector3>, idxList:Array<Int>):BufferGeometry {
        var geom:BufferGeometry = new BufferGeometry();

        var indexTable:Array<Int> = [];
        var numTris:Int = idxList.length / 3;
        var numVerts:Int = 0;

        var indices:Uint32Array = new Uint32Array(numTris * 3);
        var vertices:Float32Array = new Float32Array(vertList.length * 3);

        for (i in 0...numTris) {
            for (j in 0...3) {
                var idx:Int = idxList[3 * i + j];
                if (indexTable[idx] == null) {
                    var v:Vector3 = vertList[idx];
                    vertices[3 * numVerts] = v.x;
                    vertices[3 * numVerts + 1] = v.y;
                    vertices[3 * numVerts + 2] = v.z;

                    indexTable[idx] = numVerts++;

                }

                indices[3 * i + j] = indexTable[idx];
            }
        }

        vertices = vertices.subarray(0, 3 * numVerts);

        geom.setIndex(new BufferAttribute(new Uint32Array(indices), 1));
        geom.setAttribute('position', new BufferAttribute(vertices, 3));

        return geom;
    }

    function addDrawCalls(geometry:BufferGeometry):BufferGeometry {
        var numTris:Int = geometry.index.count / 3;

        for (i in 0...numTris) {
            var start:Int = i * 3;
            var count:Int = 3;

            geometry.addGroup(start, count);
        }

        return geometry;
    }

    function countEdges(geom:BufferGeometry):Int {
        if (Std.is(geom, EdgesGeometry)) {
            return geom.getAttribute('position').count / 2;
        }

        if (geom.faces != null) {
            return geom.faces.length * 3;
        }

        var indices:BufferAttribute = geom.index;
        if (indices != null) {
            return indices.count;
        }

        return geom.getAttribute('position').count;
    }

    function testEdges(vertList:Array<Vector3>, idxList:Array<Int>, numAfter:Int, assert:TestCase) {
        var geoms:Array<BufferGeometry> = createGeometries(vertList, idxList);

        for (geom in geoms) {
            var numBefore:Int = idxList.length;
            assert.ok(countEdges(geom) == numBefore, 'Edges before!');

            var egeom:EdgesGeometry = new EdgesGeometry(geom);

            assert.ok(countEdges(egeom) == numAfter, 'Edges after!');
            output(geom, egeom);
        }
    }

    function output(geom:BufferGeometry, egeom:EdgesGeometry) {
        if (!DEBUG) return;

        if (renderer == null) initDebug();

        var mesh:Mesh = new Mesh(geom, null);
        var edges:LineSegments = new LineSegments(egeom, new LineBasicMaterial({color: 'black'}));

        mesh.position.x = xoffset;
        edges.position.x = xoffset++;
        scene.add(mesh);
        scene.add(edges);

        if (scene.children.length % 8 == 0) {
            xoffset += 2;
        }
    }

    var DEBUG:Bool = false;
    var renderer:WebGLRenderer;
    var camera:PerspectiveCamera;
    var scene:Scene;
    var xoffset:Int = 0;

    function initDebug() {
        renderer = new WebGLRenderer({antialias: true});
        var width:Int = 600;
        var height:Int = 480;

        renderer.setSize(width, height);
        renderer.setClearColor(0xCCCCCC);

        camera = new PerspectiveCamera(45, width / height, 1, 100);
        camera.position.x = 30;
        camera.position.z = 40;
        camera.lookAt(new Vector3(30, 0, 0));

        document.body.appendChild(renderer.domElement);

        var controls:OrbitControls = new OrbitControls(camera, renderer.domElement);
        controls.target = new Vector3(30, 0, 0);

        animate();

        function animate() {
            requestAnimationFrame(animate);

            controls.update();
            renderer.render(scene, camera);
        }
    }
}