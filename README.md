# radiko2mpd

- MPD (Music Player Daemon) で radiko の聴取・選局を可能にするやつ．
- rtmpdump とか ffmpeg とか vlc とか icecast2 とか sinatra とかの組み合わせ技．
- Raspbian で動作確認．

## 準備

### rbenv + ruby-build + ruby 2.2.2 + bundler
	rbenv のインストール
	----
	rbenv install 2.2.2
	rbenv rehash
	rbenv shell 2.2.2
	rbenv exec gem update --system
	rbenv exec gem install bundler
	rbenv rehash

### パッケージのインストール
	sudo aptitude install wget
	sudo aptitude install libxml2
	sudo aptitude install rtmpdump
	sudo aptitude install swftools
	sudo aptitude install ffmpeg lame
	sudo aptitude install vlc-nox
	sudo aptitude install icecast2
	sudo aptitude install mpd

## インストール
	git clone https://github.com/river24/radiko2mpd
	cd radiko2mpd
	rbenv local 2.2.2
	rbenv exec bundle install

### 設定ファイル作成
	cp scripts/config.bash.sample scripts/config.bash
	vi scripts/config.bash

- radiko のプレミアムユーザは 'RADIKO_MAIL' と 'RADIKO_PASS' を設定することで，エリアフリーでの視聴が可能になる．

## 放送局スキャン
	scripts/scan.bash

## プレイリストのコピー
	sudo cp playlists/*.m3u /var/lib/mpd/playlists/

## 起動
	scripts/start.bash

### MPDで選局
- MPD の "Saved playlist" から聴きたい放送局を選局します．
- 認証等の都合で，10秒前後かかります．

### 自動起動
	crontab -e
	----
	@reboot /path/to/radiko2mpd/scripts/start.bash
	----

## 停止
	scripts/stop.bash
