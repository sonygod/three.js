package;

import openfl.display.DisplayObject;
import openfl.display.DisplayObjectContainer;
import openfl.display.Sprite;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.Graphics;
import openfl.display.Shader;
import openfl.display.ShaderInput;
import openfl.display.ShaderParameter;
import openfl.display.BlendMode;
import openfl.display3D.Context3D;
import openfl.display3D.Context3DProgramType;
import openfl.display3D.Context3DTextureFormat;
import openfl.display3D.IndexBuffer3D;
import openfl.display3D.VertexBuffer3D;
import openfl.display3D.textures.TextureBase;
import openfl.events.Event;
import openfl.events.EventDispatcher;
import openfl.geom.ColorTransform;
import openfl.geom.Matrix;
import openfl.geom.Rectangle;
import openfl.utils.ByteArray;
import openfl.utils.IDataInput;
import openfl.utils.IDataOutput;

class Main extends Sprite {
    public function new() {
        super();

        if (openfl.Lib.current.stage3D) {
            var stage3D:openfl.display3D.Stage3D = openfl.Lib.current.stage3D;
            var context:Context3D = stage3D.context3D;

            var vertexShader:String = "
                varying vec3 vViewPosition;
                void main() {
                    vViewPosition = -mvPosition.xyz;
                    gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
                }
            ";

            var fragmentShader:String = "
                uniform vec3 diffuse;
                uniform vec3 emissive;
                uniform vec3 specular;
                uniform float shininess;
                uniform float opacity;
                void main() {
                    vec4 diffuseColor = vec4(diffuse, opacity);
                    vec3 outgoingLight = emissive + specular;
                    gl_FragColor = diffuseColor * vec4(outgoingLight, 1.0);
                }
            ";

            var program:Context3DProgram = context.createProgram();
            program.upload(Context3DProgramType.VERTEX, vertexShader);
            program.upload(Context3DProgramType.FRAGMENT, fragmentShader);

            var vertexBuffer:VertexBuffer3D = context.createVertexBuffer(4, 3);
            vertexBuffer.uploadFromVector([1.0, 1.0, 0.0, -1.0, 1.0, 0.0, -1.0, -1.0, 0.0, 1.0, -1.0, 0.0], 0, 4);

            var indexBuffer:IndexBuffer3D = context.createIndexBuffer(6);
            indexBuffer.uploadFromVector([0, 1, 2, 2, 3, 0], 0, 6);

            var texture:TextureBase = context.createTexture(1, 1, Context3DTextureFormat.BGRA, false);
            var bitmapData:BitmapData = new BitmapData(1, 1, true, 0x000000FF);
            texture.uploadFromBitmapData(bitmapData, 0, 0, 0);

            var shader:Shader = new Shader(context, program, ["diffuse", "emissive", "specular", "shininess", "opacity"]);
            shader.addEventListener(Event.COMPLETE, onShaderComplete);
            shader.addEventListener(Event.INIT, onShaderInit);

            shader.dispose();
        }
    }

    function onShaderInit(e:Event):Void {
        trace("Shader init");
    }

    function onShaderComplete(e:Event):Void {
        trace("Shader complete");
    }
}

var main:Main = new Main();
addChild(main);