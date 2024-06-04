import three.Vector2;

class ConvolutionShader {
  public static var name:String = "ConvolutionShader";

  public static var defines:Map<String,String> = new Map<String,String>([
    "KERNEL_SIZE_FLOAT", "25.0",
    "KERNEL_SIZE_INT", "25",
  ]);

  public static var uniforms:Map<String,Dynamic> = new Map<String,Dynamic>([
    "tDiffuse", { value: null },
    "uImageIncrement", { value: new Vector2(0.001953125, 0.0) },
    "cKernel", { value: [] },
  ]);

  public static var vertexShader:String = /* glsl */`
    uniform vec2 uImageIncrement;

    varying vec2 vUv;

    void main() {
      vUv = uv - ((KERNEL_SIZE_FLOAT - 1.0) / 2.0) * uImageIncrement;
      gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
    }
  `;

  public static var fragmentShader:String = /* glsl */`
    uniform float cKernel[KERNEL_SIZE_INT];

    uniform sampler2D tDiffuse;
    uniform vec2 uImageIncrement;

    varying vec2 vUv;

    void main() {
      vec2 imageCoord = vUv;
      vec4 sum = vec4(0.0, 0.0, 0.0, 0.0);

      for (int i = 0; i < KERNEL_SIZE_INT; i++) {
        sum += texture2D(tDiffuse, imageCoord) * cKernel[i];
        imageCoord += uImageIncrement;
      }

      gl_FragColor = sum;
    }
  `;

  public static function buildKernel(sigma:Float):Array<Float> {
    // We lop off the sqrt(2 * pi) * sigma term, since we're going to normalize anyway.

    const kMaxKernelSize = 25;
    var kernelSize = 2 * Math.ceil(sigma * 3.0) + 1;

    if (kernelSize > kMaxKernelSize) kernelSize = kMaxKernelSize;

    const halfWidth = (kernelSize - 1) * 0.5;

    var values = new Array<Float>(kernelSize);
    var sum = 0.0;
    for (i in 0...kernelSize) {
      values[i] = gauss(i - halfWidth, sigma);
      sum += values[i];
    }

    // normalize the kernel

    for (i in 0...kernelSize) values[i] /= sum;

    return values;
  }

  static function gauss(x:Float, sigma:Float):Float {
    return Math.exp(-(x * x) / (2.0 * sigma * sigma));
  }
}