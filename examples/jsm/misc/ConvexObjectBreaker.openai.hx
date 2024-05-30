package three.js.tools;

import three.Vector3;
import three.Line3;
import three.Plane;
import three.Mesh;
import three.geometries.ConvexGeometry;

class ConvexObjectBreaker {
    private var minSizeForBreak:Float;
    private var smallDelta:Float;

    private var tempLine1:Line3;
    private var tempPlane1:Plane;
    private var tempPlane2:Plane;
    private var tempPlane_Cut:Plane;
    private var tempCM1:Vector3;
    private var tempCM2:Vector3;
    private var tempVector3:Vector3;
    private var tempVector3_2:Vector3;
    private var tempVector3_3:Vector3;
    private var tempVector3_P0:Vector3;
    private var tempVector3_P1:Vector3;
    private var tempVector3_P2:Vector3;
    private var tempVector3_N0:Vector3;
    private var tempVector3_N1:Vector3;
    private var tempVector3_AB:Vector3;
    private var tempVector3_CB:Vector3;
    private var tempResultObjects:Object = { object1:null, object2:null };

    private var segments:Array<Bool> = [for (i in 0...30*30) false];

    public function new(?minSizeForBreak:Float = 1.4, ?smallDelta:Float = 0.0001) {
        this.minSizeForBreak = minSizeForBreak;
        this.smallDelta = smallDelta;

        tempLine1 = new Line3();
        tempPlane1 = new Plane();
        tempPlane2 = new Plane();
        tempPlane_Cut = new Plane();
        tempCM1 = new Vector3();
        tempCM2 = new Vector3();
        tempVector3 = new Vector3();
        tempVector3_2 = new Vector3();
        tempVector3_3 = new Vector3();
        tempVector3_P0 = new Vector3();
        tempVector3_P1 = new Vector3();
        tempVector3_P2 = new Vector3();
        tempVector3_N0 = new Vector3();
        tempVector3_N1 = new Vector3();
        tempVector3_AB = new Vector3();
        tempVector3_CB = new Vector3();
    }

    public function prepareBreakableObject(object:Mesh, mass:Float, velocity:Vector3, angularVelocity:Vector3, breakable:Bool) {
        var userData:Object = object.userData;
        userData.mass = mass;
        userData.velocity = velocity.clone();
        userData.angularVelocity = angularVelocity.clone();
        userData.breakable = breakable;
    }

