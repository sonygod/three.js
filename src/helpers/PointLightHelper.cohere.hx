import openfl.display.DisplayObject;
import openfl.display.IBitmapDrawable;
import openfl.display3D.Context3D;
import openfl.display3D.IndexBuffer3D;
import openfl.display3D.VertexBuffer3D;
import openfl.display3D.textures.TextureBase;
import openfl.events.EventDispatcher;
import openfl.events.IEventDispatcher;
import openfl.geom.Matrix3D;

class PointLightHelper extends Mesh
{
    public var light:Mesh;
    public var sphereSize:Float;
    public var color:Float;

    public function new(light:Mesh, sphereSize:Float, color:Float)
    {
        super();

        this.light = light;
        this.sphereSize = sphereSize;
        this.color = color;

        var geometry = new SphereGeometry(sphereSize, 4, 2);
        var material = new MeshBasicMaterial({ wireframe: true, fog: false, toneMapped: false });

        this.geometry = geometry;
        this.material = material;

        this.type = "PointLightHelper";

        this.matrix = light.matrixWorld;
        this.matrixAutoUpdate = false;

        this.update();
    }

    public function dispose():Void
    {
        geometry.dispose();
        material.dispose();
    }

    public function update():Void
    {
        light.updateWorldMatrix(true, false);

        if (color != null)
        {
            material.color.set(color);
        }
        else
        {
            material.color.copy(light.color);
        }
    }
}

class SphereGeometry
{
    public function new(sphereSize:Float, segmentsWidth:Int, segmentsHeight:Int)
    {

    }
}

class MeshBasicMaterial
{
    public function new(args:Dynamic)
    {

    }
}

class Mesh extends DisplayObject implements IBitmapDrawable
{
    public function new()
    {
        super();
    }

    public var geometry:Dynamic;
    public var material:Dynamic;
    public var matrix:Matrix3D;
    public var matrixAutoUpdate:Bool;
}