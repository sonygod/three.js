import js.html.CanvasElement;
import js.html.CanvasRenderingContext2D;
import js.html.HTMLDocument;
import haxe.ds.Vector;

class UVsDebug {
    private static function processFace(ctx:CanvasRenderingContext2D, width:Int, height:Int, face:Array<Int>, uvs:Array<Vector<Float>>, index:Int) {
        var a = new Vector<Float>([0.0, 0.0]);
        var b = new Vector<Float>([0.0, 0.0]);

        ctx.beginPath();

        for (var j = 0; j < uvs.length; j++) {
            var uv = uvs[j];

            a.x += uv.x;
            a.y += uv.y;

            if (j == 0) {
                ctx.moveTo(uv.x * (width - 2) + 0.5, (1 - uv.y) * (height - 2) + 0.5);
            } else {
                ctx.lineTo(uv.x * (width - 2) + 0.5, (1 - uv.y) * (height - 2) + 0.5);
            }
        }

        ctx.closePath();
        ctx.stroke();

        a.x /= uvs.length;
        a.y /= uvs.length;

        ctx.font = '18px Arial';
        ctx.fillStyle = 'rgb(63, 63, 63)';
        ctx.fillText(index.toString(), a.x * width, (1 - a.y) * height);

        if (a.x > 0.95) {
            ctx.fillText(index.toString(), (a.x % 1) * width, (1 - a.y) * height);
        }

        ctx.font = '12px Arial';
        ctx.fillStyle = 'rgb(191, 191, 191)';

        for (j = 0; j < uvs.length; j++) {
            uv = uvs[j];
            b.x = (a.x + uv.x) / 2;
            b.y = (a.y + uv.y) / 2;

            var vnum = face[j];
            ctx.fillText("abc".charAt(j) + vnum, b.x * width, (1 - b.y) * height);

            if (b.x > 0.95) {
                ctx.fillText("abc".charAt(j) + vnum, (b.x % 1) * width, (1 - b.y) * height);
            }
        }
    }

    public static function UVsDebug(geometry:Dynamic, size:Int = 1024):CanvasElement {
        var canvas = HTMLDocument.document.createElement('canvas');
        var width = size;
        var height = size;
        canvas.width = width;
        canvas.height = height;

        var ctx = canvas.getContext('2d');
        ctx.lineWidth = 1;
        ctx.strokeStyle = 'rgb(63, 63, 63)';
        ctx.textAlign = 'center';

        ctx.fillStyle = 'rgb(255, 255, 255)';
        ctx.fillRect(0, 0, width, height);

        var index = geometry.index;
        var uvAttribute = geometry.attributes.uv;

        var uvs = [
            new Vector<Float>([0.0, 0.0]),
            new Vector<Float>([0.0, 0.0]),
            new Vector<Float>([0.0, 0.0])
        ];

        var face = [];

        if (index != null) {
            for (var i = 0; i < index.count; i += 3) {
                face[0] = index.getX(i);
                face[1] = index.getX(i + 1);
                face[2] = index.getX(i + 2);

                uvs[0].x = uvAttribute.getX(face[0]);
                uvs[0].y = uvAttribute.getY(face[0]);
                uvs[1].x = uvAttribute.getX(face[1]);
                uvs[1].y = uvAttribute.getY(face[1]);
                uvs[2].x = uvAttribute.getX(face[2]);
                uvs[2].y = uvAttribute.getY(face[2]);

                processFace(ctx, width, height, face, uvs, i / 3);
            }
        } else {
            for (i = 0; i < uvAttribute.count; i += 3) {
                face[0] = i;
                face[1] = i + 1;
                face[2] = i + 2;

                uvs[0].x = uvAttribute.getX(face[0]);
                uvs[0].y = uvAttribute.getY(face[0]);
                uvs[1].x = uvAttribute.getX(face[1]);
                uvs[1].y = uvAttribute.getY(face[1]);
                uvs[2].x = uvAttribute.getX(face[2]);
                uvs[2].y = uvAttribute.getY(face[2]);

                processFace(ctx, width, height, face, uvs, i / 3);
            }
        }

        return canvas;
    }
}