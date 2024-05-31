import three.js.extras.core.Vector2;

/**
 * Convolution shader
 * ported from o3d sample to WebGL / GLSL
 */

class ConvolutionShader {

    static var name:String = 'ConvolutionShader';

    static var defines:Map<String, String> = {
        'KERNEL_SIZE_FLOAT': '25.0',
        'KERNEL_SIZE_INT': '25'
    };

    static var uniforms:Map<String, Dynamic> = {
        'tDiffuse': { value: null },
        'uImageIncrement': { value: new Vector2( 0.001953125, 0.0 ) },
        'cKernel': { value: [] }
    };

    static var vertexShader:String =
        "uniform vec2 uImageIncrement;\n\n" +
        "varying vec2 vUv;\n\n" +
        "void main() {\n" +
        "    vUv = uv - ( ( KERNEL_SIZE_FLOAT - 1.0 ) / 2.0 ) * uImageIncrement;\n" +
        "    gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );\n" +
        "}\n";

    static var fragmentShader:String =
        "uniform float cKernel[ KERNEL_SIZE_INT ];\n\n" +
        "uniform sampler2D tDiffuse;\n" +
        "uniform vec2 uImageIncrement;\n\n" +
        "varying vec2 vUv;\n\n" +
        "void main() {\n" +
        "    vec2 imageCoord = vUv;\n" +
        "    vec4 sum = vec4( 0.0, 0.0, 0.0, 0.0 );\n\n" +
        "    for( int i = 0; i < KERNEL_SIZE_INT; i ++ ) {\n" +
        "        sum += texture2D( tDiffuse, imageCoord ) * cKernel[ i ];\n" +
        "        imageCoord += uImageIncrement;\n" +
        "    }\n\n" +
        "    gl_FragColor = sum;\n" +
        "}\n";

    static function buildKernel( sigma:Float ) {

        // We lop off the sqrt(2 * pi) * sigma term, since we're going to normalize anyway.

        const kMaxKernelSize:Int = 25;
        var kernelSize:Int = 2 * Math.ceil( sigma * 3.0 ) + 1;

        if ( kernelSize > kMaxKernelSize ) kernelSize = kMaxKernelSize;

        var halfWidth:Float = ( kernelSize - 1 ) * 0.5;

        var values:Array<Float> = new Array();
        var sum:Float = 0.0;
        for ( i in 0...kernelSize ) {

            values[i] = gauss( i - halfWidth, sigma );
            sum += values[i];

        }

        // normalize the kernel

        for ( i in 0...kernelSize ) values[i] /= sum;

        return values;

    }

    static function gauss( x:Float, sigma:Float ) {

        return Math.exp( - ( x * x ) / ( 2.0 * sigma * sigma ) );

    }

}