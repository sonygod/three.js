package three.js.src.renderers.shaders.ShaderLib;

@:glsl(vertex)
extern class Vertex {
    @:glsl(varying)
    public var vWorldDirection:Vec3;

    @:glsl(include)
    public var common:Common;

    @:glsl(main)
    public function main():Void {
        vWorldDirection = transformDirection(position, modelMatrix);

        @:glsl(include)
        begin_vertex();

        @:glsl(include)
        project_vertex();
    }
}

@:glsl(fragment)
extern class Fragment {
    @:glsl(uniform)
    public var tEquirect:Sampler2D;

    @:glsl(varying)
    public var vWorldDirection:Vec3;

    @:glsl(include)
    public var common:Common;

    @:glsl(main)
    public function main():Void {
        var direction:Vec3 = normalize(vWorldDirection);

        var sampleUV:Vec2 = equirectUv(direction);

        gl_FragColor = texture2D(tEquirect, sampleUV);

        @:glsl(include)
        tonemapping_fragment();

        @:glsl(include)
        colorspace_fragment();
    }
}