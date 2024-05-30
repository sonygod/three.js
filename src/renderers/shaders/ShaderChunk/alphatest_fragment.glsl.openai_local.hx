// alphatest_fragment.glsl.hx

#if USE_ALPHATEST

    #if ALPHA_TO_COVERAGE

    diffuseColor.a = smoothstep(alphaTest, alphaTest + fwidth(diffuseColor.a), diffuseColor.a);
    if (diffuseColor.a == 0.0) discard;

    #else

    if (diffuseColor.a < alphaTest) discard;

    #end

#end


这个 Haxe 代码使用了预处理器指令（`#if` 和 `#end`），与 GLSL 的 `#ifdef` 和 `#endif` 相对应。Haxe 的 `discard` 语句与 GLSL 中的相同，直接丢弃片元。

如果你在 Haxe 中使用的是 GLSL 代码嵌入功能，可以如下定义为字符串：


var shaderCode = "
#ifdef USE_ALPHATEST

    #ifdef ALPHA_TO_COVERAGE

    diffuseColor.a = smoothstep(alphaTest, alphaTest + fwidth(diffuseColor.a), diffuseColor.a);
    if (diffuseColor.a == 0.0) discard;

    #else

    if (diffuseColor.a < alphaTest) discard;

    #endif

#endif
";