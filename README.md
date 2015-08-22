# radiko2mpd
-

## 準備

### rbenvでrubyのインストール
rbenvとruby-buildのインストールは省略．

	rbenv install 2.2.2

### パッケージのインストール
	sudo aptitude install wget
	sudo aptitude install libxml2
	sudo aptitude install rtmpdump
	sudo aptitude install swftools
	sudo aptitude install ffmpeg lame
	sudo aptitude install vlc-nox
	sudo aptitude install icecast2

## インストール
	git clone https://github.com/river24/radiko2mpd
	cd radiko2mpd
	rbenv local 2.2.2
	rbenv exec bundle install

### 設定ファイル作成
	cp scripts/config.bash.sample scripts/config.bash
	vi scripts/config.bash

## 放送局スキャン
	scripts/scan.bash
	sudo cp playlists/*.m3u /var/lib/mpd/playlists/

## 起動
	scripts/start.bash

### 自動起動
	crontab -e
	----
	@reboot /path/to/radiko2mpd/scripts/start.bash
	----

## 停止
	scripts/stop.bash
