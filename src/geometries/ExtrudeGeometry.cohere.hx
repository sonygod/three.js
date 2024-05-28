package openfl.geom;

import openfl._internal.renderer.DrawCommandReader;
import openfl._internal.renderer.DrawCommandType;
import openfl._internal.renderer.RenderingContext;
import openfl.display.BitmapData;
import openfl.display.CairoRenderer;
import openfl.display.CanvasRenderer;
import openfl.display.DOMRenderer;
import openfl.display.DisplayObject;
import openfl.display.Graphics;
import openfl.display.IBitmapDrawable;
import openfl.display.OpenGLRenderer;
import openfl.display.Stage;
import openfl.display3D.Context3D;
import openfl.display3D.Context3DTriangleFace;
import openfl.display3D.IndexBuffer3D;
import openfl.display3D.Program3D;
import openfl.display3D.VertexBuffer3D;
import openfl.display3D.VertexBuffer3DDataType;
import openfl.display3D.VertexBuffer3DFormat;
import openfl.events.Event;
import openfl.events.EventDispatcher;
import openfl.events.IEventDispatcher;
import openfl.geom.Matrix;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import openfl.utils.AGALMiniAssembler;
import openfl.utils.ByteArray;
import openfl.utils.IDataInput;
import openfl.utils.IDataOutput;

