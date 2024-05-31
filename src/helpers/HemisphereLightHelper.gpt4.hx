import three.math.Vector3;
import three.math.Color;
import three.core.Object3D;
import three.objects.Mesh;
import three.materials.MeshBasicMaterial;
import three.geometries.OctahedronGeometry;
import three.core.BufferAttribute;

class HemisphereLightHelper extends Object3D {
    public var light:Dynamic;
    public var color:Color;
    public var material:MeshBasicMaterial;
    
    private static var _vector:Vector3 = new Vector3();
    private static var _color1:Color = new Color();
    private static var _color2:Color = new Color();

    public function new(light:Dynamic, size:Float, ?color:Color) {
        super();
        
        this.light = light;
        this.matrix = light.matrixWorld;
        this.matrixAutoUpdate = false;
        this.color = color;
        this.type = 'HemisphereLightHelper';

        var geometry = new OctahedronGeometry(size);
        geometry.rotateY(Math.PI * 0.5);

        this.material = new MeshBasicMaterial({
            wireframe: true,
            fog: false,
            toneMapped: false
        });

        if (this.color == null) this.material.vertexColors = true;

        var position = geometry.getAttribute('position');
        var colors = new Float32Array(position.count * 3);
        geometry.setAttribute('color', new BufferAttribute(colors, 3));

        this.add(new Mesh(geometry, this.material));

        this.update();
    }

    public function dispose() {
        this.children[0].geometry.dispose();
        this.children[0].material.dispose();
    }

    public function update() {
        var mesh = this.children[0];

        if (this.color != null) {
            this.material.color.set(this.color);
        } else {
            var colors = mesh.geometry.getAttribute('color');
            _color1.copy(this.light.color);
            _color2.copy(this.light.groundColor);

            for (i in 0...colors.count) {
                var color = (i < (colors.count / 2)) ? _color1 : _color2;
                colors.setXYZ(i, color.r, color.g, color.b);
            }

            colors.needsUpdate = true;
        }

        this.light.updateWorldMatrix(true, false);
        mesh.lookAt(_vector.setFromMatrixPosition(this.light.matrixWorld).negate());
    }
}