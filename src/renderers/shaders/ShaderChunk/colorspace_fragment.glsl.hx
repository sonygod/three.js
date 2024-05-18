package three.shaderlib;

class ColorSpaceFragment {
    public function new() {}

    public static function main() {
        gl_FragColor = linearToOutputTexel(gl_FragColor);
    }
}