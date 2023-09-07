#include <sourcemod>

public Plugin myinfo =
{
    name = "1.13.3 Melee Update Reversal",
    author = "Dysphie",
    description = "Reverts 'Fixed melee traces ignoring objects and walls' for ignoring valid hits on clustered zombies",
    version = "1.0.0",
    url = "https://github.com/dysphie/nmrih-melee-update-reversal"
};

public void OnPluginStart()
{
    ConVar cvVersion = FindConVar("nmrih_version");
    if (cvVersion) 
    {
        char version[16];
        cvVersion.GetString(version, sizeof(version));
        if (!StrEqual(version, "1.13.3")) {
            SetFailState("This plugin is only needed in patch 1.13.3. Remove it");
        }

        SillyPatch();
    }
}

void SillyPatch()
{
    GameData gamedata = new GameData("melee-update-reversal.games");
    if (!gamedata) {
        SetFailState("You forgot to copy the gamedata file");
    }

    Address fn = gamedata.GetAddress("CheckMeleeHit");
    if (!fn) {
        SetFailState("Failed to find address for CheckMeleeHit");
    }

    int windows = gamedata.GetOffset("Windows");
    if (windows) 
    {
        PrintToServer("Applying Windows patch");
        PatchByte(fn, 0x346, 0x74, 0xEB); // jz to jmp
    } 
    else 
    {
        PrintToServer("Applying Linux patch");
        PatchByte(fn, 0x5E4, 0x0F, 0x90); // jnz to nop x6
        PatchByte(fn, 0x5E5, 0x85, 0x90); 
        PatchByte(fn, 0x5E6, 0x76, 0x90); 
        PatchByte(fn, 0x5E7, 0x05, 0x90); 
        PatchByte(fn, 0x5E8, 0x00, 0x90);
        PatchByte(fn, 0x5E9, 0x00, 0x90);
    }
}

void PatchByte(Address addr, int offset, int verify, int patch)
{
	int original = LoadFromAddress(addr + view_as<Address>(offset), NumberType_Int8);
	if (original != verify && original != patch) {
		SetFailState("Byte patcher expected %x, got %x. Plugin needs updating", verify, original);
	}
	StoreToAddress(addr + view_as<Address>(offset), patch, NumberType_Int8);
}