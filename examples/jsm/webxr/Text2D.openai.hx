package three.js.examples.jsm.webxr;

import three.js.*;

class Text2D {
  public static function createText(message:String, height:Float) {
    var canvas = js.html.CanvasElement.create("canvas");
    var context:js.html.CanvasRenderingContext2D = canvas.getContext("2d");
    var metrics:js.html.TextMetrics;
    var textHeight = 100;
    context.font = 'normal ' + textHeight + 'px Arial';
    metrics = context.measureText(message);
    var textWidth = metrics.width;
    canvas.width = Std.int(textWidth);
    canvas.height = Std.int(textHeight);
    context.font = 'normal ' + textHeight + 'px Arial';
    context.textAlign = 'center';
    context.textBaseline = 'middle';
    context.fillStyle = '#ffffff';
    context.fillText(message, textWidth / 2, textHeight / 2);

    var texture = new three.Texture(canvas);
    texture.needsUpdate = true;

    var material = new three.MeshBasicMaterial({
      color: 0xffffff,
      side: three.DoubleSide,
      map: texture,
      transparent: true,
    });
    var geometry = new three.PlaneGeometry(
      (height * textWidth) / textHeight,
      height
    );
    var plane = new three.Mesh(geometry, material);
    return plane;
  }
}