package three.test.unit.src.geometries;

import three.src.geometries.EdgesGeometry;
import three.src.core.BufferGeometry;
import three.src.core.BufferAttribute;
import three.src.math.Vector3;
import three.src.scenes.Scene;
import three.src.objects.Mesh;
import three.src.objects.LineSegments;
import three.src.materials.LineBasicMaterial;
import three.src.renderers.WebGLRenderer;
import three.src.cameras.PerspectiveCamera;
import js.Lib;

class EdgesGeometryTests {
    static function testEdges(vertList:Array<Vector3>, idxList:Array<Int>, numAfter:Int, assert:QUnitAssert) {
        var geoms = createGeometries(vertList, idxList);
        for (i in geoms) {
            var geom = geoms[i];
            var numBefore = idxList.length;
            assert.equal(countEdges(geom), numBefore, 'Edges before!');
            var egeom = new EdgesGeometry(geom);
            assert.equal(countEdges(egeom), numAfter, 'Edges after!');
            output(geom, egeom);
        }
    }

    static function createGeometries(vertList:Array<Vector3>, idxList:Array<Int>):Array<BufferGeometry> {
        var geomIB = createIndexedBufferGeometry(vertList, idxList);
        var geomDC = addDrawCalls(geomIB.clone());
        return [geomIB, geomDC];
    }

    static function createIndexedBufferGeometry(vertList:Array<Vector3>, idxList:Array<Int>):BufferGeometry {
        // ... 省略实现细节 ...
    }

    static function addDrawCalls(geometry:BufferGeometry):BufferGeometry {
        // ... 省略实现细节 ...
    }

    static function countEdges(geom:BufferGeometry):Int {
        // ... 省略实现细节 ...
    }

    static var DEBUG:Bool = false;
    static var renderer:WebGLRenderer;
    static var camera:PerspectiveCamera;
    static var scene:Scene = new Scene();
    static var xoffset:Int = 0;

    static function output(geom:BufferGeometry, egeom:EdgesGeometry) {
        if (DEBUG !== true) return;
        if (!renderer) initDebug();
        var mesh = new Mesh(geom, null);
        var edges = new LineSegments(egeom, new LineBasicMaterial({color: 'black'}));
        mesh.position.setX(xoffset);
        edges.position.setX(xoffset++);
        scene.add(mesh);
        scene.add(edges);
        if (scene.children.length % 8 === 0) {
            xoffset += 2;
        }
    }

    static function initDebug() {
        // ... 省略实现细节 ...
    }

    static function main() {
        QUnit.module('Geometries', () -> {
            QUnit.module('EdgesGeometry', () -> {
                var vertList = [
                    new Vector3(0, 0, 0),
                    new Vector3(1, 0, 0),
                    new Vector3(1, 1, 0),
                    new Vector3(0, 1, 0),
                    new Vector3(1, 1, 1),
                ];
                // ... 省略其他测试 ...
            });
        });
    }
}

class QUnit {
    public static inline function module(name:String, callback:Void->Void) {
        Lib.run(callback);
    }

    public static inline function test(name:String, callback:QUnitAssert->Void) {
        Lib.run(callback);
    }

    public static inline function todo(name:String, callback:QUnitAssert->Void) {
        Lib.run(callback);
    }
}

class QUnitAssert {
    public inline function equal(actual:Dynamic, expected:Dynamic, message:String) {
        if (actual != expected) {
            throw message;
        }
    }

    public inline function ok(condition:Bool, message:String) {
        if (!condition) {
            throw message;
        }
    }
}