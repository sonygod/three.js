class WebGPUConstants {
    static var GPUPrimitiveTopology = {
        PointList: 'point-list',
        LineList: 'line-list',
        LineStrip: 'line-strip',
        TriangleList: 'triangle-list',
        TriangleStrip: 'triangle-strip',
    };

    static var GPUCompareFunction = {
        Never: 'never',
        Less: 'less',
        Equal: 'equal',
        LessEqual: 'less-equal',
        Greater: 'greater',
        NotEqual: 'not-equal',
        GreaterEqual: 'greater-equal',
        Always: 'always'
    };

    // ... rest of the constants ...

    static var GPUFeatureName = {
        DepthClipControl: 'depth-clip-control',
        Depth32FloatStencil8: 'depth32float-stencil8',
        TextureCompressionBC: 'texture-compression-bc',
        TextureCompressionETC2: 'texture-compression-etc2',
        TextureCompressionASTC: 'texture-compression-astc',
        TimestampQuery: 'timestamp-query',
        IndirectFirstInstance: 'indirect-first-instance',
        ShaderF16: 'shader-f16',
        RG11B10UFloat: 'rg11b10ufloat-renderable',
        BGRA8UNormStorage: 'bgra8unorm-storage',
        Float32Filterable: 'float32-filterable'
    };
}