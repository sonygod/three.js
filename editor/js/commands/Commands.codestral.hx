class Commands {
    public static var AddObjectCommand:Class<AddObjectCommand>;
    public static var AddScriptCommand:Class<AddScriptCommand>;
    public static var MoveObjectCommand:Class<MoveObjectCommand>;
    public static var MultiCmdsCommand:Class<MultiCmdsCommand>;
    public static var RemoveObjectCommand:Class<RemoveObjectCommand>;
    public static var RemoveScriptCommand:Class<RemoveScriptCommand>;
    public static var SetColorCommand:Class<SetColorCommand>;
    public static var SetGeometryCommand:Class<SetGeometryCommand>;
    public static var SetGeometryValueCommand:Class<SetGeometryValueCommand>;
    public static var SetMaterialColorCommand:Class<SetMaterialColorCommand>;
    public static var SetMaterialCommand:Class<SetMaterialCommand>;
    public static var SetMaterialMapCommand:Class<SetMaterialMapCommand>;
    public static var SetMaterialRangeCommand:Class<SetMaterialRangeCommand>;
    public static var SetMaterialValueCommand:Class<SetMaterialValueCommand>;
    public static var SetMaterialVectorCommand:Class<SetMaterialVectorCommand>;
    public static var SetPositionCommand:Class<SetPositionCommand>;
    public static var SetRotationCommand:Class<SetRotationCommand>;
    public static var SetScaleCommand:Class<SetScaleCommand>;
    public static var SetSceneCommand:Class<SetSceneCommand>;
    public static var SetScriptValueCommand:Class<SetScriptValueCommand>;
    public static var SetUuidCommand:Class<SetUuidCommand>;
    public static var SetValueCommand:Class<SetValueCommand>;
}


In this Haxe code, `Commands` is a class that has static fields for each of the imported modules. You would need to ensure that the corresponding Haxe classes are defined in the right place and imported into this file.

Please note:

- This is a static class, which means you can access its members directly through the class name, without creating an instance of the class.
- The `Class<T>` type in Haxe is a representation of a class itself, not an instance of a class. It's similar to how you might use a constructor function in JavaScript.
- In Haxe, you would typically import the necessary classes at the top of your file, like so:


import AddObjectCommand;
import AddScriptCommand;
// ... and so on for each imported module