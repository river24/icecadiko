# mpdiko

- MPD で radiko をライブ試聴するためのツール．
- MPD のクライアントから radiko の選局も可能．
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
	git clone https://github.com/river24/mpdiko
	cd mpdiko
	rbenv local 2.2.2
	rbenv exec bundle install --path vendor/bundle

### 設定ファイル作成
	cp scripts/config.bash.sample scripts/config.bash
	vi scripts/config.bash

- radiko のプレミアムユーザは 'RADIKO_MAIL' と 'RADIKO_PASS' を設定することで，エリアフリーでの聴取が可能になる．

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
	@reboot /path/to/mpdiko/scripts/start.bash
	----

## 停止
	scripts/stop.bash
