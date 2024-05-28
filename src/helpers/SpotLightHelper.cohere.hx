import openfl.geom.Vector3D;
import openfl.display3D.IndexBuffer3D;
import openfl.display3D.VertexBuffer3D;
import openfl.display3D.Context3DProgramType;
import openfl.display3D.Context3DVertexBufferFormat;
import openfl.display3D.Context3D;
import openfl.display3D.Program3D;
import openfl.display3D.Context3DTextureFormat;
import openfl.display3D.textures.TextureBase;

class SpotLightHelper extends Object3D
{
    public var light:Object3D;
    public var color:Float;
    public var cone:LineSegments;
    public var matrixAutoUpdate:Bool;
    public var matrix:Matrix4;
    public var matrixWorld:Matrix4;
    public var type:String;

    public function new(light:Object3D, color:Float)
    {
        super();

        this.light = light;
        this.matrixAutoUpdate = false;
        this.color = color;
        this.type = 'SpotLightHelper';

        var geometry = new BufferGeometry();
        var positions = [0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1, 0, 0, 0, -1, 0, 1, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, -1, 1];

        for (i in 0...32)
        {
            var p1 = i / 32 * Math.PI * 2;
            var p2 = (i + 1) / 32 * Math.PI * 2;
            positions.push(Math.cos(p1));
            positions.push(Math.sin(p1));
            positions.push(1);
            positions.push(Math.cos(p2));
            positions.push(Math.sin(p2));
            positions.push(1);
        }

        geometry.addAttribute('position', new Float32BufferAttribute(positions, 3));

        var material = new LineBasicMaterial({ fog: false, toneMapped: false });

        this.cone = new LineSegments(geometry, material);
        this.add(this.cone);

        this.update();
    }

    public function dispose():Void
    {
        this.cone.geometry.dispose();
        this.cone.material.dispose();
    }

    public function update():Void
    {
        this.light.updateWorldMatrix(true, false);
        this.light.target.updateWorldMatrix(true, false);

        if (this.parent != null)
        {
            this.parent.updateWorldMatrix(true);
            this.matrix.copy(this.parent.matrixWorld).invert().multiply(this.light.matrixWorld);
        }
        else
        {
            this.matrix.copy(this.light.matrixWorld);
        }

        this.matrixWorld.copy(this.light.matrixWorld);

        var coneLength = (if (this.light.distance != null) this.light.distance else 1000);
        var coneWidth = coneLength * Math.tan(this.light.angle);

        this.cone.scale.set(coneWidth, coneWidth, coneLength);

        var _vector:Vector3D = Vector3D_create();
        _vector.setFromMatrixPosition(this.light.target.matrixWorld);
        this.cone.lookAt(_vector);

        if (this.color != null)
        {
            this.cone.material.color.set(this.color);
        }
        else
        {
            this.cone.material.color.copy(this.light.color);
        }
    }
}