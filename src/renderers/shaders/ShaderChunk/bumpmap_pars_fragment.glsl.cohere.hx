import openfl.display.DisplayObject;
import openfl.display3D.Context3D;
import openfl.display3D.IndexBuffer3D;
import openfl.display3D.VertexBuffer3D;
import openfl.display3D.textures.TextureBase;
import openfl.events.EventDispatcher;

class MyShader extends Shader {
    public var bumpMap:TextureBase;
    public var bumpScale:Float;

    public function new(context:Context3D) {
        super(context, Context3DProgramType.FRAGMENT);

        // ... 其它初始化代码 ...

        // 添加自定义变量
        addFragmentVariable("bumpMap", Context3DVertexBufferFormat.SAMPLER2D);
        addFragmentVariable("bumpScale", Context3DVertexBufferFormat.FLOAT1);
    }

    public override function dispatch(pass:String, params:Array<Dynamic>) : DisplayObject {
        super.dispatch(pass, params);

        // ... 其它调度代码 ...

        // 更新自定义变量
        setFragmentTexture("bumpMap", bumpMap);
        setFragmentConstant("bumpScale", bumpScale);
    }

    public override function getAGLSLSource(target:String, registerIndex:Int) : String {
        var glslSource = "";

        if (target == Context3DProgramTarget.FRAGMENT) {
            glslSource += "#ifdef USE_BUMPMAP\n";
            glslSource += "uniform sampler2D bumpMap;\n";
            glslSource += "uniform float bumpScale;\n";
            glslSource += "\n";
            glslSource += "// Bump Mapping Unparametrized Surfaces on the GPU by Morten S. Mikkelsen\n";
            glslSource += "// https://mmikk.github.io/papers3d/mm_sfgrad_bump.pdf\n";
            glslSource += "\n";
            glslSource += "// Evaluate the derivative of the height w.r.t. screen-space using forward differencing (listing 2)\n";
            glslSource += "\n";
            glslSource += "vec2 dHdxy_fwd() {\n";
            glslSource += "    vec2 dSTdx = dFdx(vBumpMapUv.xy);\n";
            glslSource += "    vec2 dSTdy = dFdy(vBumpMapUv.xy);\n";
            glslSource += "    float Hll = bumpScale * texture2D(bumpMap, vBumpMapUv).r;\n";
            glslSource += "    float dBx = bumpScale * texture2D(bumpMap, vBumpMapUv + dSTdx).r - Hll;\n";
            glslSource += "    float dBy = bumpScale * texture2D(bumpMap, vBumpMapUv + dSTdy).r - Hll;\n";
            glslSource += "    return vec2(dBx, dBy);\n";
            glslSource += "}\n";
            glslSource += "\n";
            glslSource += "vec3 perturbNormalArb(vec3 surf_pos, vec3 surf_norm, vec2 dHdxy, float faceDirection) {\n";
            glslSource += "    // normalize is done to ensure that the bump map looks the same regardless of the texture's scale\n";
            glslSource += "    vec3 vSigmaX = normalize(dFdx(surf_pos.xyz));\n";
            glslSource += "    vec3 vSigmaY = normalize(dFdy(surf_pos.xyz));\n";
            glslSource += "    vec3 vN = surf_norm; // normalized\n";
            glslSource += "    vec3 R1 = cross(vSigmaY, vN);\n";
            glslSource += "    vec3 R2 = cross(vN, vSigmaX);\n";
            glslSource += "    float fDet = dot(vSigmaX, R1) * faceDirection;\n";
            glslSource += "    vec3 vGrad = sign(fDet) * (dHdxy.x * R1 + dHdxy.y * R2);\n";
            glslSource += "    return normalize(abs(fDet) * vN - vGrad);\n";
            glslSource += "}\n";
            glslSource += "#endif\n";
        }

        return glslSource;
    }
}