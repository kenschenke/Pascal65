import sys

if len(sys.argv) < 2:
    print("Usage: ", sys.argv[0], "<object file>")
    sys.exit(0)

file = open(sys.argv[1], "rb")

data = list(file.read())

file.close()

used = [0] * 256

print("Object file is", len(data), "bytes.")
print("Assembled start address", "${:x}{:02x}".format(data[1], data[0]))

for b in data[2:]:  # Skip first two items (the start address)
    used[b] = 1
    
print("These bytes do not appear in the object file:\n")

i = 0
while i < len(used):
    if used[i] == 0:
        print("${:02x}".format(i), end=" ")
    i += 1

print("\n")
