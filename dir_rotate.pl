#!/usr/bin/perl

# ==============================================================================
#   機能
#     ディレクトリをローテーションする
#   構文
#     USAGE 参照
#
#   Copyright (c) 2011-2017 Yukio Shiiya
#
#   This software is released under the MIT License.
#   https://opensource.org/licenses/MIT
# ==============================================================================

######################################################################
# 基本設定
######################################################################
use strict;
use warnings;

use File::Path;
use File::Spec;
use Getopt::Long qw(GetOptionsFromArray :config gnu_getopt no_ignore_case);

my $s_err = "";
$SIG{__DIE__} = $SIG{__WARN__} = sub { $s_err = $_[0]; };

######################################################################
# 変数定義
######################################################################
my $ROTATION_COUNT = 7;
my $LOG_START = 1;

my $FLAG_OPT_FORCE_ROTATION = 0;
my $FLAG_OPT_VERBOSE = 0;
my $FLAG_OPT_MAKE_DIR = 0;
my $FLAG_OPT_PRESERVE = 0;

#my $DEBUG = 0;

my $arg;
my $dir;
my $rc;
my ($count_end, $count);
my ($dir_count_end);
my ($dest_dir, $src_dir);
my ($dir_LOG_START);
my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks);
my ($mod_num, $mod_str);
my ($uname, $gname);
my %uname = ();
my %gname = ();

######################################################################
# 関数定義
######################################################################
sub PRE_PROCESS {
}

sub POST_PROCESS {
}

sub USAGE {
	print STDOUT <<EOF;
Usage:
    dir_rotate.sh [OPTIONS ...] DirName...

OPTIONS:
    -c ROTATION_COUNT
       Directories are rotated ROTATION_COUNT times before being removed.
       Specify a positive integer as ROTATION_COUNT. (i.e. ROTATION_COUNT>0)
       (default: $ROTATION_COUNT)
    -f (force-rotation)
       Force rotation if original directory is empty.
    -v (verbose)
       Verbose output.
    -m (make-dir)
       Make empty directory after rotation of original directory.
    -p (preserve)
       Preserve mode/user/group of original directory.
       Specifying this option is effective only when '-m' option is specified.
       This option is ignored on the following systems:
         MSWin32
    -s LOG_START
       This is the number to use as the base for rotation.
       Specify 0 or a positive integer as LOG_START. (i.e. LOG_START>=0)
       (default: $LOG_START)
    --help
       Display this help and exit.
EOF
}

use Common_pl::Is_dir_empty;
use Common_pl::Is_numeric;

######################################################################
# メインルーチン
######################################################################

# オプションのチェック
if ( not eval { GetOptionsFromArray( \@ARGV,
	"c=s" => sub {
		# 指定された文字列が数値か否かのチェック
		$rc = IS_NUMERIC("$_[1]");
		if ( $rc != 0 ) {
			print STDERR "-E Argument to \"-$_[0]\" not numeric -- \"$_[1]\"\n";
			USAGE();exit 1;
		}
		if ( "-$_[0]" eq "-c" ) {
			# 指定された数値のチェック
			if ( $_[1] <= 0 ) {
				print STDERR "-E Argument to \"-$_[0]\" is invalid -- \"$_[1]\"\n";
				USAGE();exit 1;
			}
			$ROTATION_COUNT = "$_[1]";
		}
	},
	"s=s" => sub {
		# 指定された文字列が数値か否かのチェック
		$rc = IS_NUMERIC("$_[1]");
		if ( $rc != 0 ) {
			print STDERR "-E Argument to \"-$_[0]\" not numeric -- \"$_[1]\"\n";
			USAGE();exit 1;
		}
		if ( "-$_[0]" eq "-s" ) {
			# 指定された数値のチェック
			if ( $_[1] < 0 ) {
				print STDERR "-E Argument to \"-$_[0]\" is invalid -- \"$_[1]\"\n";
				USAGE();exit 1;
			}
			$LOG_START = "$_[1]";
		}
	},
	"f" => \$FLAG_OPT_FORCE_ROTATION,
	"v" => \$FLAG_OPT_VERBOSE,
	"m" => \$FLAG_OPT_MAKE_DIR,
	"p" => \$FLAG_OPT_PRESERVE,
	"help" => sub {
		USAGE();exit 0;
	},
) } ) {
	print STDERR "-E $s_err\n";
	USAGE();exit 1;
}

# 引数のチェック
if ( scalar(@ARGV) == 0 ) {
	print STDERR "-E Missing 1st argument\n";
	USAGE();exit 1;
}

# 作業開始前処理
PRE_PROCESS();

#####################
# メインループ 開始 #
#####################

