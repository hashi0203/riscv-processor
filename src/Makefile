ALL_SRC=$(shell ls *.sv)
TEST_SRC=test_core.sv
CIRC_SRC=$(filter-out $(TEST_SRC), $(ALL_SRC))

all:
  xvlog --sv $(TEST_SRC) $(CIRC_SRC)
  xelab -debug typical test_core -s test_core.sim
  xsim --runall test_core.sim