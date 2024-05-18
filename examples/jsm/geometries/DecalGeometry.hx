Here is the converted Haxe code:
```
package three.js.examples.jsm.geometries;

import three.js.BufferGeometry;
import three.js.Float32BufferAttribute;
import three.js.Matrix4;
import three.js.Vector3;

/**
 * You can use this geometry to create a decal mesh, that serves different kinds of purposes.
 * e.g. adding unique details to models, performing dynamic visual environmental changes or covering seams.
 *
 * Constructor parameter:
 *
 * mesh — Any mesh object
 * position — Position of the decal projector
 * orientation — Orientation of the decal projector
 * size — Size of the decal projector
 *
 * reference: http://blog.wolfire.com/2009/06/how-to-project-decals/
 */

class DecalGeometry extends BufferGeometry {

    public function new(mesh:Mesh, position:Vector3, orientation:Vector3, size:Vector3) {
        super();

        // buffers

        var vertices:Array<Float> = [];
        var normals:Array<Float> = [];
        var uvs:Array<Float> = [];

        // helpers

        var plane:Vector3 = new Vector3();

        // this matrix represents the transformation of the decal projector

        var projectorMatrix:Matrix4 = new Matrix4();
        projectorMatrix.makeRotationFromEuler(orientation);
        projectorMatrix.setPosition(position);

        var projectorMatrixInverse:Matrix4 = new Matrix4();
        projectorMatrixInverse.copy(projectorMatrix).invert();

        // generate buffers

        generate();

        // build geometry

        this.setAttribute('position', new Float32BufferAttribute(vertices, 3));
        this.setAttribute('normal', new Float32BufferAttribute(normals, 3));
        this.setAttribute('uv', new Float32BufferAttribute(uvs, 2));
    }

    function generate() {

        var decalVertices:Array<DecalVertex> = [];

        var vertex:Vector3 = new Vector3();
        var normal:Vector3 = new Vector3();

        // handle different geometry types

        var geometry:BufferGeometry = mesh.geometry;

        var positionAttribute:Float32BufferAttribute = geometry.getAttribute('position');
        var normalAttribute:Float32BufferAttribute = geometry.getAttribute('normal');

        // first, create an array of 'DecalVertex' objects
        // three consecutive 'DecalVertex' objects represent a single face
        //
        // this data structure will be later used to perform the clipping

        if (geometry.index != null) {

            // indexed BufferGeometry

            var index:Array<Int> = geometry.index.array;

            for (i in 0...index.length) {
                vertex.fromBufferAttribute(positionAttribute, index[i]);
                normal.fromBufferAttribute(normalAttribute, index[i]);

                pushDecalVertex(decalVertices, vertex, normal);
            }

        } else {

            // non-indexed BufferGeometry

            for (i in 0...positionAttribute.count) {
                vertex.fromBufferAttribute(positionAttribute, i);
                normal.fromBufferAttribute(normalAttribute, i);

                pushDecalVertex(decalVertices, vertex, normal);
            }
        }

        // second, clip the geometry so that it doesn't extend out from the projector

        decalVertices = clipGeometry(decalVertices, plane.set(1, 0, 0));
        decalVertices = clipGeometry(decalVertices, plane.set(-1, 0, 0));
        decalVertices = clipGeometry(decalVertices, plane.set(0, 1, 0));
        decalVertices = clipGeometry(decalVertices, plane.set(0, -1, 0));
        decalVertices = clipGeometry(decalVertices, plane.set(0, 0, 1));
        decalVertices = clipGeometry(decalVertices, plane.set(0, 0, -1));

        // third, generate final vertices, normals and uvs

        for (i in 0...decalVertices.length) {
            var decalVertex:DecalVertex = decalVertices[i];

            // create texture coordinates (we are still in projector space)

            uvs.push(
                0.5 + (decalVertex.position.x / size.x),
                0.5 + (decalVertex.position.y / size.y)
            );

            // transform the vertex back to world space

            decalVertex.position.applyMatrix4(projectorMatrix);

            // now create vertex and normal buffer data

            vertices.push(decalVertex.position.x, decalVertex.position.y, decalVertex.position.z);
            normals.push(decalVertex.normal.x, decalVertex.normal.y, decalVertex.normal.z);
        }
    }

    function pushDecalVertex(decalVertices:Array<DecalVertex>, vertex:Vector3, normal:Vector3) {
        // transform the vertex to world space, then to projector space

        vertex.applyMatrix4(mesh.matrixWorld);
        vertex.applyMatrix4(projectorMatrixInverse);

        normal.transformDirection(mesh.matrixWorld);

        decalVertices.push(new DecalVertex(vertex.clone(), normal.clone()));
    }

    function clipGeometry(inVertices:Array<DecalVertex>, plane:Vector3) {
        var outVertices:Array<DecalVertex> = [];

        var s:Float = 0.5 * Math.abs(size.dot(plane));

        // a single iteration clips one face,
        // which consists of three consecutive 'DecalVertex' objects

        for (i in 0...inVertices.length) {
            var total:Int = 0;
            var nV1:DecalVertex;
            var nV2:DecalVertex;
            var nV3:DecalVertex;
            var nV4:DecalVertex;

            var d1:Float = inVertices[i + 0].position.dot(plane) - s;
            var d2:Float = inVertices[i + 1].position.dot(plane) - s;
            var d3:Float = inVertices[i + 2].position.dot(plane) - s;

            var v1Out:Bool = d1 > 0;
            var v2Out:Bool = d2 > 0;
            var v3Out:Bool = d3 > 0;

            // calculate, how many vertices of the face lie outside of the clipping plane

            total = (v1Out ? 1 : 0) + (v2Out ? 1 : 0) + (v3Out ? 1 : 0);

            switch (total) {
                case 0:
                    // the entire face lies inside of the plane, no clipping needed

                    outVertices.push(inVertices[i]);
                    outVertices.push(inVertices[i + 1]);
                    outVertices.push(inVertices[i + 2]);

                case 1:
                    // one vertex lies outside of the plane, perform clipping

                    if (v1Out) {
                        nV1 = inVertices[i + 1];
                        nV2 = inVertices[i + 2];
                        nV3 = clip(inVertices[i], nV1, plane, s);
                        nV4 = clip(inVertices[i], nV2, plane, s);
                    }

                    if (v2Out) {
                        nV1 = inVertices[i];
                        nV2 = inVertices[i + 2];
                        nV3 = clip(inVertices[i + 1], nV1, plane, s);
                        nV4 = clip(inVertices[i + 1], nV2, plane, s);

                        outVertices.push(nV3);
                        outVertices.push(nV2.clone());
                        outVertices.push(nV1.clone());

                        outVertices.push(nV2.clone());
                        outVertices.push(nV3.clone());
                        outVertices.push(nV4);
                    }

                    if (v3Out) {
                        nV1 = inVertices[i];
                        nV2 = inVertices[i + 1];
                        nV3 = clip(inVertices[i + 2], nV1, plane, s);
                        nV4 = clip(inVertices[i + 2], nV2, plane, s);
                    }

                    outVertices.push(nV1.clone());
                    outVertices.push(nV2.clone());
                    outVertices.push(nV3);

                    outVertices.push(nV4);
                    outVertices.push(nV3.clone());
                    outVertices.push(nV2.clone());

                case 2:
                    // two vertices lies outside of the plane, perform clipping

                    if (!v1Out) {
                        nV1 = inVertices[i].clone();
                        nV2 = clip(nV1, inVertices[i + 1], plane, s);
                        nV3 = clip(nV1, inVertices[i + 2], plane, s);
                        outVertices.push(nV1);
                        outVertices.push(nV2);
                        outVertices.push(nV3);
                    }

                    if (!v2Out) {
                        nV1 = inVertices[i + 1].clone();
                        nV2 = clip(nV1, inVertices[i + 2], plane, s);
                        nV3 = clip(nV1, inVertices[i], plane, s);
                        outVertices.push(nV1);
                        outVertices.push(nV2);
                        outVertices.push(nV3);
                    }

                    if (!v3Out) {
                        nV1 = inVertices[i + 2].clone();
                        nV2 = clip(nV1, inVertices[i], plane, s);
                        nV3 = clip(nV1, inVertices[i + 1], plane, s);
                        outVertices.push(nV1);
                        outVertices.push(nV2);
                        outVertices.push(nV3);
                    }

                case 3:
                    // the entire face lies outside of the plane, so let's discard the corresponding vertices

                    break;
            }
        }

        return outVertices;
    }

    function clip(v0:DecalVertex, v1:DecalVertex, p:Vector3, s:Float) {
        var d0:Float = v0.position.dot(p) - s;
        var d1:Float = v1.position.dot(p) - s;

        var s0:Float = d0 / (d0 - d1);

        var v:DecalVertex = new DecalVertex(
            new Vector3(
                v0.position.x + s0 * (v1.position.x - v0.position.x),
                v0.position.y + s0 * (v1.position.y - v0.position.y),
                v0.position.z + s0 * (v1.position.z - v0.position.z)
            ),
            new Vector3(
                v0.normal.x + s0 * (v1.normal.x - v0.normal.x),
                v0.normal.y + s0 * (v1.normal.y - v0.normal.y),
                v0.normal.z + s0 * (v1.normal.z - v0.normal.z)
            )
        );

        // need to clip more values (texture coordinates)? do it this way:
        // intersectpoint.value = a.value + s * ( b.value - a.value );

        return v;
    }
}

// helper

class DecalVertex {

    public var position:Vector3;
    public var normal:Vector3;

    public function new(position:Vector3, normal:Vector3) {
        this.position = position;
        this.normal = normal;
    }

    public function clone():DecalVertex {
        return new DecalVertex(position.clone(), normal.clone());
    }
}
```