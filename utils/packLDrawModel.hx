package three.js.utils;

import fs.FileSystem;
import sys.FileSystem;
import sys.io.File;

/**
 * LDraw object packer
 *
 * Usage:
 *
 * - Download official parts library from LDraw.org and unzip in a directory (e.g. ldraw/)
 *
 * - Download your desired model file and place in the ldraw/models/ subfolder.
 *
 * - Place this script also in ldraw/
 *
 * - Issue command 'haxe -main PackLDrawModel models/<modelFileName>'
 *
 * The packed object will be in ldraw/models/<modelFileName>_Packed.mpd and will contain all the object subtree as embedded files.
 *
 *
 */

class PackLDrawModel {
  static var ldrawPath:String = './';
  static var materialsFileName:String = 'LDConfig.ldr';

  static function main() {
    if (Sys.args().length != 1) {
      trace('Usage: haxe -main PackLDrawModel <modelFilePath>');
      Sys.exit(0);
    }

    var fileName:String = Sys.args()[0];

    var materialsFilePath:String = Path.join(ldrawPath, materialsFileName);

    trace('Loading materials file "' + materialsFilePath + '"...');

    var materialsContent:String = File.getContent(materialsFilePath);

    trace('Packing "' + fileName + '"...');

    var objectsPaths:Array<String> = [];
    var objectsContents:Array<String> = [];
    var pathMap:Map<String, String> = new Map<String, String>();
    var listOfNotFound:Array<String> = [];

    // Parse object tree
    parseObject(fileName, true);

    // Check if previously files not found are found now
    // (if so, probably they were already embedded)
    var someNotFound:Bool = false;
    for (i in 0...listOfNotFound.length) {
      if (!pathMap.exists(listOfNotFound[i])) {
        someNotFound = true;
        trace('Error: File object not found: "' + fileName + '".');
      }
    }

    if (someNotFound) {
      trace('Some files were not found, aborting.');
      Sys.exit(-1);
    }

    // Obtain packed content
    var packedContent:String = materialsContent + '\n';
    for (i in objectsPaths.length - 1...0) {
      packedContent += objectsContents[i];
    }

    packedContent += '\n';

    // Save output file
    var outPath:String = fileName + '_Packed.mpd';
    trace('Writing "' + outPath + '"...');
    File.saveContent(outPath, packedContent);

    trace('Done.');
  }

  static function parseObject(fileName:String, isRoot:Bool):String {
    // Returns the located path for fileName or null if not found

    trace('Adding "' + fileName + '".');

    var originalFileName:String = fileName;

    var prefix:String = '';
    var objectContent:String = null;
    for (attempt in 0...2) {
      prefix = '';

      if (attempt == 1) {
        fileName = fileName.toLowerCase();
      }

      if (fileName.startsWith('48/')) {
        prefix = 'p/';
      } else if (fileName.startsWith('s/')) {
        prefix = 'parts/';
      }

      var absoluteObjectPath:String = Path.join(ldrawPath, prefix, fileName);

      try {
        objectContent = File.getContent(absoluteObjectPath);
        break;
      } catch (e:Dynamic) {
        prefix = 'parts/';
        absoluteObjectPath = Path.join(ldrawPath, prefix, fileName);

        try {
          objectContent = File.getContent(absoluteObjectPath);
          break;
        } catch (e:Dynamic) {
          prefix = 'p/';
          absoluteObjectPath = Path.join(ldrawPath, prefix, fileName);

          try {
            objectContent = File.getContent(absoluteObjectPath);
            break;
          } catch (e:Dynamic) {
            try {
              prefix = 'models/';
              absoluteObjectPath = Path.join(ldrawPath, prefix, fileName);

              objectContent = File.getContent(absoluteObjectPath);
              break;
            } catch (e:Dynamic) {
              if (attempt == 1) {
                // The file has not been found, add to list of not found
                listOfNotFound.push(originalFileName);
              }
            }
          }
        }
      }
    }

    var objectPath:String = Path.join(prefix, fileName).trim().replace('\\', '/');

    if (objectContent == null) {
      // File was not found, but could be a referenced embedded file.
      return null;
    }

    if (objectContent.indexOf('\r\n') != -1) {
      // This is faster than String.split with regex that splits on both
      objectContent = objectContent.replace('\r\n', '\n');
    }

    var processedObjectContent:String = isRoot ? '' : '0 FILE ' + objectPath + '\n';

    var lines:Array<String> = objectContent.split('\n');

    for (i in 0...lines.length) {
      var line:String = lines[i];
      var lineLength:Int = line.length;

      // Skip spaces/tabs
      var charIndex:Int = 0;
      while (charIndex < lineLength && (line.charAt(charIndex) == ' ' || line.charAt(charIndex) == '\t')) {
        charIndex++;
      }

      line = line.substring(charIndex);
      lineLength = line.length;
      charIndex = 0;

      if (line.startsWith('0 FILE ')) {
        if (i == 0) {
          // Ignore first line FILE meta directive
          continue;
        }

        // Embedded object was found, add to path map

        var subobjectFileName:String = line.substring(charIndex).trim().replace('\\', '/');

        if (subobjectFileName != '') {
          // Find name in path cache
          var subobjectPath:String = pathMap[subobjectFileName];

          if (subobjectPath == null) {
            pathMap[subobjectFileName] = subobjectFileName;
          }
        }
      }

      if (line.startsWith('1 ')) {
        // Subobject, add it
        charIndex = 2;

        // Skip material, position and transform
        for (token in 0...13) {
          // Skip token
          while (charIndex < lineLength && line.charAt(charIndex) != ' ' && line.charAt(charIndex) != '\t') {
            charIndex++;
          }

          // Skip spaces/tabs
          while (charIndex < lineLength && (line.charAt(charIndex) == ' ' || line.charAt(charIndex) == '\t')) {
            charIndex++;
          }
        }

        var subobjectFileName:String = line.substring(charIndex).trim().replace('\\', '/');

        if (subobjectFileName != '') {
          // Find name in path cache
          var subobjectPath:String = pathMap[subobjectFileName];

          if (subobjectPath == null) {
            // Add new object
            subobjectPath = parseObject(subobjectFileName);
          }

          pathMap[subobjectFileName] = subobjectPath != null ? subobjectPath : subobjectFileName;

          processedObjectContent += line.substring(0, charIndex) + pathMap[subobjectFileName] + '\n';
        }
      } else {
        processedObjectContent += line + '\n';
      }
    }

    if (objectsPaths.indexOf(objectPath) == -1) {
      objectsPaths.push(objectPath);
      objectsContents.push(processedObjectContent);
    }

    return objectPath;
  }
}