foreach $arg (@ARGV) {
	$dir = File::Spec->catdir("$arg");
	# 指定ディレクトリが存在しない場合
	if ( not -d "$dir" ) {
		print STDERR "-W \"$dir\" not a directory, skipped\n";
	# 指定ディレクトリが存在する場合
	} else {
		# 指定ディレクトリが空ディレクトリである場合
		$rc = IS_DIR_EMPTY("$dir");
		if ( $rc == 0 ) {
			# FORCE_ROTATION オプションが指定されていない場合
			if ( not $FLAG_OPT_FORCE_ROTATION ) {
				if ( $FLAG_OPT_VERBOSE ) { print "-I \"$dir\" directory is empty, skipped\n"; }
				next;
			}
		}
		# カウンタの初期化
		$count_end = $LOG_START + $ROTATION_COUNT;
		$count = $count_end;
		# 指定ディレクトリ.count_end が存在しない場合
		$dir_count_end = "$dir.$count_end";
		if ( not -e "$dir_count_end" ) {
			if ( $FLAG_OPT_VERBOSE ) { print "-I old \"$dir_count_end\" not exist\n"; }
		# 指定ディレクトリ.count_end が存在する場合
		} else {
			# 指定ディレクトリ.count_end の削除
			if ( $FLAG_OPT_VERBOSE ) { print "-I removing old \"$dir_count_end\"\n"; }
			$rc = rmtree("$dir_count_end");
			if ( $rc < 1 ) {
				print STDERR "-E Command has ended unsuccessfully.\n";
				POST_PROCESS();exit 1;
			}
		}
		# カウンタ>0 の場合はループ
		while ($count > 0) {
			$dest_dir = "$dir.$count";
			$count = $count - 1;
			$src_dir = "$dir.$count";
			# src_dir が存在しない場合
			if ( not -e "$src_dir" ) {
				if ( $FLAG_OPT_VERBOSE ) { print "-I old \"$src_dir\" not exist\n"; }
			# src_dir が存在する場合
			} else {
				# src_dir をdest_dir に移動
				if ( $FLAG_OPT_VERBOSE ) { print "-I renaming \"$src_dir\" to \"$dest_dir\"\n"; }
				$rc = rename("$src_dir", "$dest_dir");
				if ( $rc != 1 ) {
					print STDERR "-E Command has ended unsuccessfully.\n";
					POST_PROCESS();exit 1;
				}
			}
		}
		# 指定ディレクトリ.LOG_START が存在しない場合
		$dir_LOG_START = "$dir.$LOG_START";
		if ( not -e "$dir_LOG_START" ) {
			if ( $FLAG_OPT_VERBOSE ) { print "-I old \"$dir_LOG_START\" not exist\n"; }
		# 指定ディレクトリ.LOG_START が存在する場合
		} else {
			# 指定ディレクトリ.LOG_START の削除
			if ( $FLAG_OPT_VERBOSE ) { print "-I removing old \"$dir_LOG_START\"\n"; }
			$rc = rmtree("$dir_LOG_START");
			if ( $rc < 1 ) {
				print STDERR "-E Command has ended unsuccessfully.\n";
				POST_PROCESS();exit 1;
			}
		}
		# 指定ディレクトリを指定ディレクトリ.LOG_START に移動
		if ( $FLAG_OPT_VERBOSE ) { print "-I renaming \"$dir\" to \"$dir_LOG_START\"\n"; }
		$rc = rename("$dir", "$dir_LOG_START");
		if ( $rc != 1 ) {
			print STDERR "-E Command has ended unsuccessfully.\n";
			POST_PROCESS();exit 1;
		}
		# MAKE_DIR オプションが指定されている場合
		if ( $FLAG_OPT_MAKE_DIR ) {
			# ディレクトリの作成
			if ( $FLAG_OPT_VERBOSE ) { print "-I creating new directory \"$dir\"\n"; }
			$rc = mkpath("$dir");
			if ( $rc < 1 ) {
				print STDERR "-E Command has ended unsuccessfully.\n";
				POST_PROCESS();exit 1;
			}
			# PRESERVE オプションが指定されている場合
			if ( $FLAG_OPT_PRESERVE ) {
				if ( $^O =~ m#^(?:MSWin32)$# ) {
					print STDERR "-W \"-p\" option is specified, but they are ignored on \"$^O\" system\n";
				} else {
					# 指定ディレクトリのモード・オーナ・グループ取得
					($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = lstat("$dir_LOG_START");
					$mod_num = $mode & 07777;
					$mod_str = sprintf("%04lo", $mod_num);
					# uname
					if ( defined($uname{$uid}) ) {
						$uname = $uname{$uid};
					} else {
						$uname = getpwuid($uid);
						if ( defined($uname) ) { $uname{$uid} = $uname; } else { $uname = $uid; }
					}
					# gname
					if ( defined($gname{$gid}) ) {
						$gname = $gname{$gid};
					} else {
						$gname = getgrgid($gid);
						if ( defined($gname) ) { $gname{$gid} = $gname; } else { $gname = $gid; }
					}
					# ディレクトリのオーナ・グループ設定
					if ( $FLAG_OPT_VERBOSE ) { print "-I changing new directory user=$uname group=$gname\n"; }
					$rc = chown($uid, $gid, "$dir");
					if ( $rc < 1 ) {
						print STDERR "-E Command has ended unsuccessfully.\n";
						POST_PROCESS();exit 1;
					}
					# ディレクトリのモード設定
					if ( $FLAG_OPT_VERBOSE ) { print "-I changing new directory mode=$mod_str\n"; }
					$rc = chmod($mod_num, "$dir");
					if ( $rc < 1 ) {
						print STDERR "-E Command has ended unsuccessfully.\n";
						POST_PROCESS();exit 1;
					}
				}
			}
		}
		# 指定ディレクトリ.count_end が存在しない場合
		if ( not -e "$dir_count_end" ) {
			if ( $FLAG_OPT_VERBOSE ) { print "-I old \"$dir_count_end\" not exist\n"; }
		# 指定ディレクトリ.count_end が存在する場合
		} else {
			# 指定ディレクトリ.count_end の削除
			if ( $FLAG_OPT_VERBOSE ) { print "-I removing old \"$dir_count_end\"\n"; }
			$rc = rmtree("$dir_count_end");
			if ( $rc < 1 ) {
				print STDERR "-E Command has ended unsuccessfully.\n";
				POST_PROCESS();exit 1;
			}
		}
	}
}

#####################
# メインループ 終了 #
#####################

# 作業終了後処理
POST_PROCESS();exit 0;

