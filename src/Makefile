MAIN_MODULE=core
ALL_SRC=$(shell ls *.sv)
TEST_SRC=test_$(MAIN_MODULE).sv
CIRC_SRC=$(filter-out $(TEST_SRC), $(ALL_SRC))

all:
	xvlog --sv $(TEST_SRC) $(CIRC_SRC)
	xelab -debug typical test_$(MAIN_MODULE) -s test_$(MAIN_MODULE).sim
	xsim --runall test_$(MAIN_MODULE).sim