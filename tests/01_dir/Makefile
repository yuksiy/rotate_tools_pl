# System Configuration
srcdir = ../..

ifeq "$(ENVTYPE)" "win"
	PERL ?= $(SYSTEMDRIVE)/strawberry/perl/bin/perl.exe
else
	PERL ?= /usr/bin/perl
endif


# Inference Rules

# Macro Defines
PROJ = rotate_tools

test_root = "tmp/$(PROJ).test"

dir_rotate_options-1 = -v -m -p

test_max = 3

ls = ls --time-style="+%Y-%m-%d %H:%M:%S"

#通常のテストを行う場合
test_dir = "test_dir"
test_file = "test_file"

#スペースを含むディレクトリをテストする場合 (未成功)
#test_dir = "test dir"
#test_file = "test file"

test_dir_full_unix = /$(test_root)/$(test_dir)
test_file_full_unix = /$(test_root)/$(test_dir)/$(test_file)
ifeq "$(ENVTYPE)" "win"
	test_dir_full_native = $(shell cygpath -w $(test_dir_full_unix))
	test_file_full_native = $(shell cygpath -w $(test_file_full_unix))
else
	test_dir_full_native = $(test_dir_full_unix)
	test_file_full_native = $(test_file_full_unix)
endif


# Target List
all: \
				test \

# Test
test: \
				test1 \

test1: \
	test-CLEAN-ALL-FIRST-1 test-PREPARE-1-0_1 \
	test-DIR_FIND-BEFORE-1-0_1 DIR_ROTATE-1-0_1 \
	\
	test-CLEAN-PARTIAL-1-0_2 test-PREPARE-1-0_2 \
	test-DIR_FIND-BEFORE-1-0_2 DIR_ROTATE-1-0_2 \
	\
	test-CLEAN-PARTIAL-1-1_1 test-PREPARE-1-1_1 \
	test-DIR_FIND-BEFORE-1-1_1 DIR_ROTATE-1-1_1 \
	\
	test-CLEAN-PARTIAL-1-1_2 test-PREPARE-1-1_2 \
	test-DIR_FIND-BEFORE-1-1_2 DIR_ROTATE-1-1_2 \
	\
	test-CLEAN-ALL-LAST-1

testclean \
test-CLEAN-ALL-FIRST-1 test-CLEAN-ALL-LAST-1:
	@rm -fr "/$(test_root)"

test-CLEAN-PARTIAL-1-0_2 \
test-CLEAN-PARTIAL-1-1_1 test-CLEAN-PARTIAL-1-1_2:
	@rm -fr "$(test_dir_full_unix)"; \
	i=0; while [ $${i} -le $(test_max) ]; \
	do \
		rm -fr "$(test_dir_full_unix).$${i}"; \
		i=`expr $${i} + 1`; \
	done

test-PREPARE-1-0_1 test-PREPARE-1-0_2 \
test-PREPARE-1-1_1 test-PREPARE-1-1_2:
	@date_s=`date +%s --date="2010/12/30"`; \
	date=`perl -e "use POSIX qw(strftime); print strftime('%Y%m%d0000.00',localtime(\"$${date_s}\"))"`; \
	mkdir -p "$(test_dir_full_unix)"; \
	echo "test" > "$(test_file_full_unix)"; \
	touch -t $${date} "$(test_file_full_unix)"; \
	touch -t $${date} "$(test_dir_full_unix)"; \
	i=0; while [ $${i} -le $(test_max) ]; \
	do \
		mkdir -p "$(test_dir_full_unix).$${i}"; \
		echo "test" > "$(test_dir_full_unix).$${i}/$(test_file)_$${i}"; \
		date_s=`expr $${date_s} - 86400`; \
		date=`perl -e "use POSIX qw(strftime); print strftime('%Y%m%d0000.00',localtime(\"$${date_s}\"))"`; \
		touch -t $${date} "$(test_dir_full_unix).$${i}/$(test_file)_$${i}"; \
		touch -t $${date} "$(test_dir_full_unix).$${i}"; \
		i=`expr $${i} + 1`; \
	done

test-DIR_FIND-BEFORE-1-0_1 \
test-DIR_FIND-BEFORE-1-0_2 \
test-DIR_FIND-BEFORE-1-1_1 \
test-DIR_FIND-BEFORE-1-1_2:
	@find "$(test_dir_full_unix)"   -print | sort | xargs $(ls) -ald
	@find "$(test_dir_full_unix)."* -print | sort | xargs $(ls) -ald
	@echo "-I \"$@\" has ended successfully." ; echo

