package three.js.utils;

import js.html.CanvasElement;
import js.html.CanvasRenderingContext2D;
import three.Vector2;

class UVsDebug {
    public static function debug(geometry:three.Geometry, size:Int = 1024):CanvasElement {
        var canvas = js.Browser.document.createElement("canvas");
        canvas.width = size; // power of 2 required for wrapping
        canvas.height = size;

        var ctx:CanvasRenderingContext2D = canvas.getContext("2d");
        ctx.lineWidth = 1;
        ctx.strokeStyle = "rgb(63, 63, 63)";
        ctx.textAlign = "center";

        // paint background white
        ctx.fillStyle = "rgb(255, 255, 255)";
        ctx.fillRect(0, 0, size, size);

        var index:Array<Int> = geometry.index.array;
        var uvAttribute = geometry.attributes.uv;

        var face:Array<Int> = [];
        var uvs:Array<Vector2> = [new Vector2(), new Vector2(), new Vector2()];

        if (index != null) {
            // indexed geometry
            for (i in 0...(index.length / 3)) {
                face[0] = index[i * 3];
                face[1] = index[i * 3 + 1];
                face[2] = index[i * 3 + 2];

                uvs[0].fromBufferAttribute(uvAttribute, face[0]);
                uvs[1].fromBufferAttribute(uvAttribute, face[1]);
                uvs[2].fromBufferAttribute(uvAttribute, face[2]);

                processFace(face, uvs, i);
            }
        } else {
            // non-indexed geometry
            for (i in 0...(uvAttribute.array.length / 2)) {
                face[0] = i * 2;
                face[1] = i * 2 + 1;
                face[2] = i * 2 + 2;

                uvs[0].fromBufferAttribute(uvAttribute, face[0]);
                uvs[1].fromBufferAttribute(uvAttribute, face[1]);
                uvs[2].fromBufferAttribute(uvAttribute, face[2]);

                processFace(face, uvs, i);
            }
        }

        return canvas;

        function processFace(face:Array<Int>, uvs:Array<Vector2>, index:Int) {
            // draw contour of face
            ctx.beginPath();
            var a:Vector2 = new Vector2();
            for (j in 0...uvs.length) {
                var uv:Vector2 = uvs[j];
                a.x += uv.x;
                a.y += uv.y;
                if (j == 0) {
                    ctx.moveTo(uv.x * (size - 2) + 0.5, (1 - uv.y) * (size - 2) + 0.5);
                } else {
                    ctx.lineTo(uv.x * (size - 2) + 0.5, (1 - uv.y) * (size - 2) + 0.5);
                }
            }
            ctx.closePath();
            ctx.stroke();

            // calculate center of face
            a.divideScalar(uvs.length);

            // label the face number
            ctx.font = "18px Arial";
            ctx.fillStyle = "rgb(63, 63, 63)";
            ctx.textAlign = "center";
            ctx.fillText(Std.string(index), a.x * size, (1 - a.y) * size);
            if (a.x > 0.95) {
                // wrap x
                ctx.fillText(Std.string(index), (a.x % 1) * size, (1 - a.y) * size);
            }

            // label uv edge orders
            ctx.font = "12px Arial";
            ctx.fillStyle = "rgb(191, 191, 191)";
            for (j in 0...uvs.length) {
                var uv:Vector2 = uvs[j];
                var b:Vector2 = new Vector2(a.x + uv.x, a.y + uv.y);
                b.divideScalar(2);
                var vnum:Int = face[j];
                ctx.fillText("abc"[j] + Std.string(vnum), b.x * size, (1 - b.y) * size);
                if (b.x > 0.95) {
                    // wrap x
                    ctx.fillText("abc"[j] + Std.string(vnum), (b.x % 1) * size, (1 - b.y) * size);
                }
            }
        }
    }
}