    public function subdivideByImpact(object:Mesh, pointOfImpact:Vector3, normal:Vector3, maxRadialIterations:Int, maxRandomIterations:Int):Array<Mesh> {
        var debris:Array<Mesh> = [];

        var tempPlane1:Plane = tempPlane1;
        var tempPlane2:Plane = tempPlane2;

        tempVector3.addVectors(pointOfImpact, normal);
        tempPlane1.setFromCoplanarPoints(pointOfImpact, object.position, tempVector3);

        var maxTotalIterations:Int = maxRandomIterations + maxRadialIterations;

        var scope:ConvexObjectBreaker = this;

        function subdivideRadial(subObject:Mesh, startAngle:Float, endAngle:Float, numIterations:Int) {
            if (Math.random() < numIterations * 0.05 || numIterations > maxTotalIterations) {
                debris.push(subObject);
                return;
            }

            var angle:Float = Math.PI;

            if (numIterations == 0) {
                tempPlane2.normal.copy(tempPlane1.normal);
                tempPlane2.constant = tempPlane1.constant;
            } else {
                if (numIterations <= maxRadialIterations) {
                    angle = (endAngle - startAngle) * (0.2 + 0.6 * Math.random()) + startAngle;
                    tempVector3_2.copy(object.position).sub(pointOfImpact).applyAxisAngle(normal, angle).add(pointOfImpact);
                    tempPlane2.setFromCoplanarPoints(pointOfImpact, tempVector3, tempVector3_2);
                } else {
                    angle = (0.5 * (numIterations & 1) + 0.2 * (2 - Math.random())) * Math.PI;
                    tempVector3_2.copy(pointOfImpact).sub(object.position).applyAxisAngle(normal, angle).add(object.position);
                    tempVector3_3.copy(normal).add(object.position);
                    tempPlane2.setFromCoplanarPoints(object.position, tempVector3_3, tempVector3_2);
                }
            }

            scope.cutByPlane(subObject, tempPlane2, scope.tempResultObjects);

            var obj1:Mesh = scope.tempResultObjects.object1;
            var obj2:Mesh = scope.tempResultObjects.object2;

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

    public function cutByPlane(object:Mesh, plane:Plane, output:Object) {
        var geometry = object.geometry;
        var coords:Array<Float> = geometry.attributes.position.array;
        var normals:Array<Float> = geometry.attributes.normal.array;

        var numPoints:Int = coords.length ~/ 3;
        var numFaces:Int = numPoints ~/ 3;

        var indices:Array<UInt> = geometry.getIndex().array;

        function getVertexIndex(faceIdx:Int, vert:Int) {
            return indices != null ? indices[faceIdx * 3 + vert] : faceIdx * 3 + vert;
        }

        var points1:Array<Vector3> = [];
        var points2:Array<Vector3> = [];

        var delta:Float = this.smallDelta;

        for (i in 0...numPoints * numPoints) this.segments[i] = false;

        var p0:Vector3 = tempVector3_P0;
        var p1:Vector3 = tempVector3_P1;
        var n0:Vector3 = tempVector3_N0;
        var n1:Vector3 = tempVector3_N1;

        for (i in 0...numFaces - 1) {
            var a1:Int = getVertexIndex(i, 0);
            var b1:Int = getVertexIndex(i, 1);
            var c1:Int = getVertexIndex(i, 2);

            n0.set(normals[a1], normals[a1 + 1], normals[a1 + 2]);

            for (j in i + 1...numFaces) {
                var a2:Int = getVertexIndex(j, 0);
                var b2:Int = getVertexIndex(j, 1);
                var c2:Int = getVertexIndex(j, 2);

                n1.set(normals[a2], normals[a2 + 1], normals[a2 + 2]);

                var coplanar:Bool = 1 - n0.dot(n1) < delta;

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

        object.updateMatrix();
        var localPlane:Plane = tempPlane_Cut;
        this.transformPlaneToLocalSpace(plane, object.matrix, localPlane);

        for (i in 0...numFaces) {
            var va:Int = getVertexIndex(i, 0);
            var vb:Int = getVertexIndex(i, 1);
            var vc:Int = getVertexIndex(i, 2);

            for (segment in 0...3) {
                var i0:Int = segment == 0 ? va : (segment == 1 ? vb : vc);
                var i1:Int = segment == 0 ? vb : (segment == 1 ? vc : va);

                var segmentState:Bool = this.segments[i0 * numPoints + i1];

                if (segmentState) continue;

                this.segments[i0 * numPoints + i1] = true;
                this.segments[i1 * numPoints + i0] = true;

                p0.set(coords[i0 * 3], coords[i0 * 3 + 1], coords[i0 * 3 + 2]);
                p1.set(coords[i1 * 3], coords[i1 * 3 + 1], coords[i1 * 3 + 2]);

                var d:Float = localPlane.distanceToPoint(p0);

                if (d > delta) {
                    points2.push(p0.clone());
                } else if (d < -delta) {
                    points1.push(p0.clone());
                } else {
                    points1.push(p0.clone());
                    points2.push(p0.clone());
                }

                d = localPlane.distanceToPoint(p1);

                if (d > delta) {
                    points2.push(p1.clone());
                } else if (d < -delta) {
                    points1.push(p1.clone());
                } else {
                    points1.push(p1.clone());
                    points2.push(p1.clone());
                }

                if ((d > delta && localPlane.distanceToPoint(p1) < -delta) || (d < -delta && localPlane.distanceToPoint(p1) > delta)) {
                    this.tempLine1.start.copy(p0);
                    this.tempLine1.end.copy(p1);

                    var intersection:Vector3 = localPlane.intersectLine(tempLine1);

                    if (intersection == null) {
                        // Shouldn't happen
                        trace('Internal error: segment does not intersect plane.');
                        output.segmentedObject1 = null;
                        output.segmentedObject2 = null;
                        return 0;
                    }

                    points1.push(intersection);
                    points2.push(intersection.clone());
                }
            }
        }

        var newMass:Float = object.userData.mass * 0.5;

        var radius1:Float = 0;
        var radius2:Float = 0;

        tempCM1.set(0, 0, 0);
        for (p in points1) tempCM1.add(p);

        tempCM1.divideScalar(points1.length);

        for (p in points1) {
            p.sub(tempCM1);
            radius1 = Math.max(radius1, p.x, p.y, p.z);
        }

        tempCM1.add(object.position);

        tempCM2.set(0, 0, 0);
        for (p in points2) tempCM2.add(p);

        tempCM2.divideScalar(points2.length);

        for (p in points2) {
            p.sub(tempCM2);
            radius2 = Math.max(radius2, p.x, p.y, p.z);
        }

        tempCM2.add(object.position);

        var object1:Mesh = null;
        var object2:Mesh = null;

        var numObjects:Int = 0;

        if (points1.length > 4) {
            object1 = new Mesh(new ConvexGeometry(points1), object.material);
            object1.position.copy(tempCM1);
            object1.quaternion.copy(object.quaternion);

            this.prepareBreakableObject(object1, newMass, object.userData.velocity, object.userData.angularVelocity, 2 * radius1 > this.minSizeForBreak);

            numObjects++;
        }

        if (points2.length > 4) {
            object2 = new Mesh(new ConvexGeometry(points2), object.material);
            object2.position.copy(tempCM2);
            object2.quaternion.copy(object.quaternion);

            this.prepareBreakableObject(object2, newMass, object.userData.velocity, object.userData.angularVelocity, 2 * radius2 > this.minSizeForBreak);

            numObjects++;
        }

        output.object1 = object1;
        output.object2 = object2;

        return numObjects;
    }

    static public function transformFreeVector(v:Vector3, m:Array<Float>) {
        var x:Float = v.x;
        var y:Float = v.y;
        var z:Float = v.z;
        var e:Array<Float> = m;

        v.x = e[0] * x + e[4] * y + e[8] * z;
        v.y = e[1] * x + e[5] * y + e[9] * z;
        v.z = e[2] * x + e[6] * y + e[10] * z;

        return v;
    }

    static public function transformFreeVectorInverse(v:Vector3, m:Array<Float>) {
        var x:Float = v.x;
        var y:Float = v.y;
        var z:Float = v.z;
        var e:Array<Float> = m;

        v.x = e[0] * x + e[1] * y + e[2] * z;
        v.y = e[4] * x + e[5] * y + e[6] * z;
        v.z = e[8] * x + e[9] * y + e[10] * z;

        return v;
    }

    static public function transformTiedVectorInverse(v:Vector3, m:Array<Float>) {
        var x:Float = v.x;
        var y:Float = v.y;
        var z:Float = v.z;
        var e:Array<Float> = m;

        v.x = e[0] * x + e[1] * y + e[2] * z - e[12];
        v.y = e[4] * x + e[5] * y + e[6] * z - e[13];
        v.z = e[8] * x + e[9] * y + e[10] * z - e[14];

        return v;
    }

    static public function transformPlaneToLocalSpace(plane:Plane, m:Array<Float>, resultPlane:Plane) {
        resultPlane.normal.copy(plane.normal);
        resultPlane.constant = plane.constant;

        var referencePoint:Vector3 = ConvexObjectBreaker.transformTiedVectorInverse(plane.coplanarPoint(tempVector3_P0), m);

        ConvexObjectBreaker.transformFreeVectorInverse(resultPlane.normal, m);

        resultPlane.constant = -referencePoint.dot(resultPlane.normal);
    }
}