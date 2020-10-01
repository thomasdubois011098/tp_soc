#!/bin/bash -f
bin_path="/opt/mentor/modeltech/linux_x86_64"
ExecStep()
{
"$@"
RETVAL=$?
if [ $RETVAL -ne 0 ]
then
exit $RETVAL
fi
}
ExecStep $bin_path/vsim -64  -do "do {test_simulate.do}" -l simulate.log
