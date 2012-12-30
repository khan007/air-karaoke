package com{

	import flash.media.Sound;
	import flash.net.URLRequest;
	import flash.filesystem.File;
	import flash.events.Event;

	import flash.data.SQLConnection;
	import flash.data.SQLStatement;
	import flash.events.SQLErrorEvent;
	import flash.events.SQLEvent;
	import flash.data.SQLResult;

	import com.Notify;
	import flash.events.EventDispatcher;

	public class SongManager extends EventDispatcher{

		private var _mp3List:Array = new Array();
		private var _song:Sound = new Sound();
		private var _sql:SQLConnection;
		private var _sqlStatement:SQLStatement;
		private var _total:uint = 0;
		private var _searchString:String = "";
		private var _foundTotal:uint = 0;
		
		public static const MAX_RESULT:uint = 50;
		public static const REFRESH:String = "Refresh";

		public function SongManager() {
			// constructor code
			_sql = new SQLConnection();
			_sql.addEventListener(SQLEvent.OPEN, _onDatabaseOpen);
			_sql.addEventListener(SQLErrorEvent.ERROR, _sqlError);

			// get currently dir;
			var dbFile:File = File.applicationStorageDirectory.resolvePath("air_karaoke.db");

			// open database,If the file doesn't exist yet, it will be created
			_sql.open(dbFile);
		}

		public function fetchMP3(folderPath:String):Array {
			var mp3List:Array = new Array();
			var folder:File = new File();
			folder.nativePath = folderPath;

			var files:Array = folder.getDirectoryListing();
			for (var i:uint = 0; i < files.length; i++) {
				var file:File = files[i];
				if (! file.isDirectory) {
					// is a file, check if it's CDG
					if (file.name.substr(-3).toLowerCase() == "cdg") {
						// it's a CDG, check for matching MP3
						var mp3File:File = file.parent.resolvePath(file.name.substr(0,file.name.length - 4) + ".mp3");
						if (mp3File.exists) {
							mp3List.push(mp3File);
						}
					}
				} else {
					mp3List = mp3List.concat(fetchMP3(file.nativePath));
				}
			}
			
			return mp3List;
		}

		public function getTotal():uint {
			return _total;
		}

		public function findSong(str:String):Array {
			_searchString = str;
			return getSongList(0);
		}

		public function getSongList(startIndex:uint = 0, len:uint = MAX_RESULT):Array {
			var songs:Array = new Array();

			// get song from db
			_sqlStatement.clearParameters();			
			_sqlStatement.text = "SELECT COUNT(*) AS total FROM songs";
			
			if (_searchString.length > 0) {
				var words:Array = _searchString.split(" ");
				_sqlStatement.text += " WHERE";
				
				var likeStatements = "";
				var parameterCount:uint = 0;
				for (var i:uint = 0; i < words.length; i++) {
					if (words[i].length == 0) {
						continue;
					}
					if (likeStatements.length > 0) {
						likeStatements += " AND";
					}
					//likeStatements += " (name LIKE '%"+words[i]+"%' OR artist LIKE '%"+words[i]+"%')";
					likeStatements += " (name LIKE @param"+parameterCount+" OR artist LIKE @param"+parameterCount+")";
					_sqlStatement.parameters["@param"+parameterCount] = '%'+words[i]+'%';
					parameterCount++;
				}
				_sqlStatement.text += likeStatements;
			}
			trace(_sqlStatement.text);
			_sqlStatement.execute();
			
			// go through result;
			var sqlresult:SQLResult = _sqlStatement.getResult();
			_total = sqlresult.data[0]['total'];
			
			_sqlStatement.text = "SELECT * FROM songs";
			if (_searchString.length > 0) {
				var words:Array = _searchString.split(" ");
				_sqlStatement.text += " WHERE";
				
				var likeStatements = "";
				var parameterCount:uint = 0;
				for (var i:uint = 0; i < words.length; i++) {
					if (words[i].length == 0) {
						continue;
					}
					if (likeStatements.length > 0) {
						likeStatements += " AND";
					}
					likeStatements += " (name LIKE @param"+parameterCount+" OR artist LIKE @param"+parameterCount+")";			
					parameterCount++;
				}
				_sqlStatement.text += likeStatements;	
			}
			_sqlStatement.text += " ORDER BY name LIMIT "+len+" OFFSET "+startIndex;
			trace(_sqlStatement.text);
			_sqlStatement.execute();

			// go through result;
			sqlresult = _sqlStatement.getResult();
			if (sqlresult.data != null) {
				for (var i:uint = 0; i < sqlresult.data.length; i++) {
					var song:Song = new Song(sqlresult.data[i]);
					songs.push(song);
				}
			}

			return songs;
		}

		public function readMP3TagAsync(mp3List:Array):void {
			// drop table
			_sqlStatement.clearParameters();
			_sqlStatement.text = "DROP TABLE songs";
			_sqlStatement.execute();

			// re-create table;
			_sqlStatement.text = "CREATE TABLE IF NOT EXISTS songs (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, artist TEXT, path TEXT, count INTEGER)";
			_sqlStatement.execute();

			_mp3List = mp3List;
			_foundTotal = mp3List.length;
			_readMP3();
		}

		private function _readMP3():void {
			if (_mp3List.length > 0) {
				_song = new Sound(new URLRequest(_mp3List[0].nativePath));
				_song.addEventListener(Event.COMPLETE, _onComplete);
			} else {
				Notify.show("Complete.");
				dispatchEvent(new Event(REFRESH));
			}
		}

		private function _onComplete(e:Event):void {
			// check if exists
			var url:String = _song.url.substr(0,_song.url.length - 4);
			var id3:Object = _song.id3;
			if (id3 == null) {
				id3.artist = "Unknown";
				id3.songName = null;
			}

			Notify.show(Math.round(((_foundTotal-_mp3List.length)/_foundTotal)*100)+"% Done. Adding: "+url);

			// only insert if not found
			_sqlStatement.clearParameters();
			_sqlStatement.text = "INSERT INTO songs (name, artist, path, count) VALUES(@name, @artist, @path, @count)";

			var songName:String = id3.songName;
			if (songName == null || trim(songName).length == 0) {
				// get the filename
				songName = url.substring(url.lastIndexOf('/') + 1,url.length);
			}
			_sqlStatement.parameters["@name"] = songName;
			_sqlStatement.parameters["@artist"] = id3.artist == null ? "Unknown":id3.artist;
			_sqlStatement.parameters["@path"] = url;
			_sqlStatement.parameters["@count"] = 0;
			_sqlStatement.execute();

			_song.removeEventListener(Event.COMPLETE, _onComplete);
			_song = null;

			_mp3List.splice(0,1);
			_readMP3();
		}

		// ************************** SQL Events

		// connect and init database/table;
		private function _onDatabaseOpen(event:SQLEvent):void {
			// init sqlStatement object
			_sqlStatement = new SQLStatement();
			_sqlStatement.addEventListener(SQLErrorEvent.ERROR, _sqlError);

			_sqlStatement.sqlConnection = _sql;
			_sqlStatement.text = "CREATE TABLE IF NOT EXISTS songs (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, artist TEXT, path TEXT, count INTEGER)";
			_sqlStatement.execute();
		}

		private function _sqlError(event:SQLErrorEvent):void {
			trace("Error code:", event.error);
			//trace("Details:", event.error.message);
		}

		public function trim( s:String ):String {
			return s.replace( /^([\s|\t|\n]+)?(.*)([\s|\t|\n]+)?$/gm, "$2" );
		}
	}
}