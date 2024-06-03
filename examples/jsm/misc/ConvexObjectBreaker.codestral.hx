import three.core.math.Vector3;
import three.core.math.Plane;
import three.core.math.Line3;
import three.core.objects.Mesh;
import three.examples.jsm.geometries.ConvexGeometry;

class ConvexObjectBreaker {
    private var _v1: Vector3 = new Vector3();
    public var minSizeForBreak: Float;
    public var smallDelta: Float;
    public var tempLine1: Line3;
    public var tempPlane1: Plane;
    public var tempPlane2: Plane;
    public var tempPlane_Cut: Plane;
    public var tempCM1: Vector3;
    public var tempCM2: Vector3;
    public var tempVector3: Vector3;
    public var tempVector3_2: Vector3;
    public var tempVector3_3: Vector3;
    public var tempVector3_P0: Vector3;
    public var tempVector3_P1: Vector3;
    public var tempVector3_P2: Vector3;
    public var tempVector3_N0: Vector3;
    public var tempVector3_N1: Vector3;
    public var tempVector3_AB: Vector3;
    public var tempVector3_CB: Vector3;
    public var tempResultObjects: {object1: Mesh, object2: Mesh};
    public var segments: Array<Bool>;

    public function new(minSizeForBreak: Float = 1.4, smallDelta: Float = 0.0001) {
        this.minSizeForBreak = minSizeForBreak;
        this.smallDelta = smallDelta;
        this.tempLine1 = new Line3();
        this.tempPlane1 = new Plane();
        this.tempPlane2 = new Plane();
        this.tempPlane_Cut = new Plane();
        this.tempCM1 = new Vector3();
        this.tempCM2 = new Vector3();
        this.tempVector3 = new Vector3();
        this.tempVector3_2 = new Vector3();
        this.tempVector3_3 = new Vector3();
        this.tempVector3_P0 = new Vector3();
        this.tempVector3_P1 = new Vector3();
        this.tempVector3_P2 = new Vector3();
        this.tempVector3_N0 = new Vector3();
        this.tempVector3_N1 = new Vector3();
        this.tempVector3_AB = new Vector3();
        this.tempVector3_CB = new Vector3();
        this.tempResultObjects = {object1: null, object2: null};
        this.segments = [];
        for (i in 0...30 * 30) this.segments[i] = false;
    }

    public function prepareBreakableObject(object: Mesh, mass: Float, velocity: Vector3, angularVelocity: Vector3, breakable: Bool) {
        var userData = object.userData;
        userData["mass"] = mass;
        userData["velocity"] = velocity.clone();
        userData["angularVelocity"] = angularVelocity.clone();
        userData["breakable"] = breakable;
    }

    public function subdivideByImpact(object: Mesh, pointOfImpact: Vector3, normal: Vector3, maxRadialIterations: Int, maxRandomIterations: Int): Array<Mesh> {
        var debris: Array<Mesh> = [];
        this.tempVector3.addVectors(pointOfImpact, normal);
        this.tempPlane1.setFromCoplanarPoints(pointOfImpact, object.position, this.tempVector3);
        var maxTotalIterations = maxRandomIterations + maxRadialIterations;
        var scope = this;

        function subdivideRadial(subObject: Mesh, startAngle: Float, endAngle: Float, numIterations: Int) {
            if (Math.random() < numIterations * 0.05 || numIterations > maxTotalIterations) {
                debris.push(subObject);
                return;
            }

            var angle = Math.PI;

            if (numIterations == 0) {
                scope.tempPlane2.normal.copy(scope.tempPlane1.normal);
                scope.tempPlane2.constant = scope.tempPlane1.constant;
            } else {
                if (numIterations <= maxRadialIterations) {
                    angle = (endAngle - startAngle) * (0.2 + 0.6 * Math.random()) + startAngle;
                    scope.tempVector3_2.copy(object.position).sub(pointOfImpact).applyAxisAngle(normal, angle).add(pointOfImpact);
                    scope.tempPlane2.setFromCoplanarPoints(pointOfImpact, scope.tempVector3, scope.tempVector3_2);
                } else {
                    angle = ((0.5 * (numIterations & 1)) + 0.2 * (2 - Math.random())) * Math.PI;
                    scope.tempVector3_2.copy(pointOfImpact).sub(subObject.position).applyAxisAngle(normal, angle).add(subObject.position);
                    scope.tempVector3_3.copy(normal).add(subObject.position);
                    scope.tempPlane2.setFromCoplanarPoints(subObject.position, scope.tempVector3_3, scope.tempVector3_2);
                }
            }

            scope.cutByPlane(subObject, scope.tempPlane2, scope.tempResultObjects);
            var obj1 = scope.tempResultObjects.object1;
            var obj2 = scope.tempResultObjects.object2;

            if (obj1 != null) {
                subdivideRadial(obj1, startAngle, angle, numIterations + 1);
            }

            if (obj2 != null) {
                subdivideRadial(obj2, angle, endAngle, numIterations + 1);
            }
        }

        subdivideRadial(object, 0, 2 * Math.PI, 0);
        return debris;
    }

