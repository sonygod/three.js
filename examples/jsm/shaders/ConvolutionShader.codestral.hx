import three.Vector2;

class ConvolutionShader {
    public static var name:String = "ConvolutionShader";

    public static var defines:haxe.ds.StringMap<String> = new haxe.ds.StringMap<String>();
    public static var uniforms:haxe.ds.StringMap<Dynamic> = new haxe.ds.StringMap<Dynamic>();

    public static var vertexShader:String;
    public static var fragmentShader:String;

    public static function new() {
        defines.set('KERNEL_SIZE_FLOAT', '25.0');
        defines.set('KERNEL_SIZE_INT', '25');

        uniforms.set('tDiffuse', { value: null });
        uniforms.set('uImageIncrement', { value: new Vector2(0.001953125, 0.0) });
        uniforms.set('cKernel', { value: [] });

        vertexShader = /* glsl */`
        // Your vertex shader code here
        `;

        fragmentShader = /* glsl */`
        // Your fragment shader code here
        `;
    }

    public static function buildKernel(sigma:Float):Array<Float> {
        // Your buildKernel function here
        return [];
    }

    private static function gauss(x:Float, sigma:Float):Float {
        // Your gauss function here
        return 0.0;
    }
}