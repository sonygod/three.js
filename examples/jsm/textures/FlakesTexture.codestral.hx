import js.Browser;
import js.html.CanvasElement;
import js.html.CanvasRenderingContext2D;

class FlakesTexture {
    public function new(width:Int = 512, height:Int = 512) {
        var canvas:CanvasElement = Browser.document.createElement('canvas').cast();
        canvas.width = width;
        canvas.height = height;

        var context:CanvasRenderingContext2D = canvas.getContext('2d').cast();
        context.fillStyle = 'rgb(127,127,255)';
        context.fillRect(0, 0, width, height);

        for (var i:Int = 0; i < 4000; i++) {
            var x:Float = Math.random() * width;
            var y:Float = Math.random() * height;
            var r:Float = Math.random() * 3 + 3;

            var nx:Float = Math.random() * 2 - 1;
            var ny:Float = Math.random() * 2 - 1;
            var nz:Float = 1.5;

            var l:Float = Math.sqrt(nx * nx + ny * ny + nz * nz);

            nx /= l; ny /= l; nz /= l;

            context.fillStyle = 'rgb(' + ((nx * 127) + 127) + ',' + ((ny * 127) + 127) + ',' + (nz * 255) + ')';
            context.beginPath();
            context.arc(x, y, r, 0, Math.PI * 2);
            context.fill();
        }

        return canvas;
    }
}