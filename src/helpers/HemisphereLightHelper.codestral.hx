import three.math.Vector3;
import three.math.Color;
import three.core.Object3D;
import three.objects.Mesh;
import three.materials.MeshBasicMaterial;
import three.geometries.OctahedronGeometry;
import three.core.BufferAttribute;

class HemisphereLightHelper extends Object3D {

    private var _vector:Vector3 = new Vector3();
    private var _color1:Color = new Color();
    private var _color2:Color = new Color();

    public var light:Dynamic;
    public var color:Int;
    public var material:MeshBasicMaterial;

    public function new(light:Dynamic, size:Float, color:Int) {
        super();

        this.light = light;
        this.matrix = light.matrixWorld;
        this.matrixAutoUpdate = false;
        this.color = color;
        this.type = 'HemisphereLightHelper';

        var geometry:OctahedronGeometry = new OctahedronGeometry(size);
        geometry.rotateY(Math.PI * 0.5);

        this.material = new MeshBasicMaterial({
            wireframe: true,
            fog: false,
            toneMapped: false
        });

        if (this.color == null) {
            this.material.vertexColors = true;
        }

        var position = geometry.getAttribute('position');
        var colors:Array<Float> = new Array<Float>(position.count * 3);
        geometry.setAttribute('color', new BufferAttribute(colors, 3));

        this.add(new Mesh(geometry, this.material));
        this.update();
    }

    public function dispose():Void {
        this.children[0].geometry.dispose();
        this.children[0].material.dispose();
    }

    public function update():Void {
        var mesh:Mesh = this.children[0];

        if (this.color != null) {
            this.material.color.set(this.color);
        } else {
            var colors = mesh.geometry.getAttribute('color');

            _color1.copy(this.light.color);
            _color2.copy(this.light.groundColor);

            for (var i:Int = 0; i < colors.count; i++) {
                var color:Color = (i < (colors.count / 2)) ? _color1 : _color2;
                colors.setXYZ(i, color.r, color.g, color.b);
            }

            colors.needsUpdate = true;
        }

        this.light.updateWorldMatrix(true, false);
        mesh.lookAt(_vector.setFromMatrixPosition(this.light.matrixWorld).negate());
    }
}