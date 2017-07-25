#!/usr/bin/perl

# ==============================================================================
#   機能
#     ファイルをローテーションする
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
my $FLAG_OPT_MAKE_FILE = 0;
my $FLAG_OPT_PRESERVE = 0;

my $COMP = "";
my $COMP_OPTIONS = "";
my $COMP_EXT = "";

#my $DEBUG = 0;

my $arg;
my $file;
my $rc;
my ($count_end, $count);
my ($file_count_end, $file_count_end_COMP_EXT);
my ($dest_file, $src_file);
my ($file_LOG_START, $file_LOG_START_COMP_EXT);
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
    fil_rotate.sh [OPTIONS ...] FileName...

OPTIONS:
    -c ROTATION_COUNT
       Files are rotated ROTATION_COUNT times before being removed.
       Specify a positive integer as ROTATION_COUNT. (i.e. ROTATION_COUNT>0)
       (default: $ROTATION_COUNT)
    -f (force-rotation)
       Force rotation if original file is empty.
    -v (verbose)
       Verbose output.
    -m (make-file)
       Make empty file after rotation of original file.
    -p (preserve)
       Preserve mode/user/group of original file.
       Specifying this option is effective only when '-m' option is specified.
       This option is ignored on the following systems:
         MSWin32
    -s LOG_START
       This is the number to use as the base for rotation.
       Specify 0 or a positive integer as LOG_START. (i.e. LOG_START>=0)
       (default: $LOG_START)
    --comp=COMP
       COMP : {gzip}
       Specify program name to compress the rotated file.
    --comp_options="COMP_OPTIONS ..."
       Specify COMP program options.
    --help
       Display this help and exit.
EOF
}

use Common_pl::Cmd_v;
use Common_pl::Is_fil_empty;
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
	"m" => \$FLAG_OPT_MAKE_FILE,
	"p" => \$FLAG_OPT_PRESERVE,
	"comp=s" => sub {
		if ( $_[1] eq "gzip" ) {
			$COMP = $_[1];
		} else {
			print STDERR "-E Argument to \"--$_[0]\" is invalid -- \"$_[1]\"\n";
			USAGE();exit 1;
		}
	},
	"comp_options=s" => sub {
		$COMP_OPTIONS = ( ($COMP_OPTIONS eq "") ? "" : "$COMP_OPTIONS " ) . $_[1];
	},
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

# 変数定義(引数のチェック後)
if ( $COMP eq "gzip" ) {
	$COMP_EXT = "gz";
}

# 作業開始前処理
PRE_PROCESS();

#####################
# メインループ 開始 #
#####################

