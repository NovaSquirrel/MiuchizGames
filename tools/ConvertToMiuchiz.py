data = [0] * 0x200000

with open('game.dat', 'rb') as f:
    code = f.read()

code = list(code)
data[0x8000:0x8000+len(code)] = code

data = bytes(data)

with open('tools/flash.dat', 'wb') as f:
    f.write(data)
