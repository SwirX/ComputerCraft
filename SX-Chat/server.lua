print("Starting up...")
print("SX-Chat - Server")

local alphanum = {"a","b","c","d","e","f","g","h","i","j","k","l","m","o","p","q","r","s","t","u","v","w","x","y","z","1","2","3","4","5","6","7","8","9","#",";",":","!","<",">","?","/","%","*","$","-","_","&","@",","}

function PSC()
    local protocol = ""
    for i = 0, 10 do
        local char = string.char(math.random(32,126))
        protocol = protocol..char
    end
    return protocol
end

function inp(prompt)
    if prompt then print(prompt)end
    return read()
end

function inArr(t, obj)
    for i, v in pairs(t) do
        if v == tostring(obj) then
            return true, tostring(obj), i
        end
    end
end

function pw(prompt)
    if prompt then print(prompt)end
    local typing = true
    local pass = ""
    local hidden = true
    while typing do
        local _, key = os.pullEvent('key')
        if key == keys.enter then
            typing = false
        elseif key == keys.backspace then
            pass = pass:sub(0, #pass-1)
        elseif inArr(alphanum, key) then
            pass = pass + key
        elseif key == keys.leftAlt or key == keys.rightAlt then
            hidden = not hidden
        end
        term.clearLine()
        if hidden then term.write("*"*#pass) else term.write(pass) end
    end
end

function signin()
    print("Create an account")
    term.setTextColor(colors.red)
    print("Note: do not use you real loggin info")
    term.setTextColor(colors.white)
    local usn = inp("username: ")
    local password = pw("password: ")
    local repassword = pw("re-enter the password: ")
end

pw("testing pw:     ")