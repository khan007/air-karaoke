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
		
		// sections		
		private var _container:Sprite;
		private var _songPanel:SongListPanel;
		private var _menu:Menu;

		private const DS:String = File.separator;

		public function Main() {
			// stage setup
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
			
			// generic list panel
			_songPanel = new SongListPanel(_songManager);
			_songPanel.addEventListener(SongListPanel.PLAY_SONG, _playSong);
			this.addChildAt(_songPanel, 0);
			_songPanel.refreshList();
			
			// container for CDG + youtube
			_container = new Sprite();
			this.addChildAt(_container, 0);			
			
			// menu
			_menu = new Menu(_songManager);
			_menu.addEventListener(Menu.REFRESH, _refreshPlaylist);

			// initialize YouTube layer
			_youTube = new YouTube(stage.stageWidth, stage.stageHeight);
			_youTube.addEventListener(YouTube.READY, _onReady);

			// initialize CDG processor
			_cdg = new CDG(stage.stageWidth, stage.stageHeight);
			_cdg.addEventListener(Event.COMPLETE, _onReady);
			_cdg.addEventListener(CDG.EOF, _cdgEnd);
			
			// initialize _music
			_initUI();
		}
		
		private function _playSong(e:Event):void {
			var song:Song = _songPanel.getSelectedSong();
			_cdg.loadCDG(song.url+".cdg");
			
			_soundChannel.stop();
			_music = new Sound(new URLRequest(song.url+".mp3"));
			_music.addEventListener(Event.ID3, _onReady);
			
			_songPanel.collapse();
		}
		
		private function _initUI():void {
			menu_btn.addEventListener(MouseEvent.CLICK, _onClick);	
			songList_btn.addEventListener(MouseEvent.CLICK, _onClick);
		}
		
		private function _onClick(e:MouseEvent):void {
			switch (e.target) {
				case menu_btn:
					if (this.contains(_menu)) {
						this.removeChild(_menu);
					} else {
						this.addChild(_menu);
						_menu.x = (stage.stageWidth - _menu.width)/2;
						_menu.y = (stage.stageHeight - _menu.height)/2;
					}
					break;
				case songList_btn:
					_songPanel.toggle();
					break;
			}
		}

		private function _refreshPlaylist(e:Event):void {
			_songPanel.refreshList();
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
				_container.addChild(_cdg);
				
				_soundChannel.stop();
				_soundChannel = _music.play();
				var songName:String = "";
				if (_music.id3.songName != null) {
					songName = _music.id3.songName;
					if (_music.id3.artist != null) {
						songName += " "+_music.id3.artist;
					}
				}
				
				if (songName.length > 0) {
					// add youtube background
					_youTube.setSize(stage.stageWidth, stage.stageHeight);
					_youTube.visible = true;
					_youTube.findAndPlay(songName);
					_isTransparent = true;
				} else {
					_youTube.visible = false;
					_isTransparent = false;
				}
				
				_container.addEventListener(Event.ENTER_FRAME, _onLoop);
			}
		}

		private function _cdgEnd(e:Event):void {
			trace("End of CDG." + this.hasEventListener(Event.ENTER_FRAME));
			this.removeEventListener(Event.ENTER_FRAME, _onLoop);
		}

		private function _onLoop(e:Event):void {
			// gets the current timing and sync CDG with audio
			var cdgPosition:int = Math.round(Math.ceil(((_soundChannel.position)/3.33)-1));
			_cdg.render(cdgPosition, _isTransparent);
		}
		
		private function _onStageResize(e:Event):void {
			_songPanel.setSize(stage.stageWidth, stage.stageHeight);
			_cdg.setSize(stage.stageWidth, stage.stageHeight);
			_youTube.setSize(stage.stageWidth, stage.stageHeight);
			
			// reposition
			menu_btn.x = stage.stageWidth - menu_btn.width;
			task_txt.y = stage.stageHeight-task_txt.height;
			task_txt.width = stage.stageWidth;
		}
	}

}