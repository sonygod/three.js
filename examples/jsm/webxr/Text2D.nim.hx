import js.html.CanvasElement;
import js.html.CanvasRenderingContext2D;
import three.js.examples.jsm.webxr.Text2D;
import three.js.examples.jsm.webxr.Text2D.createText;
import three.js.Three;

class CreateText {
    public static function main() {
        var message:String = "Hello, World!";
        var height:Float = 100.0;
        var plane:three.js.examples.jsm.webxr.Text2D.createText = createText(message, height);
    }

    public static function createText(message:String, height:Float):three.js.examples.jsm.webxr.Text2D.createText {
        var canvas:CanvasElement = js.Browser.document.createElement('canvas');
        var context:CanvasRenderingContext2D = canvas.getContext('2d');
        var metrics:js.html.TextMetrics = null;
        var textHeight:Float = 100.0;
        context.font = 'normal ' + textHeight + 'px Arial';
        metrics = context.measureText(message);
        var textWidth:Float = metrics.width;
        canvas.width = textWidth;
        canvas.height = textHeight;
        context.font = 'normal ' + textHeight + 'px Arial';
        context.textAlign = 'center';
        context.textBaseline = 'middle';
        context.fillStyle = '#ffffff';
        context.fillText(message, textWidth / 2, textHeight / 2);

        var texture:three.js.examples.jsm.webxr.Text2D.createText = new three.js.examples.jsm.webxr.Text2D.createText(canvas);
        texture.needsUpdate = true;

        var material:three.js.examples.jsm.webxr.Text2D.createText = new three.js.examples.jsm.webxr.Text2D.createText({
            color: 0xffffff,
            side: three.js.examples.jsm.webxr.Text2D.createText.DoubleSide,
            map: texture,
            transparent: true,
        });
        var geometry:three.js.examples.jsm.webxr.Text2D.createText = new three.js.examples.jsm.webxr.Text2D.createText(
            (height * textWidth) / textHeight,
            height
        );
        var plane:three.js.examples.jsm.webxr.Text2D.createText = new three.js.examples.jsm.webxr.Text2D.createText(geometry, material);
        return plane;
    }
}