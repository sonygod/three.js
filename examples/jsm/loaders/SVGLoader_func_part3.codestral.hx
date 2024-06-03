import haxe.ds.Vector;

class SVGLoader {
    public static function pointsToStrokeWithBuffers(points:Array<Vector>, style:Dynamic, arcDivisions:Int, minDistance:Float, vertices:Array<Float>, normals:Array<Float>, uvs:Array<Float>, vertexOffset:Int):Int {
        var tempV2_1:Vector = new Vector();
        var tempV2_2:Vector = new Vector();
        var tempV2_3:Vector = new Vector();
        var tempV2_4:Vector = new Vector();
        var tempV2_5:Vector = new Vector();
        var tempV2_6:Vector = new Vector();
        var tempV2_7:Vector = new Vector();
        var lastPointL:Vector = new Vector();
        var lastPointR:Vector = new Vector();
        var point0L:Vector = new Vector();
        var point0R:Vector = new Vector();
        var currentPointL:Vector = new Vector();
        var currentPointR:Vector = new Vector();
        var nextPointL:Vector = new Vector();
        var nextPointR:Vector = new Vector();
        var innerPoint:Vector = new Vector();
        var outerPoint:Vector = new Vector();

        if (arcDivisions == null) arcDivisions = 12;
        if (minDistance == null) minDistance = 0.001;
        if (vertexOffset == null) vertexOffset = 0;

        points = removeDuplicatedPoints(points);

        var numPoints:Int = points.length;

        if (numPoints < 2) return 0;

        var isClosed:Bool = points[0].equals(points[numPoints - 1]);

        var currentPoint:Vector;
        var previousPoint:Vector = points[0];
        var nextPoint:Vector;

        var strokeWidth2:Float = style.strokeWidth / 2;

        var deltaU:Float = 1 / (numPoints - 1);
        var u0:Float = 0;
        var u1:Float;

        var innerSideModified:Bool;
        var joinIsOnLeftSide:Bool;
        var isMiter:Bool;
        var initialJoinIsOnLeftSide:Bool = false;

        var numVertices:Int = 0;
        var currentCoordinate:Int = vertexOffset * 3;
        var currentCoordinateUV:Int = vertexOffset * 2;

        getNormal(points[0], points[1], tempV2_1).multiplyScalar(strokeWidth2);
        lastPointL.copy(points[0]).sub(tempV2_1);
        lastPointR.copy(points[0]).add(tempV2_1);
        point0L.copy(lastPointL);
        point0R.copy(lastPointR);

        for (var iPoint:Int = 1; iPoint < numPoints; iPoint++) {
            currentPoint = points[iPoint];

            if (iPoint == numPoints - 1) {
                if (isClosed) {
                    nextPoint = points[1];
                } else nextPoint = null;
            } else {
                nextPoint = points[iPoint + 1];
            }

            var normal1:Vector = tempV2_1;
            getNormal(previousPoint, currentPoint, normal1);

            tempV2_3.copy(normal1).multiplyScalar(strokeWidth2);
            currentPointL.copy(currentPoint).sub(tempV2_3);
            currentPointR.copy(currentPoint).add(tempV2_3);

            u1 = u0 + deltaU;

            innerSideModified = false;

            if (nextPoint != null) {
                getNormal(currentPoint, nextPoint, tempV2_2);

                tempV2_3.copy(tempV2_2).multiplyScalar(strokeWidth2);
                nextPointL.copy(currentPoint).sub(tempV2_3);
                nextPointR.copy(currentPoint).add(tempV2_3);

                joinIsOnLeftSide = true;
                tempV2_3.subVectors(nextPoint, previousPoint);
                if (normal1.dot(tempV2_3) < 0) {
                    joinIsOnLeftSide = false;
                }

                if (iPoint == 1) initialJoinIsOnLeftSide = joinIsOnLeftSide;

                tempV2_3.subVectors(nextPoint, currentPoint);
                tempV2_3.normalize();
                var dot:Float = Math.abs(normal1.dot(tempV2_3));

                if (dot > Number.EPSILON) {
                    var miterSide:Float = strokeWidth2 / dot;
                    tempV2_3.multiplyScalar(-miterSide);
                    tempV2_4.subVectors(currentPoint, previousPoint);
                    tempV2_5.copy(tempV2_4).setLength(miterSide).add(tempV2_3);
                    innerPoint.copy(tempV2_5).negate();
                    var miterLength2:Float = tempV2_5.length();
                    var segmentLengthPrev:Float = tempV2_4.length();
                    tempV2_4.divideScalar(segmentLengthPrev);
                    tempV2_6.subVectors(nextPoint, currentPoint);
                    var segmentLengthNext:Float = tempV2_6.length();
                    tempV2_6.divideScalar(segmentLengthNext);

                    if (tempV2_4.dot(innerPoint) < segmentLengthPrev && tempV2_6.dot(innerPoint) < segmentLengthNext) {
                        innerSideModified = true;
                    }

                    outerPoint.copy(tempV2_5).add(currentPoint);
                    innerPoint.add(currentPoint);

                    isMiter = false;

                    if (innerSideModified) {
                        if (joinIsOnLeftSide) {
                            nextPointR.copy(innerPoint);
                            currentPointR.copy(innerPoint);
                        } else {
                            nextPointL.copy(innerPoint);
                            currentPointL.copy(innerPoint);
                        }
                    } else {
                        makeSegmentTriangles();
                    }

                    switch (style.strokeLineJoin) {
                        case 'bevel':
                            makeSegmentWithBevelJoin(joinIsOnLeftSide, innerSideModified, u1);
                            break;
                        case 'round':
                            createSegmentTrianglesWithMiddleSection(joinIsOnLeftSide, innerSideModified);
                            if (joinIsOnLeftSide) {
                                makeCircularSector(currentPoint, currentPointL, nextPointL, u1, 0);
                            } else {
                                makeCircularSector(currentPoint, nextPointR, currentPointR, u1, 1);
                            }
                            break;
                        case 'miter':
                        case 'miter-clip':
                        default:
                            var miterFraction:Float = (strokeWidth2 * style.strokeMiterLimit) / miterLength2;

                            if (miterFraction < 1) {
                                if (style.strokeLineJoin != 'miter-clip') {
                                    makeSegmentWithBevelJoin(joinIsOnLeftSide, innerSideModified, u1);
                                    break;
                                } else {
                                    createSegmentTrianglesWithMiddleSection(joinIsOnLeftSide, innerSideModified);

                                    if (joinIsOnLeftSide) {
                                        tempV2_6.subVectors(outerPoint, currentPointL).multiplyScalar(miterFraction).add(currentPointL);
                                        tempV2_7.subVectors(outerPoint, nextPointL).multiplyScalar(miterFraction).add(nextPointL);

                                        addVertex(currentPointL, u1, 0);
                                        addVertex(tempV2_6, u1, 0);
                                        addVertex(currentPoint, u1, 0.5);

                                        addVertex(currentPoint, u1, 0.5);
                                        addVertex(tempV2_6, u1, 0);
                                        addVertex(tempV2_7, u1, 0);

                                        addVertex(currentPoint, u1, 0.5);
                                        addVertex(tempV2_7, u1, 0);
                                        addVertex(nextPointL, u1, 0);
                                    } else {
                                        tempV2_6.subVectors(outerPoint, currentPointR).multiplyScalar(miterFraction).add(currentPointR);
                                        tempV2_7.subVectors(outerPoint, nextPointR).multiplyScalar(miterFraction).add(nextPointR);

                                        addVertex(currentPointR, u1, 1);
                                        addVertex(tempV2_6, u1, 1);
                                        addVertex(currentPoint, u1, 0.5);

                                        addVertex(currentPoint, u1, 0.5);
                                        addVertex(tempV2_6, u1, 1);
                                        addVertex(tempV2_7, u1, 1);

                                        addVertex(currentPoint, u1, 0.5);
                                        addVertex(tempV2_7, u1, 1);
                                        addVertex(nextPointR, u1, 1);
                                    }
                                }
                            } else {
                                if (innerSideModified) {
                                    if (joinIsOnLeftSide) {
                                        addVertex(lastPointR, u0, 1);
                                        addVertex(lastPointL, u0, 0);
                                        addVertex(outerPoint, u1, 0);

                                        addVertex(lastPointR, u0, 1);
                                        addVertex(outerPoint, u1, 0);
                                        addVertex(innerPoint, u1, 1);
                                    } else {
                                        addVertex(lastPointR, u0, 1);
                                        addVertex(lastPointL, u0, 0);
                                        addVertex(outerPoint, u1, 1);

                                        addVertex(lastPointL, u0, 0);
                                        addVertex(innerPoint, u1, 0);
                                        addVertex(outerPoint, u1, 1);
                                    }

                                    if (joinIsOnLeftSide) {
                                        nextPointL.copy(outerPoint);
                                    } else {
                                        nextPointR.copy(outerPoint);
                                    }
                                } else {
                                    if (joinIsOnLeftSide) {
                                        addVertex(currentPointL, u1, 0);
                                        addVertex(outerPoint, u1, 0);
                                        addVertex(currentPoint, u1, 0.5);

                                        addVertex(currentPoint, u1, 0.5);
                                        addVertex(outerPoint, u1, 0);
                                        addVertex(nextPointL, u1, 0);
                                    } else {
                                        addVertex(currentPointR, u1, 1);
                                        addVertex(outerPoint, u1, 1);
                                        addVertex(currentPoint, u1, 0.5);

                                        addVertex(currentPoint, u1, 0.5);
                                        addVertex(outerPoint, u1, 1);
                                        addVertex(nextPointR, u1, 1);
                                    }
                                }

                                isMiter = true;
                            }

                            break;
                    }
                } else {
                    makeSegmentTriangles();
                }
            } else {
                makeSegmentTriangles();
            }

            if (!isClosed && iPoint == numPoints - 1) {
                addCapGeometry(points[0], point0L, point0R, joinIsOnLeftSide, true, u0);
            }

            u0 = u1;

            previousPoint = currentPoint;

            lastPointL.copy(nextPointL);
            lastPointR.copy(nextPointR);
        }

        if (!isClosed) {
            addCapGeometry(currentPoint, currentPointL, currentPointR, joinIsOnLeftSide, false, u1);
        } else if (innerSideModified && vertices != null) {
            var lastOuter:Vector = outerPoint;
            var lastInner:Vector = innerPoint;

            if (initialJoinIsOnLeftSide != joinIsOnLeftSide) {
                lastOuter = innerPoint;
                lastInner = outerPoint;
            }

            if (joinIsOnLeftSide) {
                if (isMiter || initialJoinIsOnLeftSide) {
                    lastInner.toArray(vertices, 0 * 3);
                    lastInner.toArray(vertices, 3 * 3);

                    if (isMiter) {
                        lastOuter.toArray(vertices, 1 * 3);
                    }
                }
            } else {
                if (isMiter || !initialJoinIsOnLeftSide) {
                    lastInner.toArray(vertices, 1 * 3);
                    lastInner.toArray(vertices, 3 * 3);

                    if (isMiter) {
                        lastOuter.toArray(vertices, 0 * 3);
                    }
                }
            }
        }

        return numVertices;

        function getNormal(p1:Vector, p2:Vector, result:Vector):Vector {
            result.subVectors(p2, p1);
            return result.set(-result.y, result.x).normalize();
        }

        function addVertex(position:Vector, u:Float, v:Float) {
            if (vertices != null) {
                vertices[currentCoordinate] = position.x;
                vertices[currentCoordinate + 1] = position.y;
                vertices[currentCoordinate + 2] = 0;

                if (normals != null) {
                    normals[currentCoordinate] = 0;
                    normals[currentCoordinate + 1] = 0;
                    normals[currentCoordinate + 2] = 1;
                }

                currentCoordinate += 3;

                if (uvs != null) {
                    uvs[currentCoordinateUV] = u;
                    uvs[currentCoordinateUV + 1] = v;

                    currentCoordinateUV += 2;
                }
            }

            numVertices += 3;
        }

        function makeCircularSector(center:Vector, p1:Vector, p2:Vector, u:Float, v:Float) {
            tempV2_1.copy(p1).sub(center).normalize();
            tempV2_2.copy(p2).sub(center).normalize();

            var angle:Float = Math.PI;
            var dot:Float = tempV2_1.dot(tempV2_2);
            if (Math.abs(dot) < 1) angle = Math.abs(Math.acos(dot));

            angle /= arcDivisions;

            tempV2_3.copy(p1);

            for (var i:Int = 0; i < arcDivisions - 1; i++) {
                tempV2_4.copy(tempV2_3).rotateAround(center, angle);

                addVertex(tempV2_3, u, v);
                addVertex(tempV2_4, u, v);
                addVertex(center, u, 0.5);

                tempV2_3.copy(tempV2_4);
            }

            addVertex(tempV2_4, u, v);
            addVertex(p2, u, v);
            addVertex(center, u, 0.5);
        }

        function makeSegmentTriangles() {
            addVertex(lastPointR, u0, 1);
            addVertex(lastPointL, u0, 0);
            addVertex(currentPointL, u1, 0);

            addVertex(lastPointR, u0, 1);
            addVertex(currentPointL, u1, 0);
            addVertex(currentPointR, u1, 1);
        }

        function makeSegmentWithBevelJoin(joinIsOnLeftSide:Bool, innerSideModified:Bool, u:Float) {
            if (innerSideModified) {
                if (joinIsOnLeftSide) {
                    addVertex(lastPointR, u0, 1);
                    addVertex(lastPointL, u0, 0);
                    addVertex(currentPointL, u1, 0);

                    addVertex(lastPointR, u0, 1);
                    addVertex(currentPointL, u1, 0);
                    addVertex(innerPoint, u1, 1);

                    addVertex(currentPointL, u, 0);
                    addVertex(nextPointL, u, 0);
                    addVertex(innerPoint, u, 0.5);
                } else {
                    addVertex(lastPointR, u0, 1);
                    addVertex(lastPointL, u0, 0);
                    addVertex(currentPointR, u1, 1);

                    addVertex(lastPointL, u0, 0);
                    addVertex(innerPoint, u1, 0);
                    addVertex(currentPointR, u1, 1);

                    addVertex(currentPointR, u, 1);
                    addVertex(innerPoint, u, 0);
                    addVertex(nextPointR, u, 1);
                }
            } else {
                if (joinIsOnLeftSide) {
                    addVertex(currentPointL, u, 0);
                    addVertex(nextPointL, u, 0);
                    addVertex(currentPoint, u, 0.5);
                } else {
                    addVertex(currentPointR, u, 1);
                    addVertex(nextPointR, u, 0);
                    addVertex(currentPoint, u, 0.5);
                }
            }
        }

        function createSegmentTrianglesWithMiddleSection(joinIsOnLeftSide:Bool, innerSideModified:Bool) {
            if (innerSideModified) {
                if (joinIsOnLeftSide) {
                    addVertex(lastPointR, u0, 1);
                    addVertex(lastPointL, u0, 0);
                    addVertex(currentPointL, u1, 0);

                    addVertex(lastPointR, u0, 1);
                    addVertex(currentPointL, u1, 0);
                    addVertex(innerPoint, u1, 1);

                    addVertex(currentPointL, u0, 0);
                    addVertex(currentPoint, u1, 0.5);
                    addVertex(innerPoint, u1, 1);

                    addVertex(currentPoint, u1, 0.5);
                    addVertex(nextPointL, u0, 0);
                    addVertex(innerPoint, u1, 1);
                } else {
                    addVertex(lastPointR, u0, 1);
                    addVertex(lastPointL, u0, 0);
                    addVertex(currentPointR, u1, 1);

                    addVertex(lastPointL, u0, 0);
                    addVertex(innerPoint, u1, 0);
                    addVertex(currentPointR, u1, 1);

                    addVertex(currentPointR, u0, 1);
                    addVertex(innerPoint, u1, 0);
                    addVertex(currentPoint, u1, 0.5);

                    addVertex(currentPoint, u1, 0.5);
                    addVertex(innerPoint, u1, 0);
                    addVertex(nextPointR, u0, 1);
                }
            }
        }

        function addCapGeometry(center:Vector, p1:Vector, p2:Vector, joinIsOnLeftSide:Bool, start:Bool, u:Float) {
            switch (style.strokeLineCap) {
                case 'round':
                    if (start) {
                        makeCircularSector(center, p2, p1, u, 0.5);
                    } else {
                        makeCircularSector(center, p1, p2, u, 0.5);
                    }
                    break;
                case 'square':
                    if (start) {
                        tempV2_1.subVectors(p1, center);
                        tempV2_2.set(tempV2_1.y, -tempV2_1.x);

                        tempV2_3.addVectors(tempV2_1, tempV2_2).add(center);
                        tempV2_4.subVectors(tempV2_2, tempV2_1).add(center);

                        if (joinIsOnLeftSide) {
                            tempV2_3.toArray(vertices, 1 * 3);
                            tempV2_4.toArray(vertices, 0 * 3);
                            tempV2_4.toArray(vertices, 3 * 3);
                        } else {
                            tempV2_3.toArray(vertices, 1 * 3);
                            if (uvs[3 * 2 + 1] == 1) {
                                tempV2_4.toArray(vertices, 3 * 3);
                            } else {
                                tempV2_3.toArray(vertices, 3 * 3);
                            }
                            tempV2_4.toArray(vertices, 0 * 3);
                        }
                    } else {
                        tempV2_1.subVectors(p2, center);
                        tempV2_2.set(tempV2_1.y, -tempV2_1.x);

                        tempV2_3.addVectors(tempV2_1, tempV2_2).add(center);
                        tempV2_4.subVectors(tempV2_2, tempV2_1).add(center);

                        var vl:Int = vertices.length;

                        if (joinIsOnLeftSide) {
                            tempV2_3.toArray(vertices, vl - 1 * 3);
                            tempV2_4.toArray(vertices, vl - 2 * 3);
                            tempV2_4.toArray(vertices, vl - 4 * 3);
                        } else {
                            tempV2_4.toArray(vertices, vl - 2 * 3);
                            tempV2_3.toArray(vertices, vl - 1 * 3);
                            tempV2_4.toArray(vertices, vl - 4 * 3);
                        }
                    }
                    break;
                case 'butt':
                default:
                    break;
            }
        }

        function removeDuplicatedPoints(points:Array<Vector>):Array<Vector> {
            var dupPoints:Bool = false;
            for (var i:Int = 1; i < points.length - 1; i++) {
                if (points[i].distanceTo(points[i + 1]) < minDistance) {
                    dupPoints = true;
                    break;
                }
            }

            if (!dupPoints) return points;

            var newPoints:Array<Vector> = [];
            newPoints.push(points[0]);

            for (var i:Int = 1; i < points.length - 1; i++) {
                if (points[i].distanceTo(points[i + 1]) >= minDistance) {
                    newPoints.push(points[i]);
                }
            }

            newPoints.push(points[points.length - 1]);

            return newPoints;
        }
    }
}