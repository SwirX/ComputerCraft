# SX-Crypt

A collection of hashing and cryptography algorithms built in Lua.

### Implementation details
I wanted a way to safely store passwords and securely send data across Rednet without folks snooping. This folder contains pure Lua implementations of common hashing algorithms like MD5, SHA3, and MORUS. The `bin.lua` and `test.lua` files were used to test binary conversions and verify the hashes.

### Development status
The hashing scripts (md5, sha3, and morus) work properly and output the correct hash strings. They can be dragged and dropped into other projects that require data encryption. No further development is needed unless I decide to add more algorithms like AES.
