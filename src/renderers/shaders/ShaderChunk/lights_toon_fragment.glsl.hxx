import js.Lib;

class Main {
    static function main() {
        var shader = Lib.glsl`
            ToonMaterial material;
            material.diffuseColor = diffuseColor.rgb;
        `;
        // 使用shader
    }
}