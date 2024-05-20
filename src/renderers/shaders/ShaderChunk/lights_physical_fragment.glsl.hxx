class PhysicalMaterial {
    public var diffuseColor:Float;
    public var roughness:Float;
    public var ior:Float;
    public var specularColor:Float;
    public var specularF90:Float;
    public var clearcoat:Float;
    public var clearcoatRoughness:Float;
    public var clearcoatF0:Float;
    public var clearcoatF90:Float;
    public var dispersion:Float;
    public var iridescence:Float;
    public var iridescenceIOR:Float;
    public var iridescenceThickness:Float;
    public var sheenColor:Float;
    public var sheenRoughness:Float;
    public var anisotropy:Float;
    public var anisotropyT:Float;
    public var anisotropyB:Float;
    public var alphaT:Float;

    public function new() {
        // 初始化代码
    }

    public function calculateDiffuseColor(nonPerturbedNormal:Float, metalnessFactor:Float):Float {
        // 计算diffuseColor的逻辑
    }

    public function calculateRoughness(roughnessFactor:Float, geometryRoughness:Float):Float {
        // 计算roughness的逻辑
    }

    // 其他方法...
}