import tslFn.Float;
import tslFn.Vec3;
import tslFn.Layout;

class D_GGX_Anisotropic {
    static var RECIPROCAL_PI = new Float(1 / Math.PI);

    static var D_GGX_Anisotropic = tslFn(({ alphaT, alphaB, dotNH, dotTH, dotBH }) -> {
        var a2 = alphaT * alphaB;
        var v = new Vec3(alphaB * dotTH, alphaT * dotBH, a2 * dotNH);
        var v2 = v.dot(v);
        var w2 = a2 / v2;

        return RECIPROCAL_PI * a2 * w2 * w2;
    }).setLayout(new Layout({
        name: 'D_GGX_Anisotropic',
        type: 'float',
        inputs: [
            { name: 'alphaT', type: 'float', qualifier: 'in' },
            { name: 'alphaB', type: 'float', qualifier: 'in' },
            { name: 'dotNH', type: 'float', qualifier: 'in' },
            { name: 'dotTH', type: 'float', qualifier: 'in' },
            { name: 'dotBH', type: 'float', qualifier: 'in' }
        ]
    }));
}