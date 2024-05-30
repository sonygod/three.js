import js.three.Texture;
import js.three.MeshBasicMaterial;
import js.three.PlaneGeometry;
import js.three.Mesh;

function createText(message:String, height:Int) -> Mesh {
    var canvas = js.browser.window.document.createElement('canvas');
    var context = canvas.getContext2d();
    var metrics = null;
    var textHeight = 100;
    context.font = 'normal ' + textHeight + 'px Arial';
    metrics = context.measureText(message);
    var textWidth = Std.int(metrics.width);
    canvas.width = textWidth;
    canvas.height = textHeight;
    context.font = 'normal ' + textHeight + 'px Arial';
    context.textAlign = 'center';
    context.textBaseline = 'middle';
    context.fillStyle = '#ffffff';
    context.fillText(message, textWidth / 2, textHeight / 2);

    var texture = new Texture(canvas);
    texture.needsUpdate = true;

    var material = new MeshBasicMaterial({
        color: 0xffffff,
        side: js.three.DoubleSide.DoubleSide,
        map: texture,
        transparent: true
    });
    var geometry = new PlaneGeometry((height * textWidth) / textHeight, height);
    var plane = new Mesh(geometry, material);
    return plane;
}