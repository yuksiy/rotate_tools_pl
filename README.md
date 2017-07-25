# rotate_tools_pl

## 概要

ディレクトリやファイルをローテーション (Perl)

## 使用方法

### dir_rotate.pl

指定されたディレクトリを7回までローテーションさせた後、削除します。  
オリジナルのディレクトリを回転させた後、
オリジナルのディレクトリのモード/オーナー/グループを維持した空ディレクトリを作成します。

    $ dir_rotate.pl -c 7 -m -p ディレクトリ名

### fil_rotate.pl

指定されたファイルを7回までローテーションさせた後、削除します。  
オリジナルのファイルを回転させた後、
オリジナルのファイルのモード/オーナー/グループを維持した空ファイルを作成します。

    $ fil_rotate.pl -c 7 -m -p ファイル名

### その他

* 上記で紹介したツールの詳細については、「ツール名 --help」を参照してください。

## 動作環境

OS:

* Linux
* Cygwin

依存パッケージ または 依存コマンド:

* make (インストール目的のみ)
* perl
* [common_pl](https://github.com/yuksiy/common_pl)

## インストール

ソースからインストールする場合:

    (Linux, Cygwin の場合)
    # make install

fil_pkg.plを使用してインストールする場合:

[fil_pkg.pl](https://github.com/yuksiy/fil_tools_pl/blob/master/README.md#fil_pkgpl) を参照してください。

## インストール後の設定

環境変数「PATH」にインストール先ディレクトリを追加してください。

## 最新版の入手先

<https://github.com/yuksiy/rotate_tools_pl>

## License

MIT License. See [LICENSE](https://github.com/yuksiy/rotate_tools_pl/blob/master/LICENSE) file.

## Copyright

Copyright (c) 2011-2017 Yukio Shiiya
