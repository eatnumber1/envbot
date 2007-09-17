# This file is used to generate some, uh, generated files.
all: numerics

numerics:
	tools/build_numerics.sh > lib/numerics.sh

clean:
	rm -f *~ */*~

cleanlogs:
	rm -f logs/*.log


.PHONY: all numerics clean cleanlogs
