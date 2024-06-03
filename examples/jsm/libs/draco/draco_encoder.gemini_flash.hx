import draco_wasm.DracoEncoderModule;

class HaxeDracoEncoderModule extends DracoEncoderModule {

    public static function isVersionSupported(versionString:String):Bool {
        if (versionString.length == 0 || versionString.indexOf(".") == -1) return false;
        var parts = versionString.split(".");
        if (parts.length < 2 || parts.length > 3) return false;
        var major = Std.parseInt(parts[0]);
        var minor = Std.parseInt(parts[1]);
        if (major == 1 && minor >= 0 && minor <= 3) return true;
        if (major != 0 || minor > 10) return false;
        return true;
    }
    
    public static function main() {
        var module = new HaxeDracoEncoderModule();
        
        // Example: check if a Draco version is supported
        trace(module.isVersionSupported("1.3.1")); // true
        trace(module.isVersionSupported("1.4.0")); // false
        trace(module.isVersionSupported("0.10.0")); // true
        trace(module.isVersionSupported("0.11.0")); // false
        trace(module.isVersionSupported("1.0")); // false
        trace(module.isVersionSupported("1")); // false
        trace(module.isVersionSupported("1.3")); // false
        trace(module.isVersionSupported("1.3.a")); // false
        
        // Example: create a new MeshBuilder
        var meshBuilder = new module.MeshBuilder();
        
        // Example: create a new PointCloudBuilder
        var pointCloudBuilder = new module.PointCloudBuilder();
        
        // Example: create a new MetadataBuilder
        var metadataBuilder = new module.MetadataBuilder();
        
        // Example: create a new PointAttribute
        var pointAttribute = new module.PointAttribute();
        
        // Example: create a new GeometryAttribute
        var geometryAttribute = new module.GeometryAttribute();
        
        // Example: create a new Encoder
        var encoder = new module.Encoder();
        
        // Example: create a new ExpertEncoder
        var expertEncoder = new module.ExpertEncoder();
        
        // Example: create a new DracoInt8Array
        var dracoInt8Array = new module.DracoInt8Array();
        
        // Example: create a new Mesh
        var mesh = new module.Mesh();
        
        // Example: create a new PointCloud
        var pointCloud = new module.PointCloud();
        
        // Example: create a new Metadata
        var metadata = new module.Metadata();
        
        // Example: use the encoder to encode a mesh
        // ...
        
        // Example: use the expertEncoder to encode a point cloud
        // ...
        
        // Example: use the dracoInt8Array to access the encoded data
        // ...
    }
}

class Main {
    
    static function main() {
        HaxeDracoEncoderModule.main();
    }
}