DIR_ROTATE-1-0_1:
	@s=0; c=1; \
	date_s=`date +%s --date="2011/01/01"`; \
	date=`perl -e "use POSIX qw(strftime); print strftime('%Y%m%d0000.00',localtime(\"$${date_s}\"))"`; \
	i=0; while [ $${i} -le $${c} ]; \
	do \
		(set -x; $(PERL) $(srcdir)/dir_rotate.pl -s $${s} -c $${c} $(dir_rotate_options-1) "$(test_dir_full_native)"); \
		if test $$? -ne 0; then exit 1; fi; \
		echo "test" > "$(test_file_full_unix)"; \
		touch -t $${date} "$(test_dir_full_unix)" "$(test_file_full_unix)"; \
		find              "$(test_dir_full_unix)"   -print | sort | xargs $(ls) -ald; \
		find              "$(test_dir_full_unix)."* -print | sort | xargs $(ls) -ald; \
		date_s=`expr $${date_s} + 86400`; \
		date=`perl -e "use POSIX qw(strftime); print strftime('%Y%m%d0000.00',localtime(\"$${date_s}\"))"`; \
		i=`expr $${i} + 1`; \
	done
	@echo "-I \"$@\" has ended successfully." ; echo

DIR_ROTATE-1-0_2:
	@s=0; c=2; \
	date_s=`date +%s --date="2011/01/01"`; \
	date=`perl -e "use POSIX qw(strftime); print strftime('%Y%m%d0000.00',localtime(\"$${date_s}\"))"`; \
	i=0; while [ $${i} -le $${c} ]; \
	do \
		(set -x; $(PERL) $(srcdir)/dir_rotate.pl -s $${s} -c $${c} $(dir_rotate_options-1) "$(test_dir_full_native)"); \
		if test $$? -ne 0; then exit 1; fi; \
		echo "test" > "$(test_file_full_unix)"; \
		touch -t $${date} "$(test_dir_full_unix)" "$(test_file_full_unix)"; \
		find              "$(test_dir_full_unix)"   -print | sort | xargs $(ls) -ald; \
		find              "$(test_dir_full_unix)."* -print | sort | xargs $(ls) -ald; \
		date_s=`expr $${date_s} + 86400`; \
		date=`perl -e "use POSIX qw(strftime); print strftime('%Y%m%d0000.00',localtime(\"$${date_s}\"))"`; \
		i=`expr $${i} + 1`; \
	done
	@echo "-I \"$@\" has ended successfully." ; echo

DIR_ROTATE-1-1_1:
	@s=1; c=1; \
	date_s=`date +%s --date="2011/01/01"`; \
	date=`perl -e "use POSIX qw(strftime); print strftime('%Y%m%d0000.00',localtime(\"$${date_s}\"))"`; \
	i=0; while [ $${i} -le $${c} ]; \
	do \
		(set -x; $(PERL) $(srcdir)/dir_rotate.pl -s $${s} -c $${c} $(dir_rotate_options-1) "$(test_dir_full_native)"); \
		if test $$? -ne 0; then exit 1; fi; \
		echo "test" > "$(test_file_full_unix)"; \
		touch -t $${date} "$(test_dir_full_unix)" "$(test_file_full_unix)"; \
		find              "$(test_dir_full_unix)"   -print | sort | xargs $(ls) -ald; \
		find              "$(test_dir_full_unix)."* -print | sort | xargs $(ls) -ald; \
		date_s=`expr $${date_s} + 86400`; \
		date=`perl -e "use POSIX qw(strftime); print strftime('%Y%m%d0000.00',localtime(\"$${date_s}\"))"`; \
		i=`expr $${i} + 1`; \
	done
	@echo "-I \"$@\" has ended successfully." ; echo

DIR_ROTATE-1-1_2:
	@s=1; c=2; \
	date_s=`date +%s --date="2011/01/01"`; \
	date=`perl -e "use POSIX qw(strftime); print strftime('%Y%m%d0000.00',localtime(\"$${date_s}\"))"`; \
	i=0; while [ $${i} -le $${c} ]; \
	do \
		(set -x; $(PERL) $(srcdir)/dir_rotate.pl -s $${s} -c $${c} $(dir_rotate_options-1) "$(test_dir_full_native)"); \
		if test $$? -ne 0; then exit 1; fi; \
		echo "test" > "$(test_file_full_unix)"; \
		touch -t $${date} "$(test_dir_full_unix)" "$(test_file_full_unix)"; \
		find              "$(test_dir_full_unix)"   -print | sort | xargs $(ls) -ald; \
		find              "$(test_dir_full_unix)."* -print | sort | xargs $(ls) -ald; \
		date_s=`expr $${date_s} + 86400`; \
		date=`perl -e "use POSIX qw(strftime); print strftime('%Y%m%d0000.00',localtime(\"$${date_s}\"))"`; \
		i=`expr $${i} + 1`; \
	done
	@echo "-I \"$@\" has ended successfully." ; echo

