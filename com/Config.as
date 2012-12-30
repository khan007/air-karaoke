package com {

	import flash.filesystem.File;
	import flash.utils.ByteArray;
	import flash.filesystem.FileStream;
	import flash.filesystem.FileMode;

	public class Config {

		private static var _config:Object;
		private static var configFile:File;
		private static var _default:Object;
	
		public function Config() {
			// constructor code
		}
		
		public static function init():void {
			_default = new Object();
			_default.folder = File.applicationDirectory.nativePath;
			_default.playbackWidth = 640;
			_default.playbackHeight = 480;
			
			configFile = File.applicationStorageDirectory.resolvePath("config.ini");
			
			if (configFile.exists) {
				// read it
				_config = _readConfig(configFile);
			} else {
				// create it with default
				_writeConfig(configFile, _default);
			}
		}
		
		public static function get(key:String):* {
			trace("CONFIG - "+key+": "+_config[key]);
			trace("DEFAULT - "+key+": "+_default[key]);
			if (_config[key] == undefined) {
				return _default[key];
			}
			return _config[key];
		}
		
		public static function set(key:String, val:String):void {
			_config[key] = val;
			_writeConfig(configFile, _config);
		}
		
		private static function _writeConfig(file:File, obj:Object):void {
			var ba:ByteArray = new ByteArray();
			ba.writeObject(obj);
			var fs:FileStream = new FileStream();
			fs.open(file, FileMode.WRITE);
			fs.writeInt(ba.length);
			fs.writeBytes(ba);
			fs.close();
			fs = null;
		}

		private static function _readConfig(file:File):Object {
			var fs:FileStream = new FileStream();
			fs.open(file, FileMode.READ);
			var len = fs.readInt();
			var ba:ByteArray = new ByteArray();
			fs.readBytes(ba, 0, len);
			fs.close();
			fs = null;
			return ba.readObject();
		}

	}
	
}
