import three.core.BufferGeometry;
import three.core.Float32BufferAttribute;
import three.materials.LineBasicMaterial;
import three.math.Color;
import three.objects.LineSegments;

class PolarGridHelper extends LineSegments {
  public var radius:Float;
  public var sectors:Int;
  public var rings:Int;
  public var divisions:Int;
  public var color1:Color;
  public var color2:Color;

  public function new(radius:Float = 10, sectors:Int = 16, rings:Int = 8, divisions:Int = 64, color1:Int = 0x444444, color2:Int = 0x888888) {
    this.radius = radius;
    this.sectors = sectors;
    this.rings = rings;
    this.divisions = divisions;
    this.color1 = new Color(color1);
    this.color2 = new Color(color2);

    var vertices:Array<Float> = [];
    var colors:Array<Float> = [];

    // create the sectors
    if (sectors > 1) {
      for (i in 0...sectors) {
        var v = (i / sectors) * (Math.PI * 2);
        var x = Math.sin(v) * radius;
        var z = Math.cos(v) * radius;

        vertices.push(0, 0, 0);
        vertices.push(x, 0, z);

        var color = (i & 1) == 1 ? color1 : color2;

        colors.push(color.r, color.g, color.b);
        colors.push(color.r, color.g, color.b);
      }
    }

    // create the rings
    for (i in 0...rings) {
      var color = (i & 1) == 1 ? color1 : color2;
      var r = radius - (radius / rings * i);

      for (j in 0...divisions) {
        // first vertex
        var v = (j / divisions) * (Math.PI * 2);
        var x = Math.sin(v) * r;
        var z = Math.cos(v) * r;

        vertices.push(x, 0, z);
        colors.push(color.r, color.g, color.b);

        // second vertex
        v = ((j + 1) / divisions) * (Math.PI * 2);
        x = Math.sin(v) * r;
        z = Math.cos(v) * r;

        vertices.push(x, 0, z);
        colors.push(color.r, color.g, color.b);
      }
    }

    var geometry = new BufferGeometry();
    geometry.setAttribute('position', new Float32BufferAttribute(vertices, 3));
    geometry.setAttribute('color', new Float32BufferAttribute(colors, 3));

    var material = new LineBasicMaterial({vertexColors: true, toneMapped: false});

    super(geometry, material);
    this.type = 'PolarGridHelper';
  }

  public function dispose():Void {
    geometry.dispose();
    material.dispose();
  }
}