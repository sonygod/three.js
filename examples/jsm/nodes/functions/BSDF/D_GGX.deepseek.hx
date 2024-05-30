import three.shadernode.ShaderNode;

class D_GGX extends ShaderNode {

    public function new() {
        super();
        this.setLayout({
            name: 'D_GGX',
            type: 'float',
            inputs: [
                { name: 'alpha', type: 'float' },
                { name: 'dotNH', type: 'float' }
            ]
        });
    }

    public function compute(alpha:Float, dotNH:Float):Float {
        var a2 = Math.pow(alpha, 2);
        var denom = Math.pow(dotNH, 2) * (a2 - 1) - 1; // avoid alpha = 0 with dotNH = 1
        return a2 / Math.pow(denom, 2) / Math.PI;
    }
}

class D_GGXFactory {
    public static function create():D_GGX {
        return new D_GGX();
    }
}