package utils;

import sys.io.File;
import sys.FileSystem;
import haxe.io.Path;

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
 * - Issue command 'haxe packLDrawModel models/<modelFileName>'
 *
 * The packed object will be in ldraw/models/<modelFileName>_Packed.mpd and will contain all the object subtree as embedded files.
 */

class PackLDrawModel {
  static var ldrawPath = './';
  static var materialsFileName = 'LDConfig.ldr';

  static function main(args:Array<String>) {
    if (args.length != 1) {
      Sys.println('Usage: haxe packLDrawModel <modelFilePath>');
      Sys.exit(0);
    }

    var fileName = args[0];

    var materialsFilePath = Path.join(ldrawPath, materialsFileName);

    Sys.println('Loading materials file "' + materialsFilePath + '"...');
    var materialsContent = File.getContent(materialsFilePath);

    Sys.println('Packing "' + fileName + '"...');

    var objectsPaths = [];
    var objectsContents = [];
    var pathMap = new Map<String, String>();
    var listOfNotFound = [];

    // Parse object tree
    parseObject(fileName, true);

    // Check if previously files not found are found now
    // (if so, probably they were already embedded)
    var someNotFound = false;
    for (i in 0...listOfNotFound.length) {
      if (!pathMap.exists(listOfNotFound[i])) {
        someNotFound = true;
        Sys.println('Error: File object not found: "' + fileName + '".');
      }
    }

    if (someNotFound) {
      Sys.println('Some files were not found, aborting.');
      Sys.exit(-1);
    }

    // Obtain packed content
    var packedContent = materialsContent + '\n';
    for (i in objectsPaths.length - 1...0) {
      packedContent += objectsContents[i];
    }

    packedContent += '\n';

    // Save output file
    var outPath = fileName + '_Packed.mpd';
    Sys.println('Writing "' + outPath + '"...');
    File.saveContent(outPath, packedContent);

    Sys.println('Done.');
  }

  static function parseObject(fileName:String, isRoot:Bool):String {
    // Returns the located path for fileName or null if not found

    Sys.println('Adding "' + fileName + '".');

    var originalFileName = fileName;

    var prefix = '';
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

      var absoluteObjectPath = Path.join(ldrawPath, prefix, fileName);

      try {
        objectContent = File.getContent(absoluteObjectPath);
      } catch (e:Dynamic) {
        prefix = 'parts/';
        absoluteObjectPath = Path.join(ldrawPath, prefix, fileName);

        try {
          objectContent = File.getContent(absoluteObjectPath);
        } catch (e:Dynamic) {
          prefix = 'p/';
          absoluteObjectPath = Path.join(ldrawPath, prefix, fileName);

          try {
            objectContent = File.getContent(absoluteObjectPath);
          } catch (e:Dynamic) {
            try {
              prefix = 'models/';
              absoluteObjectPath = Path.join(ldrawPath, prefix, fileName);

              objectContent = File.getContent(absoluteObjectPath);
            } catch (e:Dynamic) {
              if (attempt == 1) {
                // The file has not been found, add to list of not found
                listOfNotFound.push(originalFileName);
              }
            }
          }
        }
      }

      if (objectContent == null) {
        // File was not found, but could be a referenced embedded file.
        return null;
      }

      if (objectContent.indexOf('\r\n') != -1) {
        // This is faster than String.split with regex that splits on both
        objectContent = objectContent.replace('\r\n', '\n');
      }

      var objectPath = Path.join(prefix, fileName).trim().replace('\\', '/');

      if (!objectContent) {
        return null;
      }

      var processedObjectContent = isRoot ? '' : '0 FILE ' + objectPath + '\n';

      var lines = objectContent.split('\n');

      for (i in 0...lines.length) {
        var line = lines[i];
        var lineLength = line.length;

        // Skip spaces/tabs
        var charIndex = 0;
        while ((line.charAt(charIndex) == ' ' || line.charAt(charIndex) == '\t') && charIndex < lineLength) {
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

          var subobjectFileName = line.substring(charIndex).trim().replace('\\', '/');

          if (subobjectFileName != '') {
            // Find name in path cache
            var subobjectPath = pathMap.get(subobjectFileName);

            if (subobjectPath == null) {
              pathMap.set(subobjectFileName, subobjectFileName);
            }
          }
        }

        if (line.startsWith('1 ')) {
          // Subobject, add it
          charIndex = 2;

          // Skip material, position and transform
          for (token in 0...13) {
            // Skip token
            while (line.charAt(charIndex) != ' ' && line.charAt(charIndex) != '\t' && charIndex < lineLength) {
              charIndex++;
            }

            // Skip spaces/tabs
            while ((line.charAt(charIndex) == ' ' || line.charAt(charIndex) == '\t') && charIndex < lineLength) {
              charIndex++;
            }
          }

          var subobjectFileName = line.substring(charIndex).trim().replace('\\', '/');

          if (subobjectFileName != '') {
            // Find name in path cache
            var subobjectPath = pathMap.get(subobjectFileName);

            if (subobjectPath == null) {
              // Add new object
              subobjectPath = parseObject(subobjectFileName);
            }

            pathMap.set(subobjectFileName, subobjectPath != null ? subobjectPath : subobjectFileName);

            processedObjectContent += line.substring(0, charIndex) + pathMap.get(subobjectFileName) + '\n';
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

    return null;
  }
}