    public function cutByPlane(object: Mesh, plane: Plane, output: {object1: Mesh, object2: Mesh}): Int {
        var geometry = object.geometry;
        var coords = geometry.attributes.position.array;
        var normals = geometry.attributes.normal.array;
        var numPoints = coords.length / 3;
        var numFaces = numPoints / 3;
        var indices = geometry.getIndex();

        if (indices != null) {
            indices = indices.array;
            numFaces = indices.length / 3;
        }

        function getVertexIndex(faceIdx: Int, vert: Int): Int {
            var idx = faceIdx * 3 + vert;
            return indices != null ? indices[idx] : idx;
        }

        var points1: Array<Vector3> = [];
        var points2: Array<Vector3> = [];
        var delta = this.smallDelta;

        for (i in 0...numPoints * numPoints) this.segments[i] = false;

        var p0 = this.tempVector3_P0;
        var p1 = this.tempVector3_P1;
        var n0 = this.tempVector3_N0;
        var n1 = this.tempVector3_N1;

        for (i in 0...numFaces - 1) {
            var a1 = getVertexIndex(i, 0);
            var b1 = getVertexIndex(i, 1);
            var c1 = getVertexIndex(i, 2);
            n0.set(normals[a1], normals[a1] + 1, normals[a1] + 2);

            for (j in i + 1...numFaces) {
                var a2 = getVertexIndex(j, 0);
                var b2 = getVertexIndex(j, 1);
                var c2 = getVertexIndex(j, 2);
                n1.set(normals[a2], normals[a2] + 1, normals[a2] + 2);

                var coplanar = 1 - n0.dot(n1) < delta;

                if (coplanar) {
                    if (a1 == a2 || a1 == b2 || a1 == c2) {
                        if (b1 == a2 || b1 == b2 || b1 == c2) {
                            this.segments[a1 * numPoints + b1] = true;
                            this.segments[b1 * numPoints + a1] = true;
                        } else {
                            this.segments[c1 * numPoints + a1] = true;
                            this.segments[a1 * numPoints + c1] = true;
                        }
                    } else if (b1 == a2 || b1 == b2 || b1 == c2) {
                        this.segments[c1 * numPoints + b1] = true;
                        this.segments[b1 * numPoints + c1] = true;
                    }
                }
            }
        }

        var localPlane = this.tempPlane_Cut;
        object.updateMatrix();
        ConvexObjectBreaker.transformPlaneToLocalSpace(plane, object.matrix, localPlane);

        for (i in 0...numFaces) {
            var va = getVertexIndex(i, 0);
            var vb = getVertexIndex(i, 1);
            var vc = getVertexIndex(i, 2);

            for (segment in 0...3) {
                var i0 = segment == 0 ? va : (segment == 1 ? vb : vc);
                var i1 = segment == 0 ? vb : (segment == 1 ? vc : va);
                var segmentState = this.segments[i0 * numPoints + i1];

                if (segmentState) continue;

                this.segments[i0 * numPoints + i1] = true;
                this.segments[i1 * numPoints + i0] = true;

                p0.set(coords[3 * i0], coords[3 * i0 + 1], coords[3 * i0 + 2]);
                p1.set(coords[3 * i1], coords[3 * i1 + 1], coords[3 * i1 + 2]);

                var mark0 = 0;
                var d = localPlane.distanceToPoint(p0);

                if (d > delta) {
                    mark0 = 2;
                    points2.push(p0.clone());
                } else if (d < -delta) {
                    mark0 = 1;
                    points1.push(p0.clone());
                } else {
                    mark0 = 3;
                    points1.push(p0.clone());
                    points2.push(p0.clone());
                }

                var mark1 = 0;
                d = localPlane.distanceToPoint(p1);

                if (d > delta) {
                    mark1 = 2;
                    points2.push(p1.clone());
                } else if (d < -delta) {
                    mark1 = 1;
                    points1.push(p1.clone());
                } else {
                    mark1 = 3;
                    points1.push(p1.clone());
                    points2.push(p1.clone());
                }

                if ((mark0 == 1 && mark1 == 2) || (mark0 == 2 && mark1 == 1)) {
                    this.tempLine1.start.copy(p0);
                    this.tempLine1.end.copy(p1);
                    var intersection = localPlane.intersectLine(this.tempLine1, null);

                    if (intersection == null) {
                        trace("Internal error: segment does not intersect plane.");
                        output.object1 = null;
                        output.object2 = null;
                        return 0;
                    }

                    points1.push(intersection);
                    points2.push(intersection.clone());
                }
            }
        }

        var newMass = object.userData["mass"] * 0.5;
        this.tempCM1.set(0, 0, 0);
        var radius1 = 0;
        var numPoints1 = points1.length;

        if (numPoints1 > 0) {
            for (i in 0...numPoints1) this.tempCM1.add(points1[i]);
            this.tempCM1.divideScalar(numPoints1);
            for (i in 0...numPoints1) {
                var p = points1[i];
                p.sub(this.tempCM1);
                radius1 = Math.max(radius1, p.x, p.y, p.z);
            }

            this.tempCM1.add(object.position);
        }

        this.tempCM2.set(0, 0, 0);
        var radius2 = 0;
        var numPoints2 = points2.length;
        if (numPoints2 > 0) {
            for (i in 0...numPoints2) this.tempCM2.add(points2[i]);
            this.tempCM2.divideScalar(numPoints2);
            for (i in 0...numPoints2) {
                var p = points2[i];
                p.sub(this.tempCM2);
                radius2 = Math.max(radius2, p.x, p.y, p.z);
            }

            this.tempCM2.add(object.position);
        }

        var object1: Mesh = null;
        var object2: Mesh = null;
        var numObjects = 0;

        if (numPoints1 > 4) {
            object1 = new Mesh(new ConvexGeometry(points1), object.material);
            object1.position.copy(this.tempCM1);
            object1.quaternion.copy(object.quaternion);
            this.prepareBreakableObject(object1, newMass, object.userData["velocity"], object.userData["angularVelocity"], 2 * radius1 > this.minSizeForBreak);
            numObjects++;
        }

        if (numPoints2 > 4) {
            object2 = new Mesh(new ConvexGeometry(points2), object.material);
            object2.position.copy(this.tempCM2);
            object2.quaternion.copy(object.quaternion);
            this.prepareBreakableObject(object2, newMass, object.userData["velocity"], object.userData["angularVelocity"], 2 * radius2 > this.minSizeForBreak);
            numObjects++;
        }

        output.object1 = object1;
        output.object2 = object2;

        return numObjects;
    }

