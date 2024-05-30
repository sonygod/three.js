import three.Vector2;

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

    static var vertexShader:String = `
        uniform vec2 uImageIncrement;
        varying vec2 vUv;
        void main() {
            vUv = uv - ( ( KERNEL_SIZE_FLOAT - 1.0 ) / 2.0 ) * uImageIncrement;
            gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
        }`;

    static var fragmentShader:String = `
        uniform float cKernel[ KERNEL_SIZE_INT ];
        uniform sampler2D tDiffuse;
        uniform vec2 uImageIncrement;
        varying vec2 vUv;
        void main() {
            vec2 imageCoord = vUv;
            vec4 sum = vec4( 0.0, 0.0, 0.0, 0.0 );
            for( int i = 0; i < KERNEL_SIZE_INT; i ++ ) {
                sum += texture2D( tDiffuse, imageCoord ) * cKernel[ i ];
                imageCoord += uImageIncrement;
            }
            gl_FragColor = sum;
        }`;

    static function buildKernel(sigma:Float):Array<Float> {
        const kMaxKernelSize:Int = 25;
        var kernelSize:Int = 2 * Math.ceil( sigma * 3.0 ) + 1;
        if ( kernelSize > kMaxKernelSize ) kernelSize = kMaxKernelSize;
        var halfWidth:Float = ( kernelSize - 1 ) * 0.5;
        var values:Array<Float> = new Array(kernelSize);
        var sum:Float = 0.0;
        for (i in 0...kernelSize) {
            values[i] = gauss(i - halfWidth, sigma);
            sum += values[i];
        }
        for (i in 0...kernelSize) values[i] /= sum;
        return values;
    }

    static function gauss(x:Float, sigma:Float):Float {
        return Math.exp( - ( x * x ) / ( 2.0 * sigma * sigma ) );
    }
}