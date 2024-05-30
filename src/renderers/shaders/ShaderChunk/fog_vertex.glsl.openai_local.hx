package shaders;

class FogVertexShader {
  public static inline var code = "
    #ifdef USE_FOG

      vFogDepth = - mvPosition.z;

    #endif
  ";
}


然后，在你的 `Main.hx` 文件中，可以像这样使用这个 Shader 代码：


package;

import shaders.FogVertexShader;

class Main {
  static function main() {
    // 在这里初始化你的 Three.js 相关代码
    trace(FogVertexShader.code);
  }
}


确保你的 `build.hxml` 文件包含如下内容来编译 Haxe 代码：

hxml
# 编译输出到 JavaScript
-js bin/main.js

# 包含 src 目录下的所有 Haxe 文件
-cp src

# 指定主类
-main Main


要运行这个项目，进入你的项目目录并运行：

sh
haxe build.hxml