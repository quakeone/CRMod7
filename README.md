# CRMod 7: ClanRing Multiplayer Mod

An advanced server mod for Quake 1 competitive multiplayer, CRMod 7 is a modern evolution of the classic ClanRing/CRMod series. Designed as an all-in-one tournament mod (similar to [KTX](https://github.com/QW-Group/ktx) for QuakeWorld), CRMod 7 supports multiple game modes including Clan Arena, Capture the Flag, Team Deathmatch, Free-for-All, Rocket Arena, and specialized modes like Airshot and DMM4.

**Engine Requirements:** CRMod 7 requires FTE extensions and must be run on QSS-M or FTEsv binaries.

Based on the original [CRMod](https://github.com/jp-grossman/crmod) and [CRCTF](https://github.com/timbergeron/crctf28d) code by JP Grossman, with extensive enhancements by R00k and the community.

## 🎮 Game Modes

### Core Modes
- **Team Deathmatch (TDM)** - Classic team-based combat with match timer and spawning system
- **Capture the Flag (CTF)** - ThreeWave-style CTF with hook support and enhanced features
- **Free-for-All (FFA/Normal)** - Standard deathmatch mode and public CTF
- **Practice Mode** - Full inventory, self-damage, unlimited time for training

### Arena Modes
- **Clan Arena (CA)** - Round-based elimination with full starting loadout
- **Clan Arena Wipeout** - CA variant with timed respawning
- **Rocket Arena (RA)** - Tournament-style dueling with queue system
- **Airshot Mode** - Specialized mode focusing on mid-air rocket combat
- **DMM4 Mode** - Fast-paced 1 on 1 with 3 min deathmatch arena

## 🛠️ Compiling the Source

### Prerequisites
1. **FTEQCC Compiler** - Download from [fteqcc.org](https://www.fteqcc.org)
2. **CRmod 7 Source Code** - Download from GitHub as ZIP or clone the repository

### Compilation Steps

#### Windows
1. **Download FTEQCC**
   - Go to [fteqcc.org](https://www.fteqcc.org/dl/fteqcc_win64.zip) and download fteqcc_win64.zip
   - Extract the zip file and copy `fteqcc64.exe` to your CRmod 7 project folder

2. **Download CRMod 7 Source**
   - Download the CRmod 7 source code from GitHub (Download ZIP button)
   - Extract to a folder like `C:\crmod7`

3. **Compile the mod**
   ```cmd
   # Option 1: Command line
   # Open Command Prompt in the CRmod 7 folder
   fteqcc64.exe -src src
   
   # Option 2: GUI
   # Double-click fteqcc64.exe to open the GUI
   # Click "Open Source File" and select src/progs.src
   # Click compile
   
#### Linux
1. **Download FTEQCC**
   ```bash
   # Download and extract FTEQCC for Linux
   wget https://www.fteqcc.org/dl/fteqcc_linux64.zip
   unzip fteqcc_linux64.zip
   ```

2. **Download CRMod 7 Source**
   ```bash
   # Download source code (or use git clone)
   wget https://github.com/yourusername/crmod7/archive/main.zip
   unzip main.zip
   cd crmod7-main
   ```

3. **Compile the mod**
   ```bash
   ./fteqcc64 -src src

### ✅ Output Files

After compiling on either platform, the following output files will be generated in the `src/` directory:

- `progs.dat` — server-side QuakeC binary
- `csprogs.dat` — optional client-side binary (used for HUD/menu effects, if enabled)

### Source Files
- **progs.src** - Server-side compilation script
- **csprogs.src** - Client-side compilation script  
- **src/** - Main source code directory containing all .qc files

### GitHub Actions
The repository includes automated compilation via GitHub Actions. Every push triggers a build that:
1. Downloads the appropriate FTEQCC compiler
2. Compiles both server and client code
3. Uploads the compiled .dat files as artifacts

## 💬 Contact & Community

### Join the Community
For questions, support, or to connect with other players:

**Discord:** [NetQuake Players Discord](https://discord.quakeone.com)
- **#tech-talk** - General discussion and questions
- **#github** - Development discussion and technical support

The NetQuake community is friendly and welcoming to both new and experienced players. Don't hesitate to ask questions!