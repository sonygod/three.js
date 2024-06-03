class BlinnPhongMaterial {
    public var diffuseColor:Array<Float>;
    public var specularColor:Array<Float>;
    public var specularShininess:Float;
    public var specularStrength:Float;

    public function new(diffuseColor:Array<Float>, specular:Array<Float>, shininess:Float, specularStrength:Float) {
        this.diffuseColor = diffuseColor;
        this.specularColor = specular;
        this.specularShininess = shininess;
        this.specularStrength = specularStrength;
    }
}