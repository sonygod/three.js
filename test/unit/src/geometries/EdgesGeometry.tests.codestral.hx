import three.geometries.EdgesGeometry;
import three.core.BufferGeometry;
import three.core.BufferAttribute;
import three.math.Vector3;

class EdgesGeometryTests {
    static function testEdges(vertList:Array<Vector3>, idxList:Array<Int>, numAfter:Int, assert:QUnit.Assert):Void {
        var geoms:Array<BufferGeometry> = createGeometries(vertList, idxList);

        for (geom in geoms) {
            var numBefore:Int = idxList.length;
            assert.equal(countEdges(geom), numBefore, 'Edges before!');

            var egeom:EdgesGeometry = new EdgesGeometry(geom);

            assert.equal(countEdges(egeom), numAfter, 'Edges after!');
        }
    }

    static function createGeometries(vertList:Array<Vector3>, idxList:Array<Int>):Array<BufferGeometry> {
        var geomIB:BufferGeometry = createIndexedBufferGeometry(vertList, idxList);
        var geomDC:BufferGeometry = addDrawCalls(geomIB.clone());
        return [geomIB, geomDC];
    }

    static function createIndexedBufferGeometry(vertList:Array<Vector3>, idxList:Array<Int>):BufferGeometry {
        var geom:BufferGeometry = new BufferGeometry();

        var indexTable:Array<Int> = [];
        var numTris:Int = idxList.length / 3;
        var numVerts:Int = 0;

        var indices:Array<Int> = new Array<Int>(numTris * 3);
        var vertices:Array<Float> = new Array<Float>(vertList.length * 3);

        for (i in 0...numTris) {
            for (j in 0...3) {
                var idx:Int = idxList[3 * i + j];
                if (indexTable[idx] == null) {
                    var v:Vector3 = vertList[idx];
                    vertices[3 * numVerts] = v.x;
                    vertices[3 * numVerts + 1] = v.y;
                    vertices[3 * numVerts + 2] = v.z;

                    indexTable[idx] = numVerts;

                    numVerts++;
                }

                indices[3 * i + j] = indexTable[idx];
            }
        }

        vertices = vertices.slice(0, 3 * numVerts);

        geom.setIndex(new BufferAttribute(indices, 1));
        geom.setAttribute('position', new BufferAttribute(vertices, 3));

        return geom;
    }

    static function addDrawCalls(geometry:BufferGeometry):BufferGeometry {
        var numTris:Int = geometry.index.count / 3;

        for (i in 0...numTris) {
            var start:Int = i * 3;
            var count:Int = 3;

            geometry.addGroup(start, count);
        }

        return geometry;
    }

    static function countEdges(geom:BufferGeometry):Int {
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
}