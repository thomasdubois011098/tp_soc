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
ExecStep source ./test_compile.do 2>&1 | tee -a compile.log