class ExtrudeGeometry extends BufferGeometry {
    public var type:String;
    public var parameters:Dynamic;
    public function new(shapes:Array<Shape> = [new Shape([new Vector2(0.5, 0.5), new Vector2(-0.5, 0.5), new Vector2(-0.5, -0.5), new Vector2(0.5, -0.5)])], options:Dynamic = {}) {
        super();
        this.type = "ExtrudeGeometry";
        this.parameters = {shapes: shapes, options: options};
        shapes = (if (Array.isArray(shapes)) shapes else [shapes]);
        var scope:ExtrudeGeometry = this;
        var verticesArray:Array<Float> = [];
        var uvArray:Array<Float> = [];
        var i:Int, l:Int;
        for (i = 0, l = shapes.length; i < l; i++) {
            var shape:Shape = shapes[i];
            addShape(shape);
        }
        this.setAttribute("position", new Float32BufferAttribute(verticesArray, 3));
        this.setAttribute("uv", new Float32BufferAttribute(uvArray, 2));
        this.computeVertexNormals();
        function addShape(shape:Shape) {
            var placeholder:Array<Float> = [];
            var curveSegments:Int = (if (options.curveSegments != null) options.curveSegments else 12);
            var steps:Int = (if (options.steps != null) options.steps else 1);
            var depth:Float = (if (options.depth != null) options.depth else 1);
            var bevelEnabled:Bool = (if (options.bevelEnabled != null) options.bevelEnabled else true);
            var bevelThickness:Float = (if (options.bevelThickness != null) options.bevelThickness else 0.2);
            var bevelSize:Float = (if (options.bevelSize != null) options.bevelSize else bevelThickness - 0.1);
            var bevelOffset:Float = (if (options.bevelOffset != null) options.bevelOffset else 0);
            var bevelSegments:Int = (if (options.bevelSegments != null) options.bevelSegments else 3);
            var extrudePath:Curve = options.extrudePath;
            var uvgen:Dynamic = (if (options.UVGenerator != null) options.UVGenerator else WorldUVGenerator);
            var extrudePts:Array<Float>, extrudeByPath:Bool, splineTube:Dynamic, binormal:Vector3D, normal:Vector3D, position2:Vector3D;
            if (extrudePath != null) {
                extrudePts = extrudePath.getSpacedPoints(steps);
                extrudeByPath = true;
                bevelEnabled = false;
                splineTube = extrudePath.computeFrenetFrames(steps, false);
                binormal = new Vector3D();
                normal = new Vector3D();
                position2 = new Vector3D();
            }
            if (!bevelEnabled) {
                bevelSegments = 0;
                bevelThickness = 0;
                bevelSize = 0;
                bevelOffset = 0;
            }
            var shapePoints:Dynamic = shape.extractPoints(curveSegments);
            var vertices:Array<Float> = shapePoints.shape;
            var holes:Array<Float> = shapePoints.holes;
            var reverse:Bool = !ShapeUtils.isClockWise(vertices);
            if (reverse) {
                vertices = vertices.reverse();
                var h:Int, hl:Int;
                for (h = 0, hl = holes.length; h < hl; h++) {
                    var ahole:Array<Float> = holes[h];
                    if (ShapeUtils.isClockWise(ahole)) {
                        holes[h] = ahole.reverse();
                    }
                }
            }
            var faces:Array<Int> = ShapeUtils.triangulateShape(vertices, holes);
            var contour:Array<Float> = vertices;
            var vlen:Int, flen:Int;
            for (h = 0, hl = holes.length; h < hl; h++) {
                ahole = holes[h];
                vertices = vertices.concat(ahole);
            }
            function scalePt2(pt:Vector2D, vec:Vector2D, size:Float):Vector2D {
                if (vec == null) {
                    throw new Error("THREE.ExtrudeGeometry: vec does not exist");
                }
                return pt.clone().addScaledVector(vec, size);
            }
            vlen = vertices.length;
            flen = faces.length;
            function getBevelVec(inPt:Vector2D, inPrev:Vector2D, inNext:Vector2D):Vector2D {
                var v_trans_x:Float, v_trans_y:Float, shrink_by:Float, v_prev_x:Float, v_prev_y:Float, v_prev_lensq:Float, collinear0:Float, v_next_x:Float, v_next_y:Float, v_prev_len:Float, v_next_len:Float, ptPrevShift_x:Float, ptPrevShift_y:Float, ptNextShift_x:Float, ptNextShift_y:Float, sf:Float;
                v_prev_x = inPt.x - inPrev.x;
                v_prev_y = inPt.y - inPrev.y;
                v_next_x = inNext.x - inPt.x;
                v_next_y = inNext.y - inPt.y;
                v_prev_lensq = (v_prev_x * v_prev_x + v_prev_y * v_prev_y);
                collinear0 = (v_prev_x * v_next_y - v_prev_y * v_next_x);
                if (Math.abs(collinear0) > Number.EPSILON) {
                    v_prev_len = Math.sqrt(v_prev_lensq);
                    v_next_len = Math.sqrt((v_next_x * v_next_x + v_next_y * v_next_y));
                    ptPrevShift_x = (inPrev.x - v_prev_y / v_prev_len);
                    ptPrevShift_y = (inPrev.y + v_prev_x / v_prev_len);
                    ptNextShift_x = (inNext.x - v_next_y / v_next_len);
                    ptNextShift_y = (inNext.y + v_next_x / v_next_len);
                    sf = ((ptNextShift_x - ptPrevShift_x) * v_next_y - (ptNextShift_y - ptPrevShift_y) * v_next_x) / (v_prev_x * v_next_y - v_prev_y * v_next_x);
                    v_trans_x = (ptPrevShift_x + v_prev_x * sf - inPt.x);
                    v_trans_y = (ptPrevShift_y + v_prev_y * sf - inPt.y);
                    if ((v_trans_x * v_trans_x + v_trans_y * v_trans_y) <= 2) {
                        return new Vector2D(v_trans_x, v_trans_y);
                    } else {
                        shrink_by = Math.sqrt((v_trans_x * v_trans_x + v_trans_y * v_trans_y) / 2);
                    }
                } else {
                    if (v_prev_x > Number.EPSILON) {
                        if (v_next_x > Number.EPSILON) {
                            direction_eq = true;
                        }
                    } else {
                        if (v_prev_x < -Number.EPSILON) {
                            if (v_next_x < -Number.EPSILON) {
                                direction_eq = true;
                            }
                        } else {
                            if (Math.sign(v_prev_y) == Math.sign(v_next_y)) {
                                direction_eq = true;
                            }
                        }
                    }
                    if (direction_eq) {
                        v_trans_x = -v_prev_y;
                        v_trans_y = v_prev_x;
                        shrink_by = Math.sqrt(v_prev_lensq);
                    } else {
                        v_trans_x = v_prev_x;
                        v_trans_y = v_prev_y;
                        shrink_Multiplier = Math.sqrt(v_prev_lensq / 2);
                    }
                }
                return new Vector2D(v_trans_x / shrink_by, v_trans_y / shrink_by);
            }
            var contourMovements:Array<Float> = [];
            var i:Int, il:Int, j:Int, k:Int;
            for (i = 0, il = contour.length, j = il - 1, k = i + 1; i < il; i++, j++, k++) {
                if (j == il) {
                    j = 0;
                }
                if (k == il) {
                    k = 0;
                }
                contourMovements[i] = getBevelVec(contour[i], contour[j], contour[k]);
            }
            var holesMovements:Array<Float> = [];
            var oneHoleMovements:Array<Float>, verticesMovements:Array<Float> = contourMovements.concat();
            for (h = 0, hl = holes.length; h < hl; h++) {
                ahole = holes[h];
                oneHoleMovements = [];
                for (i = 0, il = ahole.length, j = il - 1, k = i + 1; i < il; i++, j++, k++) {
                    if (j == il) {
                        j = 0;
                    }
                    if (k == il) {
                        k = 0;
                    }
                    oneHoleMovements[i] = getBevelVec(ahole[i], ahole[j], ahole[k]);
                }
                holesMovements.push(oneHoleMovements);
                verticesMovements = verticesMovements.concat(oneHoleMovements);
            }
            for (b:Int = 0; b < bevelSegments; b++) {
                var t:Float = b / bevelSegments;
                var z:Float = bevelThickness * Math.cos(t * Math.PI / 2);
                var bs:Float = bevelSize * Math.sin(t * Math.PI / 2) + bevelOffset;
                for (i = 0, il = contour.length; i < il; i++) {
                    var vert:Vector2D = scalePt2(contour[i], contourMovements[i], bs);
                    v(vert.x, vert.y, -z);
                }
                for (h = 0, hl = holes.length; h < hl; h++) {
                    ahole = holes[h];
                    oneHoleMovements = holesMovements[h];
                    for (i = 0, il = ahole.length; i++) {
                        vert = scalePt2(ahole[i], oneHoleMovements[i], bs);
                        v(vert.x, vert.y, -z);
                    }
                }
            }
            bs = bevelSize + bevelOffset;
            for (i = 0; i < vlen; i++) {
                vert = (if (bevelEnabled) scalePt2(vertices[i], verticesMovements[i], bs) else vertices[i]);
                if (!extrudeByPath) {
                    v(vert.x, vert.y, 0);
                } else {
                    normal.copy(splineTube.normals[0]).multiplyScalar(vert.x);
                    binormal.copy(splineTube.binormals[0]).multiplyScalar(vert.y);
                    position2.copy(extrudePts[0]).add(normal).add(binormal);
                    v(position2.x, position2.y, position2.z);
                }
            }
            for (s:Int = 1; s <= steps; s++) {
                for (i = 0; i < vlen; i++) {
                    vert = (if (bevelEnabled) scalePt2(vertices[i], verticesMovements[i], bs) else vertices[i]);
                    if (!extrudeByPath) {
                        v(vert.x, vert.y, depth / steps * s);
                    } else {
                        normal.copy(splineTube.normals[s]).multiplyScalar(vert.x);
                        binormal.copy(splineTube.binormals[s]).multiplyScalar(vert.y);
                        position2.copy(extrudePts[s]).add(normal).add(binormal);
                        v(position2.x, position2.y, position2.z);
                    }
                }
            }
            for (b = bevelSegments - 1; b >= 0; b--) {
                t = b / bevelSegments;
                z = bevelThickness * Math.cos(t * Math.PI / 2);
                bs = bevelSize * Math.sin(t * Math.PI / 2) + bevelOffset;
                for (i = 0, il = contour.length; i < il; i++) {
                    vert = scalePt2(contour[i], contourMovements[i], bs);
                    v(vert.x, vert.y, depth + z);
                }
                for (h = 0, hl = holes.length; h < hl; h++) {
                    ahole = holes[h];
                    oneHoleMovements = holesMovements[h];
                    for (i = 0, il = ahole.length; i++) {
                        vert = scalePt2(ahole[i], oneHoleMovements[i], bs);
                        if (!extrudeByPath) {
                            v(vert.x, vert.y, depth + z);
                        } else {
                            v(vert.x, vert.y + extrudePts[steps - 1].y, extrudePts[steps - 1].x + z);
                        }
                    }
                }
            }
            function buildLidFaces() {
                var start:Int = verticesArray.length / 3;
                if (bevelEnabled) {
                    var layer:Int = 0;
                    var offset:Int = vlen * layer;
                    for (i = 0; i < flen; i++) {
                        var face:Array<Int> = faces[i];
                        f3(face[2] + offset, face[1] + offset, face[0] + offset);
                    }
                    layer = steps + bevelSegments * 2;
                    offset = vlen * layer;
                    for (i = 0; i < flen; i++) {
                        face = faces[i];
                        f3(face[0] + offset, face[1] + offset, face[2] + offset);
                    }
                } else {
                    for (i = 0; i < flen; i++) {
                        face = faces[i];
                        f3(face[2], face[1], face[0]);
                    }
                    for (i = 0; i < flen; i++) {
                        face = faces[i];
                        f3(face[0] + vlen * steps, face[1] + vlen * steps, face[2] + vlen * steps);
                    }
                }
                scope.addGroup(start, verticesArray.length / 3 - start, 0);
            }
            function buildSideFaces() {
                var start:Int = verticesArray.length / 3;
                var layeroffset:Int = 0;
                sidewalls(contour, layeroffset);
                layeroffset += contour.length;
                for (h = 0, hl = holes.length; h < hl; h++) {
                    ahole = holes[h];
                    sidewalls(ahole, layeroffset);
                    layeroffset += ahole.length;
                }
                scope.addGroup(start, verticesArray.length / 3 - start, 1);
            }
            function sidewalls(contour:Array<Float>, layeroffset:Int) {
                var i:Int = contour.length;
                while (--i >= 0) {
                    var j:Int = i;
                    var k:Int = i - 1;
                    if (k < 0) {
                        k = contour.length - 1;
                    }
                    for (var s:Int = 0, sl:Int = (steps + bevelSegments * 2); s < sl; s++) {
                        var slen1:Int = vlen * s;
                        var slen2:Int = vlen * (s + 1);
                        var a:Int = layeroffset + j + slen1;
                        var b:Int = layeroffset + k + slen1;
                        var c:Int = layeroffset + k + slen2;
                        var d:Int = layeroffset + j + slen2;
                        f4(a, b, c, d);
                    }
                }
            }
            function v(x:Float, y:Float, z:Float) {
                placeholder.push(x);
                placeholder.push(y);
                placeholder.push(z);
            }
            function f3(a:Int, b:Int, c:Int) {
                addVertex(a);
                addVertex(b);
                addVertex(c);
                var nextIndex:Int = verticesArray.length / 3;
                var uvs:Array<Float> = uvgen.generateTopUV(scope, verticesArray, nextIndex - 3, nextIndex - 2, nextIndex - 1);
                addUV(uvs[0]);
                addUV(uvs[1]);
                addUV(uvs[2]);
            }
            function f4(a:Int, b:Int, c:Int, d:Int) {
                addVertex(a);
                addVertex(b);
                addVertex(d);
                addVertex(b);
                addVertex(c);
                addVertex(d);
                var nextIndex:Int = verticesArray.length / 3;
                var uvs:Array<Float> = uvgen.generateSideWallUV(scope, verticesArray, nextIndex - 6, nextIndex - 3, nextIndex - 2, nextIndex - 1);
                addUV(uvs[0]);
                addUV(uvs[1]);
                addUV(uvs[3]);
                addUV(uvs[1]);
                addUV(uvs[2]);
                addUV(uvs[3]);
            }
            function addVertex(index:Int) {
                verticesArray.push(placeholder[index * 3 + 0]);
                verticesArray.push(placeholder[index * 3 + 1]);
                verticesArray.push(placeholder[index * 3 + 2]);
            }
            function addUV(vector2:Vector2D) {
                uvArray.push(vector2.x);
                uvArray.push(vector2.y);
            }
        }
    }
    public function copy(source:ExtrudeGeometry):ExtrudeGeometry {
        super.copy(source);
        this.parameters = Object.assign({}, source.parameters);
        return this;
    }
    public function toJSON():Dynamic {
        var data:Dynamic = super.toJSON();
        var shapes:Dynamic = this.parameters.shapes;
        var options:Dynamic = this.parameters.options;
        data.shapes = [];
        if (Array.isArray(shapes)) {
            var i:Int, l:Int;
            for (i = 0, l = shapes.length; i < l; i++) {
                var shape:Shape = shapes[i];
                data.shapes.push(shape.uuid);
            }
        } else {
            data.shapes.push(shapes.uuid);
        }
        data.options = Object.assign({}, options);
        if (options.extrudePath != null) {
            data.options.extrudePath = options.extrudePath.toJSON();
        }
        return data;
    }
    public static function fromJSON(data:Dynamic, shapes:Dynamic):ExtrudeGeometry {
        var geometryShapes:Array<Shape> = [];
        var j:Int, jl:Int;
        for (j = 0, jl = data.shapes.length; j < jl; j++) {
            var shape:Shape = shapes[data.shapes[j]];
            geometryShapes.push(shape);
        }
        var extrudePath:Curve = data.options.extrudePath;
        if (extrudePath != null) {
            data.options.extrudePath = new Curves[extrudePath.type]().fromJSON(extrudePath);
        }
        return new ExtrudeGeometry(geometryShapes, data.options);
    }
}
class WorldUVGenerator {
    public static function generateTopUV(geometry:Dynamic, vertices:Array<Float>, indexA:Int, indexB:Int, indexC:Int):Array<Vector2D> {
        var a_x:Float = vertices[indexA * 3];
        var a_y:Float = vertices[indexA * 3 + 1];
        var b_x:Float = vertices[indexB * 3];
        var b_y:Float = vertices[indexB * 3 + 1];
        var c_x:Float = vertices[indexC * 3];
        var c_y:Float = vertices[indexC * 3 + 1];
        return [
            new Vector2D(a_x, a_y),
            new Vector2D(b_x, b_y),
            new Vector2D(c_x, c_y)
        ];
    }
    public static function generateSideWallUV(geometry:Dynamic, vertices:Array<Float>, indexA:Int, indexB:Int, indexC:Int, indexD:Int):Array<Vector2D> {
        var a_x:Float = vertices[indexA * 3];
        var a_y:Float = vertices[indexA * 3 + 1];
        var a_z:Float = vertices[indexA * 3 + 2];
        var b_x:Float = vertices[indexB * 3];
        var b_y:Float = vertices[indexB * 3 + 1];
        var b_z:Float = vertices[indexB * 3 + 2];
        var c_x:Float = vertices[indexC * 3];
        var c_y:Float = vertices[indexC * 3 + 1];
        var c_z:Float = vertices[indexC * 3 + 2];
        var d_x:Float = vertices[indexD * 3];
        var d_y:Float = vertices[indexD * 3 + 1];
        var d_z:Float = vertices[indexD * 3 + 2];
        if (Math.abs(a_y - b_y) < Math.abs(a_x - b_x)) {
            return [
                new Vector2D(a_x, 1 - a_z),
                new Vector2D(b_x, 1 - b_z),
                new Vector2D(c_x, 1 - c_z),
                new Vector2D(d_x, 1 - d_z)
            ];
        } else {
            return [
                new Vector2D(a_y, 1 - a_z),
                new Vector2D(b_y, 1 - b_z),
                new Vector2D(c_y, 1 - c_z),
                new Vector2D(d_y, 1 - d_z)
            ];
        }
    }
}
function toJSON(shapes:Dynamic, options:Dynamic, data:Dynamic):Dynamic {
    data.shapes = [];
    if (Array.isArray(shapes)) {
        var i:Int, l:Int;
        for (i = 0, l = shapes.length; i < l; i++) {
            var shape:Shape = shapes[i];
            data.shapes.push(shape.uuid);
        }
    } else {
        data.shapes.push(shapes.uuid);
    }
    data.options = Object.assign({}, options);
    if (options.extrudePath != null) {
        data.options.extrudePath = options.extrudePath.toJSON();
    }
    return data;
}