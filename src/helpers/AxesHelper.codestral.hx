import three.objects.LineSegments;
import three.materials.LineBasicMaterial;
import three.core.BufferAttribute;
import three.core.BufferGeometry;
import three.math.Color;

class AxesHelper extends LineSegments {

    public function new(size:Float = 1) {
        super();

        var vertices:Array<Float> = [
            0, 0, 0, size, 0, 0,
            0, 0, 0, 0, size, 0,
            0, 0, 0, 0, 0, size
        ];

        var colors:Array<Float> = [
            1, 0, 0, 1, 0.6, 0,
            0, 1, 0, 0.6, 1, 0,
            0, 0, 1, 0, 0.6, 1
        ];

        var geometry:BufferGeometry = new BufferGeometry();
        geometry.setAttribute('position', new Float32BufferAttribute(vertices, 3));
        geometry.setAttribute('color', new Float32BufferAttribute(colors, 3));

        var material:LineBasicMaterial = new LineBasicMaterial({vertexColors: true, toneMapped: false});

        this.init(geometry, material);

        this.type = 'AxesHelper';
    }

    public function setColors(xAxisColor:Int, yAxisColor:Int, zAxisColor:Int):AxesHelper {
        var color:Color = new Color();
        var array:Array<Float> = this.geometry.attributes.get('color').array;

        color.set(xAxisColor);
        color.toArray(array, 0);
        color.toArray(array, 3);

        color.set(yAxisColor);
        color.toArray(array, 6);
        color.toArray(array, 9);

        color.set(zAxisColor);
        color.toArray(array, 12);
        color.toArray(array, 15);

        this.geometry.attributes.get('color').needsUpdate = true;

        return this;
    }

    public function dispose():Void {
        this.geometry.dispose();
        this.material.dispose();
    }
}