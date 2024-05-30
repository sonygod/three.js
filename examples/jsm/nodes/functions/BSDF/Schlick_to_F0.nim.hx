import three.js.examples.jsm.nodes.ShaderNode;

class Schlick_to_F0 {
    public static function main() {
        var Schlick_to_F0 = ShaderNode.tslFn(function(f, f90, dotVH) {
            var x = dotVH.oneMinus().saturate();
            var x2 = x.mul(x);
            var x5 = x.mul(x2, x2).clamp(0, 0.9999);
            return f.sub(ShaderNode.vec3(f90).mul(x5)).div(x5.oneMinus());
        }).setLayout({
            name: 'Schlick_to_F0',
            type: 'vec3',
            inputs: [
                { name: 'f', type: 'vec3' },
                { name: 'f90', type: 'float' },
                { name: 'dotVH', type: 'float' }
            ]
        });
        return Schlick_to_F0;
    }
}