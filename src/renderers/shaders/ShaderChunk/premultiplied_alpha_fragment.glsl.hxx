class PremultipliedAlphaFragment {
    public static function getShaderChunk():String {
        return """
        #ifdef PREMULTIPLIED_ALPHA

            // Get get normal blending with premultipled, use with CustomBlending, OneFactor, OneMinusSrcAlphaFactor, AddEquation.
            gl_FragColor.rgb *= gl_FragColor.a;

        #endif
        """;
    }
}
```

然后，你可以在JavaScript中这样使用它：

```javascript
var shaderChunk = PremultipliedAlphaFragment.getShaderChunk();
// 使用shaderChunk