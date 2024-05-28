import js.three.BufferGeometry;
import js.three.Float32BufferAttribute;
import js.three.Matrix4;
import js.three.Vector3;

class DecalGeometry extends BufferGeometry {
    public function new(mesh:Dynamic, position:Vector3, orientation:Vector3, size:Vector3) {
        super();

        var vertices = [];
        var normals = [];
        var uvs = [];

        var plane = new Vector3();

        var projectorMatrix = new Matrix4();
        projectorMatrix.makeRotationFromEuler(orientation);
        projectorMatrix.setPosition(position);

        var projectorMatrixInverse = projectorMatrix.clone();
        projectorMatrixInverse.invert();

        generate();

        this.setAttribute('position', new Float32BufferAttribute(vertices, 3));
        this.setAttribute('normal', new Float32BufferAttribute(normals, 3));
        this.setAttribute('uv', new Float32BufferAttribute(uvs, 2));

        function generate() {
            var decalVertices = [];

            var vertex = new Vector3();
            var normal = new Vector3();

            var geometry = mesh.geometry;

            var positionAttribute = geometry.attributes.position;
            var normalAttribute = geometry.attributes.normal;

            if (geometry.index != null) {
                var index = geometry.index;

                for (i in 0...index.count) {
                    vertex = positionAttribute.getX(index.getX(i));
                    normal = normalAttribute.getX(index.getX(i));

                    pushDecalVertex(decalVertices, vertex, normal);
                }
            } else {
                for (i in 0...positionAttribute.count) {
                    vertex = positionAttribute.getX(i);
                    normal = normalAttribute.getX(i);

                    pushDecalVertex(decalVertices, vertex, normal);
                }
            }

            decalVertices = clipGeometry(decalVertices, plane.set(1, 0, 0));
            decalVertices = clipGeometry(decalVertices, plane.set(-1, 0, 0));
            decalVertices = clipGeometry(decalVertices, plane.set(0, 1, 0));
            decalVertices = clipGeometry(decalVertices, plane.set(0, -1, 0));
            decalVertices = clipGeometry(decalVertices, plane.set(0, 0, 1));
            decalVertices = clipGeometry(decalVertices, plane.set(0, 0, -1));

            for (i in 0...decalVertices.length) {
                var decalVertex = decalVertices[i];

                uvs.push(0.5 + (decalVertex.position.x / size.x), 0.5 + (decalVertex.position.y / size.y));

                decalVertex.position.applyMatrix4(projectorMatrix);

                vertices.push(decalVertex.position.x, decalVertex.position.y, decalVertex.position.z);
                normals.push(decalVertex.normal.x, decalVertex.normal.y, decalVertex.normal.z);
            }
        }

        function pushDecalVertex(decalVertices, vertex, normal) {
            vertex.applyMatrix4(mesh.matrixWorld);
            vertex.applyMatrix4(projectorMatrixInverse);

            normal.transformDirection(mesh.matrixWorld);

            decalVertices.push(new DecalVertex(vertex.clone(), normal.clone()));
        }

        function clipGeometry(inVertices, plane) {
            var outVertices = [];

            var s = 0.5 * size.dot(plane);

            for (i in 0...inVertices.length) {
                var total = 0;
                var nV1, nV2, nV3, nV4;

                var d1 = inVertices[i + 0].position.dot(plane) - s;
                var d2 = inVertices[i + 1].position.dot(plane) - s;
                var d3 = inVertices[i + 2].position.dot(plane) - s;

                var v1Out = d1 > 0;
                var v2Out = d2 > 0;
                var v3Out = d3 > 0;

                total = (v1Out ? 1 : 0) + (v2Out ? 1 : 0) + (v3Out ? 1 : 0);

                switch (total) {
                    case 0:
                        outVertices.push(inVertices[i]);
                        outVertices.push(inVertices[i + 1]);
                        outVertices.push(inVertices[i + 2]);
                        break;
                    case 1:
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
                            break;
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
                        break;
                    case 2:
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
                        break;
                    case 3:
                        break;
                }
            }

            return outVertices;
        }

        function clip(v0, v1, p, s) {
            var d0 = v0.position.dot(p) - s;
            var d1 = v1.position.dot(p) - s;

            var s0 = d0 / (d0 - d1);

            var v = new DecalVertex(
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

            return v;
        }
    }
}

class DecalVertex {
    public var position:Vector3;
    public var normal:Vector3;

    public function new(position:Vector3, normal:Vector3) {
        this.position = position;
        this.normal = normal;
    }

    public function clone():DecalVertex {
        return new DecalVertex(this.position.clone(), this.normal.clone());
    }
}