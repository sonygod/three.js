package openfl.display3D.extras;

import openfl.display3D.IndexBuffer3D;
import openfl.display3D.VertexBuffer3D;
import openfl.display3D.contexts.Context3D;
import openfl.display3D.IndexBufferFormat;
import openfl.display3D.VertexBufferFormat;
import openfl.geom.Vector3D;
import openfl.utils.ColorTransform;

class GridHelper {
    public function new(size:Float = 10.0, divisions:Int = 10, color1:Int = 0x444444, color2:Int = 0x888888) {
        var context:Context3D = openfl.Lib.current.context3D;
        var vertices:Array<Vector3D> = [];
        var colors:Array<Float> = [];
        var center:Int = divisions / 2;
        var step:Float = size / divisions;
        var halfSize:Float = size / 2.0;
        var i:Int, j:Int, k:Float;
        for (i = 0; i <= divisions; i++) {
            k = -halfSize;
            while (k <= halfSize) {
                vertices.push(Vector3D_impl(-halfSize, 0, k));
                vertices.push(Vector3D_impl(halfSize, 0, k));
                k += step;
            }
            k = -halfSize;
            while (k <= halfSize) {
                vertices.push(Vector3D_impl(k, 0, -halfSize));
                vertices.push(Vector3D_impl(k, 0, halfSize));
                k += step;
            }
            var color:ColorTransform = i == center ? ColorTransform_impl(color1) : ColorTransform_impl(color2);
            color.toArray(colors);
        }
        var vertexBuffer:VertexBuffer3D = context.createVertexBuffer(VertexBuffer3D_impl(vertices, colors, Vector3D));
        var indexBuffer:IndexBuffer3D = context.createIndexBuffer(IndexBuffer3D_impl(divisions * 4, IndexBufferFormat.UInt16));
        var indices:Array<Int> = [];
        var index:Int = 0;
        for (i = 0; i < divisions; i++) {
            for (j = 0; j < 2; j++) {
                indices.push(index);
                indices.push(index + 1);
                index += 2;
            }
        }
        indexBuffer.uploadFromArray(indices, 0, indices.length);
        context.setVertexBufferAt(0, vertexBuffer, 0, VertexBufferFormat.Float3);
        context.setVertexBufferAt(1, vertexBuffer, 3, VertexBufferFormat.Float3);
        context.setVertexBufferAt(2, vertexBuffer, 6, VertexBufferFormat.Float4);
        context.setIndexBuffer(indexBuffer);
        context.drawTriangles(indexBuffer.numIndices);
    }
}

function Vector3D_impl(x:Float, y:Float, z:Float):Vector3D {
    var vector:Vector3D = new Vector3D();
    vector.x = x;
    vector.y = y;
    vector.z = z;
    return vector;
}

function ColorTransform_impl(color:Int):ColorTransform {
    var transform:ColorTransform = new ColorTransform();
    transform.color = color;
    return transform;
}

function VertexBuffer3D_impl(vertices:Array<Vector3D>, colors:Array<Float>, defaultVertex:Vector3D):VertexBuffer3D {
    var vertexBuffer:VertexBuffer3D = new VertexBuffer3D();
    vertexBuffer.numVertices = vertices.length;
    vertexBuffer.format = VertexBufferFormat.Float3;
    vertexBuffer.uploadFromArray(vertices, 0, VertexBufferFormat.Float3);
    vertexBuffer.uploadFromArray(colors, 0, VertexBufferFormat.Float4, 3, vertices.length);
    vertexBuffer.uploadFromArray([defaultVertex.x, defaultVertex.y, defaultVertex.z], 0, VertexBufferFormat.Float3, vertices.length);
    return vertexBuffer;
}

function IndexBuffer3D_impl(numIndices:Int, format:IndexBufferFormat):IndexBuffer3D {
    var indexBuffer:IndexBuffer3D = new IndexBuffer3D();
    indexBuffer.numIndices = numIndices;
    indexBuffer.format = format;
    return indexBuffer;
}