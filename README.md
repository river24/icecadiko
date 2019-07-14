# icecadiko

- radikoをicecast2経由で視聴するためのツール．
- icecast2対応の各種クライアントでradikoを視聴可能に．
- icecast2のURLを切り替えることで，radikoの選局も可能．
- radikoのプレミアムにも対応．
- Raspbianで動作確認．

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

## インストール
	git clone https://github.com/river24/icecadiko
	cd icecadiko
	rbenv local 2.2.2
	rbenv exec bundle install --path vendor/bundle

### 設定ファイル作成
	cp scripts/config.bash.sample scripts/config.bash
	vi scripts/config.bash

- radiko のプレミアムユーザは 'RADIKO_MAIL' と 'RADIKO_PASS' を設定することで，エリアフリーでの聴取が可能になる．
- 'APP_PORT'はデフォルトで9000番．他のアプリケーションと重なる場合は適宜変更．

## 放送局スキャン
	scripts/scan.bash

## プレイリストのコピー
	sudo rsync -av playlists/icecadiko /path/to/playlist/folder/of/your/icecast2/client/

## 起動
	scripts/start.bash

### 自動起動
	crontab -e
	----
	@reboot /path/to/mpdiko/scripts/start.bash
	----

## 停止
	scripts/stop.bash

## 視聴・選局
icecast2対応のクライアントで，プレイリストを選んで再生．

### Music Player Daemonでの選局の様子
- 「プレイリストのコピー」のコピー先として，Music Player Daemonのプレイリストディレクトリを指定して，コピー．
- Music Player Daemonの"Saved playlist"から聴きたい放送局を選局．
- 認証等の都合で，選局に10秒前後かかることがある．

