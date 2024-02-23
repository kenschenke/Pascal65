# This program reads the output PRG files from the build process and
# combines them into a runtime.lib file for use by the linker.

# The runtime.lib is a collection of modules in sequential order.
# Each module starts with a two-byte little-endian integer which
# is the number of bytes of that module.

# Because each module is a relocatable PRG file, the next two bytes
# of the module is the load address for the object code. This load
# address is used by the linker for relocating the code within the
# output PRG file.

import sys

if len(sys.argv) < 2:
    print("Usage: ", sys.argv[0], "<target>")
    sys.exit(0)

libs = []
file = open("mkruntime.cfg", "r")
while True:
    content = file.readline()
    if not content:
        break
    libs.append(content.strip())
file.close()

runtimefh = open("bin/" + sys.argv[1] + "/runtime.lib", "wb")

for lib in libs:
    libfh = open("lib/" + sys.argv[1] + "/" + lib + ".lib", "rb")
    data = list(libfh.read())
    libfh.close()
    runtimefh.write(bytearray([len(data) % 256, len(data) // 256]))
    runtimefh.write(bytearray(data))

runtimefh.write(b'\x00')
runtimefh.write(b'\x00')
runtimefh.close()
