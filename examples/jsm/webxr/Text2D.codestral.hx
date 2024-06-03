import js.html.Canvas;
import js.html.CanvasRenderingContext2D;
import js.html.HTMLCanvasElement;
import js.html.HTMLElement;
import js.html.Window;
import three.Texture;
import three.MeshBasicMaterial;
import three.PlaneGeometry;
import three.Mesh;
import three.DoubleSide;

class Text2D {

    static function createText(message: String, height: Float): Mesh {
        var canvas: Canvas = Window.document.createElement('canvas');
        var context: Context2D = canvas.getContext('2d');
        var metrics: TextMetrics = null;
        var textHeight: Float = 100;
        context.font = 'normal ' + textHeight + 'px Arial';
        metrics = context.measureText(message);
        var textWidth: Float = metrics.width;
        canvas.width = textWidth;
        canvas.height = textHeight;
        context.font = 'normal ' + textHeight + 'px Arial';
        context.textAlign = 'center';
        context.textBaseline = 'middle';
        context.fillStyle = '#ffffff';
        context.fillText(message, textWidth / 2, textHeight / 2);

        var texture: Texture = new Texture(canvas);
        texture.needsUpdate = true;

        var material: MeshBasicMaterial = new MeshBasicMaterial({
            color: 0xffffff,
            side: DoubleSide,
            map: texture,
            transparent: true
        });

        var geometry: PlaneGeometry = new PlaneGeometry(
            (height * textWidth) / textHeight,
            height
        );

        var plane: Mesh = new Mesh(geometry, material);
        return plane;
    }
}