    static public function transformFreeVector(v: Vector3, m: Matrix4): Vector3 {
        var x = v.x;
        var y = v.y;
        var z = v.z;
        var e = m.elements;
        v.x = e[0] * x + e[4] * y + e[8] * z;
        v.y = e[1] * x + e[5] * y + e[9] * z;
        v.z = e[2] * x + e[6] * y + e[10] * z;
        return v;
    }

    static public function transformFreeVectorInverse(v: Vector3, m: Matrix4): Vector3 {
        var x = v.x;
        var y = v.y;
        var z = v.z;
        var e = m.elements;
        v.x = e[0] * x + e[1] * y + e[2] * z;
        v.y = e[4] * x + e[5] * y + e[6] * z;
        v.z = e[8] * x + e[9] * y + e[10] * z;
        return v;
    }

    static public function transformTiedVectorInverse(v: Vector3, m: Matrix4): Vector3 {
        var x = v.x;
        var y = v.y;
        var z = v.z;
        var e = m.elements;
        v.x = e[0] * x + e[1] * y + e[2] * z - e[12];
        v.y = e[4] * x + e[5] * y + e[6] * z - e[13];
        v.z = e[8] * x + e[9] * y + e[10] * z - e[14];
        return v;
    }

    static public function transformPlaneToLocalSpace(plane: Plane, m: Matrix4, resultPlane: Plane): Void {
        resultPlane.normal.copy(plane.normal);
        resultPlane.constant = plane.constant;
        var referencePoint = ConvexObjectBreaker.transformTiedVectorInverse(plane.coplanarPoint(new Vector3()), m);
        ConvexObjectBreaker.transformFreeVectorInverse(resultPlane.normal, m);
        resultPlane.constant = -referencePoint.dot(resultPlane.normal);
    }
}