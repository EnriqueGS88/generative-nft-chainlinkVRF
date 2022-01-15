// The following code generates art.

function draw(uint id) public view returns (string) {
    uint a = uint(uint160(keccak256(abi.encodePacked(idToSeed[id]))));
    bytes memory output = new bytes(USIZE * (USIZE + 3) + 30);
    uint c;
    for (c = 0; c < 30; c++) {
        output[c] = prefix[c];
    }
    int x = 0;
    int y = 0;
    uint v = 0;
    uint value = 0;
    uint mod = (a % 11) + 5;
    
    bytes5 symbols;
    if (idToSymbolScheme[id] == 0) {
        revert();
    } else if (idToSymbolScheme[id] == 1) {
        symbols = 0x2E582F5C2E; // X/\
    } else if (idToSymbolScheme[id] == 2) {
        symbols = 0x2E2B2D7C2E; // +-|
    } else if (idToSymbolScheme[id] == 3) {
        symbols = 0x2E2F5C2E2E; // /\
    } else if (idToSymbolScheme[id] == 4) {
        symbols = 0x2E5C7C2D2F; // \|-/
    } else if (idToSymbolScheme[id] == 5) {
        symbols = 0x2E4F7C2D2E; // O|-
    } else if (idToSymbolScheme[id] == 6) {
        symbols = 0x2E5C5C2E2E; // \
    } else if (idToSymbolScheme[id] == 7) {
        symbols = 0x2E237C2D2B; // #|-+
    } else if (idToSymbolScheme[id] == 8) {
        symbols = 0x2E4F4F2E2E; // OO
    } else if (idToSymbolScheme[id] == 9) {
        symbols = 0x2E232E2E2E; // #
    } else {
        symbols = 0x2E234F2E2E; // #O
    }
    for (int i = int(0); i < SIZE; i++) {
        y = (2 * (i - HALF_SIZE) + 1);
        if (a % 3 == 1) {
            y = -y;
        } else if (a % 3 == 2) {
            y = abs(y);
        }
        y = y * int(a);
        for (int j = int(0); j < SIZE; j++) {
            x = (2 * (j - HALF_SIZE) + 1);
            if (a % 2 == 1) {
                x = abs(x);
            }
            x = x * int(a);
            v = uint(x * y / ONE) % mod;
            if (v < 5) {
                value = uint(symbols[v]);
            } else {
                value = 0x2E;
            }
            output[c] = byte(bytes32(value << 248));
            c++;
        }
        output[c] = byte(0x25);
        c++;
        output[c] = byte(0x30);
        c++;
        output[c] = byte(0x41);
        c++;
    }
    string memory result = string(output);
    return result;
}