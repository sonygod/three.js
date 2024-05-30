import h3d.BufferAttribute;
import h3d.BufferGeometry;
import h3d.EdgesGeometry;
import h3d.Vector3;

class QUnit {
    public static function module(name:String, cb:Void->Void):Void {}
    public function test(name:String, cb:Void->Void):Void {}
    public function todo(name:String, cb:Void->Void):Void {}
}

class THREE {
    public class OrbitControls {
        public function new(camera:Dynamic, domElement:Dynamic):Void {}
        public var target:Vector3;
    }
}

class WebGLRenderer {
    public function new(_options:Dynamic):Void {}
    public function setClearColor(color:Int):Void {}
    public function setSize(width:Int, height:Int):Void {}
}

class PerspectiveCamera {
    public function new(_fov:Dynamic, _aspect:Dynamic, _near:Dynamic, _far:Dynamic):Void {}
    public function lookAt(vector:Vector3):Void {}
    public var position:Vector3;
}

class Scene {
    public function new():Void {}
    public function add(obj:Dynamic):Void {}
}

class Mesh {
    public function new(geom:Dynamic, mat:Dynamic):Void {}
    public var position:Vector3;
}

class LineSegments {
    public function new(geom:Dynamic, mat:Dynamic):Void {}
    public var position:Vector3;
}

class LineBasicMaterial {
    public function new(params:Dynamic):Void {}
}

class Uint32Array {
    public function new(length:Int):Void {}
}

class Float32Array {
    public function new(length:Int):Void {}
}

class Document {
    public var body:Dynamic;
}

class Vector3 {
    public function new(x:Float, y:Float, z:Float):Void {}
    public static function $(x:Float, y:Float, z:Float):Vector3 {}
}

// DEBUGGING
var renderer:WebGLRenderer;
var camera:PerspectiveCamera;
var scene:Scene = new Scene();
var xoffset:Int = 0;

function output(geom:Dynamic, egeom:Dynamic) {
    if (!DEBUG) return;

    if (!renderer) initDebug();

    var mesh = new Mesh(geom, null);
    var edges = new LineSegments(egeom, new LineBasicMaterial({ color: 'black' }));

    mesh.position.x = xoffset;
    edges.position.x = xoffset++;
    scene.add(mesh);
    scene.add(edges);

    if (scene.children.length % 8 == 0) {
        xoffset += 2;
    }
}

function initDebug() {
    renderer = new WebGLRenderer({
        antialias: true
    });

    var width = 600;
    var height = 480;

    renderer.setSize(width, height);
    renderer.setClearColor(0xCCCCCC);

    camera = new PerspectiveCamera(45, width / height, 1, 100);
    camera.position.x = 30;
    camera.position.z = 40;
    camera.lookAt(new Vector3(30, 0, 0));

    Document.body.appendChild(renderer.domElement);

    var controls = new THREE.OrbitControls(camera, renderer.domElement);
    controls.target = new Vector3(30, 0, 0);

    animate();

    function animate() {
        requestAnimationFrame(animate);

        controls.update();

        renderer.render(scene, camera);
    }
}

function testEdges(vertList:Array<Vector3>, idxList:Array<Int>, numAfter:Int, assert:QUnit) {
    var geoms = createGeometries(vertList, idxList);

    for (i in 0...geoms.length) {
        var geom = geoms[i];

        var numBefore = idxList.length;
        assert.equal(countEdges(geom), numBefore, 'Edges before!');

        var egeom = new EdgesGeometry(geom);

        assert.equal(countEdges(egeom), numAfter, 'Edges after!');
        output(geom, egeom);
    }
}

function createGeometries(vertList:Array<Vector3>, idxList:Array<Int>):Array<BufferGeometry> {
    var geomIB = createIndexedBufferGeometry(vertList, idxList);
    var geomDC = addDrawCalls(geomIB.clone());
    return [geomIB, geomDC];
}

function createIndexedBufferGeometry(vertList:Array<Vector3>, idxList:Array<Int>):BufferGeometry {
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

function addDrawCalls(geometry:BufferGeometry):BufferGeometry {
    var numTris = geometry.index.count / 3;

    for (i in 0...numTris) {
        var start = i * 3;
        var count = 3;

        geometry.addGroup(start, count);
    }

    return geometry;
}

function countEdges(geom:Dynamic):Int {
    if (geom instanceof EdgesGeometry) {
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

// HELPERS
var DEBUG = false;

// Vector3
var _v = [
    new Vector3(0, 0, 0),
    new Vector3(1, 0, 0),
    new Vector3(1, 1, 0),
    new Vector3(0, 1, 0),
    new Vector3(1, 1, 1)
];

// QUnit module
export default function main() {
    QUnit.module('Geometries', function () {
        QUnit.module('EdgesGeometry', function () {
            // INHERITANCE
            QUnit.test('Extending', function (assert) {
                var object = new EdgesGeometry();
                assert.strictEqual(
                    object instanceof BufferGeometry,
                    true,
                    'EdgesGeometry extends from BufferGeometry'
                );
            });

            // INSTANCING
            QUnit.test('Instancing', function (assert) {
                var object = new EdgesGeometry();
                assert.ok(object, 'Can instantiate an EdgesGeometry.');
            });

            // PROPERTIES
            QUnit.test('type', function (assert) {
                var object = new EdgesGeometry();
                assert.ok(
                    object.type == 'EdgesGeometry',
                    'EdgesGeometry.type should be EdgesGeometry'
                );
            });

            QUnit.todo('parameters', function (assert) {
                assert.ok(false, 'everything\'s gonna be alright');
            });

            // OTHERS
            QUnit.test('singularity', function (assert) {
                testEdges(_v, [1, 1, 1], 0, assert);
            });

            QUnit.test('needle', function (assert) {
                testEdges(_v, [0, 0, 1], 0, assert);
            });

            QUnit.test('single triangle', function (assert) {
                testEdges(_v, [0, 1, 2], 3, assert);
            });

            QUnit.test('two isolated triangles', function (assert) {
                var vertList = [
                    new Vector3(0, 0, 0),
                    new Vector3(1, 0, 0),
                    new Vector3(1, 1, 0),
                    new Vector3(0, 0, 1),
                    new Vector3(1, 0, 1),
                    new Vector3(1, 1, 1)
                ];

                testEdges(vertList, [0, 1, 2, 3, 4, 5], 6, assert);
            });

            QUnit.test('two flat triangles', function (assert) {
                testEdges(_v, [0, 1, 2, 0, 2, 3], 4, assert);
            });

            QUnit.test('two flat triangles, inverted', function (assert) {
                testEdges(_v, [0, 1, 2, 0, 3, 2], 5, assert);
            });

            QUnit.test('two non-coplanar triangles', function (assert) {
                testEdges(_v, [0, 1, 2, 0, 4, 2], 5, assert);
            });

            QUnit.test('three triangles, coplanar first', function (assert) {
                testEdges(_v, [0, 2, 3, 0, 1, 2, 0, 4, 2], 7, assert);
            });

            QUnit.test('three triangles, coplanar last', function (assert) {
                testEdges(_v, [0, 1, 2, 0, 4, 2, 0, 2, 3], 6, assert); // Should be 7
            });

            QUnit.test('tetrahedron', function (assert) {
                testEdges(_v, [0, 1, 2, 0, 1, 4, 0, 4, 2, 1, 2, 4], 6, assert);
            });
        });
    });
}