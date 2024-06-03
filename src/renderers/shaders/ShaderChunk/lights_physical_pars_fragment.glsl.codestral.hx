class PhysicalMaterial {
    public var diffuseColor: Array<Float>;
    public var roughness: Float;
    public var specularColor: Array<Float>;
    public var specularF90: Float;
    public var dispersion: Float;

    // ...other properties...
}

// temporary
var clearcoatSpecularDirect: Array<Float> = [0.0, 0.0, 0.0];
var clearcoatSpecularIndirect: Array<Float> = [0.0, 0.0, 0.0];
var sheenSpecularDirect: Array<Float> = [0.0, 0.0, 0.0];
var sheenSpecularIndirect: Array<Float> = [0.0, 0.0, 0.0];

function Schlick_to_F0(f: Array<Float>, f90: Float, dotVH: Float): Array<Float> {
    var x = Math.min(1.0, Math.max(0.0, 1.0 - dotVH));
    var x2 = x * x;
    var x5 = Math.min(0.9999, Math.max(0.0, x * x2 * x2));

    var result = new Array<Float>();
    for (var i = 0; i < 3; i++) {
        result[i] = (f[i] - f90 * x5) / (1.0 - x5);
    }
    return result;
}

// ...other functions...

function BRDF_GGX(lightDir: Array<Float>, viewDir: Array<Float>, normal: Array<Float>, material: PhysicalMaterial): Array<Float> {
    var f0 = material.specularColor;
    var f90 = material.specularF90;
    var roughness = material.roughness;

    var alpha = roughness * roughness; // UE4's roughness

    // ...other calculations...

    var F = Schlick_to_F0(f0, f90, dotVH);

    // ...other calculations...

    var result = new Array<Float>();
    for (var i = 0; i < 3; i++) {
        result[i] = F[i] * (V * D);
    }
    return result;
}

// ...other functions...