foreach $arg (@ARGV) {
	$file = File::Spec->catfile("$arg");
	# 指定ファイルが存在しない場合
	if ( not -f "$file" ) {
		print STDERR "-W \"$file\" not a file, skipped\n";
	# 指定ファイルが存在する場合
	} else {
		# 指定ファイルが空ファイルである場合
		$rc = IS_FIL_EMPTY("$file");
		if ( $rc == 0 ) {
			# FORCE_ROTATION オプションが指定されていない場合
			if ( not $FLAG_OPT_FORCE_ROTATION ) {
				if ( $FLAG_OPT_VERBOSE ) { print "-I \"$file\" file is empty, skipped\n"; }
				next;
			}
		}
		# カウンタの初期化
		$count_end = $LOG_START + $ROTATION_COUNT;
		$count = $count_end;
		# 指定ファイル.count_end.COMP_EXT が存在しない場合
		$file_count_end = "$file.$count_end";
		$file_count_end_COMP_EXT = "$file_count_end" . ( ($COMP_EXT eq "") ? "" : ".$COMP_EXT" );
		if ( not -e "$file_count_end_COMP_EXT" ) {
			if ( $FLAG_OPT_VERBOSE ) { print "-I old \"$file_count_end_COMP_EXT\" not exist\n"; }
		# 指定ファイル.count_end.COMP_EXT が存在する場合
		} else {
			# 指定ファイル.count_end.COMP_EXT の削除
			if ( $FLAG_OPT_VERBOSE ) { print "-I removing old \"$file_count_end_COMP_EXT\"\n"; }
			$rc = unlink("$file_count_end_COMP_EXT");
			if ( $rc != 1 ) {
				print STDERR "-E Command has ended unsuccessfully.\n";
				POST_PROCESS();exit 1;
			}
		}
		# カウンタ>0 の場合はループ
		while ($count > 0) {
			$dest_file = "$file.$count" . ( ($COMP_EXT eq "") ? "" : ".$COMP_EXT" );
			$count = $count - 1;
			$src_file = "$file.$count" . ( ($COMP_EXT eq "") ? "" : ".$COMP_EXT" );
			# src_file が存在しない場合
			if ( not -e "$src_file" ) {
				if ( $FLAG_OPT_VERBOSE ) { print "-I old \"$src_file\" not exist\n"; }
			# src_file が存在する場合
			} else {
				# src_file をdest_file に移動
				if ( $FLAG_OPT_VERBOSE ) { print "-I renaming \"$src_file\" to \"$dest_file\"\n"; }
				$rc = rename("$src_file", "$dest_file");
				if ( $rc != 1 ) {
					print STDERR "-E Command has ended unsuccessfully.\n";
					POST_PROCESS();exit 1;
				}
			}
		}
		# 指定ファイル.LOG_START.COMP_EXT が存在しない場合
		$file_LOG_START = "$file.$LOG_START";
		$file_LOG_START_COMP_EXT = "$file_LOG_START" . ( ($COMP_EXT eq "") ? "" : ".$COMP_EXT" );
		if ( not -e "$file_LOG_START_COMP_EXT" ) {
			if ( $FLAG_OPT_VERBOSE ) { print "-I old \"$file_LOG_START_COMP_EXT\" not exist\n"; }
		# 指定ファイル.LOG_START.COMP_EXT が存在する場合
		} else {
			# 指定ファイル.LOG_START.COMP_EXT の削除
			if ( $FLAG_OPT_VERBOSE ) { print "-I removing old \"$file_LOG_START_COMP_EXT\"\n"; }
			$rc = unlink("$file_LOG_START_COMP_EXT");
			if ( $rc != 1 ) {
				print STDERR "-E Command has ended unsuccessfully.\n";
				POST_PROCESS();exit 1;
			}
		}
		# 指定ファイルを指定ファイル.LOG_START に移動
		if ( $FLAG_OPT_VERBOSE ) { print "-I renaming \"$file\" to \"$file.$LOG_START\"\n"; }
		$rc = rename("$file", "$file_LOG_START");
		if ( $rc != 1 ) {
			print STDERR "-E Command has ended unsuccessfully.\n";
			POST_PROCESS();exit 1;
		}
		# MAKE_FILE オプションが指定されている場合
		if ( $FLAG_OPT_MAKE_FILE ) {
			# ファイルの作成
			if ( $FLAG_OPT_VERBOSE ) { print "-I creating new file \"$file\"\n"; }
			if ( not defined(open(FILE, '>', "$file")) ) {
				print STDERR "-E Command has ended unsuccessfully.\n";
				POST_PROCESS();exit 1;
			}
			close(FILE);
			# PRESERVE オプションが指定されている場合
			if ( $FLAG_OPT_PRESERVE ) {
				if ( $^O =~ m#^(?:MSWin32)$# ) {
					print STDERR "-W \"-p\" option is specified, but they are ignored on \"$^O\" system\n";
				} else {
					# 指定ディレクトリのモード・オーナ・グループ取得
					($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = lstat("$file_LOG_START");
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
					# ファイルのオーナ・グループ設定
					if ( $FLAG_OPT_VERBOSE ) { print "-I changing new file user=$uname group=$gname\n"; }
					$rc = chown($uid, $gid, "$file");
					if ( $rc < 1 ) {
						print STDERR "-E Command has ended unsuccessfully.\n";
						POST_PROCESS();exit 1;
					}
					# ファイルのモード設定
					if ( $FLAG_OPT_VERBOSE ) { print "-I changing new file mode=$mod_str\n"; }
					$rc = chmod($mod_num, "$file");
					if ( $rc < 1 ) {
						print STDERR "-E Command has ended unsuccessfully.\n";
						POST_PROCESS();exit 1;
					}
				}
			}
		}
		# 指定ファイル.LOG_STARTを圧縮
		if ( not "$COMP" eq "" ) {
			if ( $FLAG_OPT_VERBOSE ) { print "-I compressing \"$file.$LOG_START\"\n"; }
			$rc = SYS "$COMP $COMP_OPTIONS '$file_LOG_START'";
			if ( $rc != 0 ) {
				print STDERR "-E Command has ended unsuccessfully.\n";
				POST_PROCESS();exit 1;
			}
		}
		# 指定ファイル.count_end.COMP_EXT が存在しない場合
		if ( not -e "$file_count_end_COMP_EXT" ) {
			if ( $FLAG_OPT_VERBOSE ) { print "-I old \"$file_count_end_COMP_EXT\" not exist\n"; }
		# 指定ファイル.count_end.COMP_EXT が存在する場合
		} else {
			# 指定ファイル.count_end.COMP_EXT の削除
			if ( $FLAG_OPT_VERBOSE ) { print "-I removing old \"$file_count_end_COMP_EXT\"\n"; }
			$rc = unlink("$file_count_end_COMP_EXT");
			if ( $rc != 1 ) {
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

