import openfl.display.DisplayObject;
import openfl.display.BitmapData;
import openfl.display.Shader;
import openfl.display.ShaderParameter;

class MyShader extends Shader {
    public function new() {
        super();
        init();
    }

    private function init() {
        // GLSL 代码
        var code = "
            float G_BlinnPhong_Implicit() {
                return 0.25;
            }

            float D_BlinnPhong(float shininess, float dotNH) {
                return ${RECIPROCAL_PI} * (shininess * 0.5 + 1.0) * pow(dotNH, shininess);
            }

            vec3 BRDF_BlinnPhong(vec3 lightDir, vec3 viewDir, vec3 normal, vec3 specularColor, float shininess) {
                vec3 halfDir = normalize(lightDir + viewDir);
                float dotNH = saturate(dot(normal, halfDir));
                float dotVH = saturate(dot(viewDir, halfDir));
                vec3 F = F_Schlick(specularColor, 1.0, dotVH);
                float G = G_BlinnPhong_Implicit();
                float D = D_BlinnPhong(shininess, dotNH);
                return F * (G * D);
            }
        ";

        // 编译并加载Shader
        load(code);

        // 创建Shader参数
        var specularColor = new ShaderParameter("specularColor", null);
        var shininess = new ShaderParameter("shininess", null);

        // 将参数添加到Shader中
        parameters.push(specularColor);
        parameters.push(shininess);
    }
}

// 使用Shader
var shader = new MyShader();
var bitmapData = new BitmapData(400, 300, true, 0xFFFFFFFF);
var displayObject = new DisplayObject();

displayObject.shader = shader;
displayObject.bitmapData = bitmapData;

// 设置Shader参数
shader.specularColor.value = 0xFF0000;
shader.shininess.value = 32.0;