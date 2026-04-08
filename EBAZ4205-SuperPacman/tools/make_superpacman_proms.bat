copy /b sp1-2.1c + sp1-1.1b cpu1_rom.bin
copy /b superpac.3l + superpac.3l + superpac.3l + superpac.3l spclut_rom.bin
copy /b spv-2.3f + spv-2.3f sprite0_rom.bin
copy /b spv-2.3f + spv-2.3f sprite1_rom.bin

make_vhdl_prom superpac.4c clut_rom.vhd
make_vhdl_prom superpac.4e char_rom.vhd
make_vhdl_prom spclut_rom.bin spclut_rom.vhd
make_vhdl_prom superpac.3m snd_rom.vhd

make_vhdl_prom sp1-6.3c gfx1_rom.vhd
make_vhdl_prom sprite0_rom.bin sprite0_rom.vhd
make_vhdl_prom sprite1_rom.bin sprite1_rom.vhd

make_vhdl_prom cpu1_rom.bin cpu1_rom.vhd
make_vhdl_prom spc-3.1k cpu2_rom.vhd

pause
