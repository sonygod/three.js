// 定义 BlinnPhongMaterial 结构体
typedef BlinnPhongMaterial = {
    var diffuseColor: Vector3;
    var specularColor: Vector3;
    var specularShininess: Float;
    var specularStrength: Float;
}

// 创建一个新的 BlinnPhongMaterial 实例，并赋值
var material: BlinnPhongMaterial = {
    diffuseColor: diffuseColor.rgb,
    specularColor: specular,
    specularShininess: shininess,
    specularStrength: specularStrength
};