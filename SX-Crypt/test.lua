
local morus = require'SX-Crypt.morus'
local bin = require "SX-Crypt.bin"
local md5 = require "SX-Crypt.md5"
local sha = require "SX-Crypt.sha3"

local xts = bin.hextos
local c = md5.hash("mysupersecretpassword")
c = sha.sha256(c)
print("Encrypted md5+sha3: "..c)

function genHex()
    return tostring(math.random(1000000000000000, 9999999999999999))..tostring(math.random(1000000000000000, 9999999999999999))
end

shell.execute("pastebin", 'get', 'ZVc6jbQj', 'app-test.lua')
shell.execute("pastebin", 'get', 'GvHP2Ebe', 'SX-Crypt/md5.lua')
shell.execute("pastebin", 'get', 'uin4LTj4', 'SX-Crypt/bin.lua')
shell.execute("pastebin", 'get', 'KGfkQ3St', 'SX-Crypt/sha3.lua')
shell.execute("pastebin", 'get', 'D2U7Q8W9', 'SX-Crypt/morus.lua')

local h=genHex()
local h2=genHex()

print("Hex: "..h, '/nLen: '..h:len())
print("Hex: "..h2, '/nLen: '..h2:len())

local k = xts(h)
local iv = xts(h2)
local m = "hello"


local crypted = morus.encrypt(k, iv, m)
local uncrypted = morus.decrypt(k, iv, crypted)


print("encrypted version: "..crypted)
print("decrypted version: "..uncrypted)

