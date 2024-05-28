import openfl.display.DisplayObject;
import openfl.display.DisplayObjectContainer;
import openfl.display.Sprite;
import openfl.display3D.Context3D;
import openfl.display3D.IndexBuffer3D;
import openfl.display3D.Program3D;
import openfl.display3D.VertexBuffer3D;
import openfl.display3D.textures.TextureBase;
import openfl.events.EventDispatcher;
import openfl.events.IEventDispatcher;
import openfl.utils.ByteArrayData;
import openfl.utils.IDataInput;
import openfl.utils.IDataOutput;

class BlinnPhongMaterial {
    public var diffuseColor:Float;
    public var specularColor:Float;
    public var specularShininess:Float;
    public var specularStrength:Float;
}

class ShaderCode {
    public static var blinnPhong:String = null;
    public function new() {
        blinnPhong = "
            BlinnPhongMaterial material;
            material.diffuseColor = diffuseColor.rgb;
            material.specularColor = specular;
            material.specFreq = shininess;
            material.specularStrength = specularStrength;
        ";
    }
}