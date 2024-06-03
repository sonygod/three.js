@:keep class DecalGeometry extends BufferGeometry {
    public function new(mesh:Mesh, position:Vector3, orientation:Euler, size:Vector3) {
        super();

        var vertices:Array<Float> = [];
        var normals:Array<Float> = [];
        var uvs:Array<Float> = [];

        var plane:Vector3 = new Vector3();

        var projectorMatrix:Matrix4 = new Matrix4();
        projectorMatrix.makeRotationFromEuler(orientation);
        projectorMatrix.setPosition(position);

        var projectorMatrixInverse:Matrix4 = new Matrix4();
        projectorMatrixInverse.copy(projectorMatrix).invert();

        generate();

        this.setAttribute('position', new Float32BufferAttribute(vertices, 3));
        this.setAttribute('normal', new Float32BufferAttribute(normals, 3));
        this.setAttribute('uv', new Float32BufferAttribute(uvs, 2));

        function generate() {
            var decalVertices:Array<DecalVertex> = [];

            var vertex:Vector3 = new Vector3();
            var normal:Vector3 = new Vector3();

            var geometry:BufferGeometry = mesh.geometry;

            var positionAttribute:Float32BufferAttribute = geometry.attributes.position;
            var normalAttribute:Float32BufferAttribute = geometry.attributes.normal;

            if (geometry.index !== null) {
                var index:BufferAttribute = geometry.index;

                for (var i:Int = 0; i < index.count; i++) {
                    vertex.fromBufferAttribute(positionAttribute, index.getX(i));
                    normal.fromBufferAttribute(normalAttribute, index.getX(i));

                    pushDecalVertex(decalVertices, vertex, normal);
                }
            } else {
                for (var i:Int = 0; i < positionAttribute.count; i++) {
                    vertex.fromBufferAttribute(positionAttribute, i);
                    normal.fromBufferAttribute(normalAttribute, i);

                    pushDecalVertex(decalVertices, vertex, normal);
                }
            }

            decalVertices = clipGeometry(decalVertices, plane.set(1, 0, 0));
            decalVertices = clipGeometry(decalVertices, plane.set(-1, 0, 0));
            decalVertices = clipGeometry(decalVertices, plane.set(0, 1, 0));
            decalVertices = clipGeometry(decalVertices, plane.set(0, -1, 0));
            decalVertices = clipGeometry(decalVertices, plane.set(0, 0, 1));
            decalVertices = clipGeometry(decalVertices, plane.set(0, 0, -1));

            for (var i:Int = 0; i < decalVertices.length; i++) {
                var decalVertex:DecalVertex = decalVertices[i];

                uvs.push(0.5 + (decalVertex.position.x / size.x));
                uvs.push(0.5 + (decalVertex.position.y / size.y));

                decalVertex.position.applyMatrix4(projectorMatrix);

                vertices.push(decalVertex.position.x, decalVertex.position.y, decalVertex.position.z);
                normals.push(decalVertex.normal.x, decalVertex.normal.y, decalVertex.normal.z);
            }
        }

        function pushDecalVertex(decalVertices:Array<DecalVertex>, vertex:Vector3, normal:Vector3) {
            vertex.applyMatrix4(mesh.matrixWorld);
            vertex.applyMatrix4(projectorMatrixInverse);

            normal.transformDirection(mesh.matrixWorld);

            decalVertices.push(new DecalVertex(vertex.clone(), normal.clone()));
        }

        function clipGeometry(inVertices:Array<DecalVertex>, plane:Vector3):Array<DecalVertex> {
            var outVertices:Array<DecalVertex> = [];

            var s:Float = 0.5 * Math.abs(size.dot(plane));

            for (var i:Int = 0; i < inVertices.length; i += 3) {
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

                total = (v1Out ? 1 : 0) + (v2Out ? 1 : 0) + (v3Out ? 1 : 0);

                switch (total) {
                    case 0:
                        outVertices.push(inVertices[i]);
                        outVertices.push(inVertices[i + 1]);
                        outVertices.push(inVertices[i + 2]);
                        break;
                    case 1:
                        // ... the rest of the switch statement
                }
            }

            return outVertices;
        }

        function clip(v0:DecalVertex, v1:DecalVertex, p:Vector3, s:Float):DecalVertex {
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