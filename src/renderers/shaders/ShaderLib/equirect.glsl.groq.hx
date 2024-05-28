package three.js.src.renderers.shaders.ShaderLib;

// Vertex shader
class EquirectVertexShader {
    public var vWorldDirection:Vec3;

    public function new() {}

    public function main(position:Vec3, modelMatrix:Mat4):Void {
        vWorldDirection = transformDirection(position, modelMatrix);
        beginVertex();
        projectVertex();
    }
}

// Fragment shader
class EquirectFragmentShader {
    public var tEquirect:Texture;
    public var vWorldDirection:Vec3;

    public function new() {}

    public function main():Void {
        var direction:Vec3 = normalize(vWorldDirection);
        var sampleUV:Vec2 = equirectUv(direction);
        var color:Vec4 = texture2D(tEquirect, sampleUV);
        toneMappingFragment(color);
        colorSpaceFragment(color);
        gl_FragColor = color;
    }
}