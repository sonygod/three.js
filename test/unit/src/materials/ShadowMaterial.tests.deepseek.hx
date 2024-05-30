// 导入必要的类
import three.materials.ShadowMaterial;
import three.materials.Material;

// 定义测试模块
class ShadowMaterialTest {
    static function main() {
        // 测试继承
        var object = new ShadowMaterial();
        unittest.assert(object instanceof Material);

        // 测试实例化
        var object = new ShadowMaterial();
        unittest.assert(object != null);

        // 测试类型属性
        var object = new ShadowMaterial();
        unittest.assert(object.type == "ShadowMaterial");

        // 测试isShadowMaterial属性
        var object = new ShadowMaterial();
        unittest.assert(object.isShadowMaterial);
    }
}