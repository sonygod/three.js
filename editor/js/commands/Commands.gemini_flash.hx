package ;

import AddObjectCommand from './AddObjectCommand';
import AddScriptCommand from './AddScriptCommand';
import MoveObjectCommand from './MoveObjectCommand';
import MultiCmdsCommand from './MultiCmdsCommand';
import RemoveObjectCommand from './RemoveObjectCommand';
import RemoveScriptCommand from './RemoveScriptCommand';
import SetColorCommand from './SetColorCommand';
import SetGeometryCommand from './SetGeometryCommand';
import SetGeometryValueCommand from './SetGeometryValueCommand';
import SetMaterialColorCommand from './SetMaterialColorCommand';
import SetMaterialCommand from './SetMaterialCommand';
import SetMaterialMapCommand from './SetMaterialMapCommand';
import SetMaterialRangeCommand from './SetMaterialRangeCommand';
import SetMaterialValueCommand from './SetMaterialValueCommand';
import SetMaterialVectorCommand from './SetMaterialVectorCommand';
import SetPositionCommand from './SetPositionCommand';
import SetRotationCommand from './SetRotationCommand';
import SetScaleCommand from './SetScaleCommand';
import SetSceneCommand from './SetSceneCommand';
import SetScriptValueCommand from './SetScriptValueCommand';
import SetUuidCommand from './SetUuidCommand';
import SetValueCommand from './SetValueCommand';

class Commands {
  public static var AddObjectCommand: Class<AddObjectCommand> = AddObjectCommand;
  public static var AddScriptCommand: Class<AddScriptCommand> = AddScriptCommand;
  public static var MoveObjectCommand: Class<MoveObjectCommand> = MoveObjectCommand;
  public static var MultiCmdsCommand: Class<MultiCmdsCommand> = MultiCmdsCommand;
  public static var RemoveObjectCommand: Class<RemoveObjectCommand> = RemoveObjectCommand;
  public static var RemoveScriptCommand: Class<RemoveScriptCommand> = RemoveScriptCommand;
  public static var SetColorCommand: Class<SetColorCommand> = SetColorCommand;
  public static var SetGeometryCommand: Class<SetGeometryCommand> = SetGeometryCommand;
  public static var SetGeometryValueCommand: Class<SetGeometryValueCommand> = SetGeometryValueCommand;
  public static var SetMaterialColorCommand: Class<SetMaterialColorCommand> = SetMaterialColorCommand;
  public static var SetMaterialCommand: Class<SetMaterialCommand> = SetMaterialCommand;
  public static var SetMaterialMapCommand: Class<SetMaterialMapCommand> = SetMaterialMapCommand;
  public static var SetMaterialRangeCommand: Class<SetMaterialRangeCommand> = SetMaterialRangeCommand;
  public static var SetMaterialValueCommand: Class<SetMaterialValueCommand> = SetMaterialValueCommand;
  public static var SetMaterialVectorCommand: Class<SetMaterialVectorCommand> = SetMaterialVectorCommand;
  public static var SetPositionCommand: Class<SetPositionCommand> = SetPositionCommand;
  public static var SetRotationCommand: Class<SetRotationCommand> = SetRotationCommand;
  public static var SetScaleCommand: Class<SetScaleCommand> = SetScaleCommand;
  public static var SetSceneCommand: Class<SetSceneCommand> = SetSceneCommand;
  public static var SetScriptValueCommand: Class<SetScriptValueCommand> = SetScriptValueCommand;
  public static var SetUuidCommand: Class<SetUuidCommand> = SetUuidCommand;
  public static var SetValueCommand: Class<SetValueCommand> = SetValueCommand;
}


This code does the following:

1. **Declares a package:** `package ;` This can be changed to a more specific package name if needed.
2. **Imports the necessary classes:** It imports each command class from their respective files.
3. **Creates a `Commands` class:** This class serves as a container for all the command classes.
4. **Defines static variables for each command:** Each variable holds the class reference of the corresponding command. This makes it easy to access these classes from other parts of the code.

Now, you can access any of the command classes using the `Commands` class like this:


var addObjectCommand: Class<AddObjectCommand> = Commands.AddObjectCommand;