package three.js.examples.jsw.WebXR;

import js.html.CanvasElement;
import js.html.CanvasRenderingContext2D;
import three.js.Three;

class Text2D {
    public static function createText(message:String, height:Float):three.js.Mesh {
        var canvas:CanvasElement = js.Browser.document.createElement("canvas");
        var context:CanvasRenderingContext2D = canvas.getContext("2d");
        var metrics:Dynamic = null;
        var textHeight:Float = 100;
        context.font = 'normal ' + textHeight + 'px Arial';
        metrics = context.measureText(message);
        var textWidth:Float = metrics.width;
        canvas.width = Std.int(textWidth);
        canvas.height = Std.int(textHeight);
        context.font = 'normal ' + textHeight + 'px Arial';
        context.textAlign = 'center';
        context.textBaseline = 'middle';
        context.fillStyle = '#ffffff';
        context.fillText(message, textWidth / 2, textHeight / 2);

        var texture:three.js.Texture = new three.js.Texture(canvas);
        texture.needsUpdate = true;

        var material:three.js.MeshBasicMaterial = new three.js.MeshBasicMaterial({
            color: 0xffffff,
            side: three.js.Side.DoubleSide,
            map: texture,
            transparent: true,
        });
        var geometry:three.js.PlaneGeometry = new three.js.PlaneGeometry(
            (height * textWidth) / textHeight,
            height
        );
        var plane:three.js.Mesh = new three.js.Mesh(geometry, material);
        return plane;
    }
}