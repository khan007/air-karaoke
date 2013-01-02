package {

	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.display.Bitmap;
	import flash.utils.getTimer;
	import flash.media.SoundChannel;
	import flash.media.Sound;
	import flash.net.URLRequest;
	import flash.filesystem.File;
	import flash.display.Stage;
	import flash.display.StageScaleMode;
	import flash.display.StageAlign;
	import org.dynamiclab.CDG;
	import org.dynamiclab.YouTube;
	import com.SongManager;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import com.Song;
	import com.SongListPanel;
	import com.Menu;
	import com.Config;
	import com.Notify;
	import flash.events.ErrorEvent;

	// Window stuff
	import flash.desktop.NativeApplication;
	import com.PlaybackWindow;

	public class Main extends MovieClip {

		private var _cdg:CDG;
		private var _youTube:YouTube;
		private var _songManager:SongManager;
		private var _soundChannel:SoundChannel = new SoundChannel();
		private var _music:Sound;
		private var _isYouTubeReady:Boolean = false;
		private var _isMP3Ready:Boolean = false;
		private var _isCDGReady:Boolean = false;
		private var _config:Object;
		private var _file:String,_folder:String;
		private var _isTransparent:Boolean;
		private var _isPlaying:Boolean = false;

		// sections
		private var _songPanel:SongListPanel;
		private var _menu:Menu;
		private var _playbackWindow:PlaybackWindow;

		private const DS:String = File.separator;

		public function Main() {
			// stage setup;
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			stage.addEventListener(Event.RESIZE, _onStageResize);

			// config
			Config.init();

			// notification manager
			task_txt.mouseEnabled = false;
			Notify.init(task_txt);

			// song manager
			_songManager = new SongManager();
			_songManager.addEventListener(SongManager.REFRESH, _refreshPlaylist);
			
			// generic list panel;
			_songPanel = new SongListPanel(_songManager);
			_songPanel.addEventListener(SongListPanel.START_SONG, _startSong);
			this.addChildAt(_songPanel, 0);
			_songPanel.refreshList();

			// create new window to house the MV
			_playbackWindow = new PlaybackWindow();
			_playbackWindow.setSize(Config.get('playbackWidth'), Config.get('playbackHeight'));
			_playbackWindow.addEventListener(Event.CLOSE, _endPlayback);
			_playbackWindow.x = stage.nativeWindow.x + stage.nativeWindow.width;
			_playbackWindow.y = stage.nativeWindow.y;
			_playbackWindow.activate();

			// menu
			_menu = new Menu(_songManager);

			// initialize YouTube layer
			_youTube = new YouTube(Config.get('playbackWidth'), Config.get('playbackHeight'));
			_youTube.addEventListener(YouTube.READY, _onReady);
			_youTube.addEventListener(YouTube.NO_VIDEO , _noVideo);

			// initialize CDG processor
			_cdg = new CDG(Config.get('playbackWidth'), Config.get('playbackHeight'));
			_cdg.addEventListener(Event.COMPLETE, _onReady);

			// initialize _music
			_initUI();

			// exit
			stage.nativeWindow.addEventListener(Event.CLOSE, _closeApplication);
		}

		private function _endPlayback(e:Event):void {
			_stopPlayback();
		}
		
		private function _nextSong(e:Event):void {
			_stopPlayback();
			_playSong(_songManager.getNextSong());
		}
		
		private function _stopPlayback():void {
			_playbackWindow.removeChild(_youTube);
			_playbackWindow.removeChild(_cdg);
			_soundChannel.stop();
			_youTube.stop();
			_isPlaying = false;
			this.removeEventListener(Event.ENTER_FRAME, _onLoop);
		}

		private function _startSong(e:Event):void {
			if (!_isPlaying) {
				_playSong(_songPanel.getSelectedSong());
			}
		}
		
		private function _playSong(song:Song):void {
			if (song == null) {
				return;
			}
			_isPlaying = true;
			_cdg.loadCDG(song.url+".cdg");

			_soundChannel.stop();
			_music = new Sound(new URLRequest(song.url + ".mp3"));
			_music.addEventListener(Event.ID3, _onReady);

			_playbackWindow.activate();
		}

		private function _initUI():void {
			menu_btn.addEventListener(MouseEvent.CLICK, _onClick);
			songList_btn.addEventListener(MouseEvent.CLICK, _onClick);
			playList_btn.addEventListener(MouseEvent.CLICK, _onClick);
			stop_btn.addEventListener(MouseEvent.CLICK, _onClick);
		}

		private function _onClick(e:MouseEvent):void {
			// hide all
			if (this.contains(_menu)) {
				this.removeChild(_menu);
			}
			
			switch (e.target) {
				case menu_btn :
						this.addChild(_menu);
						_menu.x = (stage.stageWidth - _menu.width)/2;
						_menu.y = (stage.stageHeight - _menu.height)/2;
					break;
				case songList_btn :
					_songPanel.show(SongListPanel.SONG_LIST);
					break;
				case playList_btn :
					_songPanel.show(SongListPanel.PLAYLIST);
					break;
				case stop_btn:
					_nextSong(null);
					_songPanel.refreshList();
					break;
			}
		}

		private function _refreshPlaylist(e:Event):void {
			_songPanel.refreshList();
		}

		private function _noVideo(e:Event):void {
			_playbackWindow.removeChild(_youTube);
			_isTransparent = false;
		}

		private function _onReady(e:Event):void {
			switch (e.target) {
				case _youTube :
					_isYouTubeReady = true;
					break;
				case _cdg :
					_isCDGReady = true;
					break;
				case _music :
					_isMP3Ready = true;
					_music.removeEventListener(Event.ID3, _onReady);
					break;
			}

			if (_isYouTubeReady && _isCDGReady && _isMP3Ready) {
				// add CDG bitmap
				_cdg.setSize(stage.stageWidth, stage.stageHeight);
				_playbackWindow.addChild(_cdg);

				// sound panel
				_soundChannel.stop();
				_soundChannel = _music.play();
				_soundChannel.addEventListener(Event.SOUND_COMPLETE, _nextSong);	
				
				var songName:String = "";
				if (_music.id3.songName != null) {
					songName = _music.id3.songName;
					if (_music.id3.artist != null) {
						songName +=  " " + _music.id3.artist;
					}
				}

				if (songName.length > 0) {
					// add youtube background
					_youTube.setSize(stage.stageWidth, stage.stageHeight);
					_playbackWindow.addChildAt(_youTube, 0);
					_isTransparent = true;
					_youTube.findAndPlay(songName+" official");
				} else {
					_isTransparent = false;
					_playbackWindow.removeChild(_youTube);
				}

				this.addEventListener(Event.ENTER_FRAME, _onLoop);
			}
		}

		private function _onLoop(e:Event):void {
			// gets the current timing and sync CDG with audio
			var cdgPosition:int = Math.round(Math.ceil(((_soundChannel.position)/3.33)-1));
			_cdg.render(cdgPosition, _isTransparent);
		}

		private function _onStageResize(e:Event):void {
			_songPanel.setSize(stage.stageWidth, stage.stageHeight);

			// reposition
			menu_btn.x = stage.stageWidth - menu_btn.width;
			task_txt.y = stage.stageHeight - task_txt.height;
			task_txt.width = stage.stageWidth;
		}

		public function _closeApplication(e:Event):void {
			NativeApplication.nativeApplication.exit();
		}
	}

}