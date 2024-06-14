onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider <NULL>
add wave -noupdate /dut_harness/avmm_trans_s
add wave -noupdate /dut_harness/avmm_pins_s
add wave -noupdate /dut_harness/i2c_trans_s
add wave -noupdate /dut_harness/scl_s
add wave -noupdate -expand /dut_harness/sda_s
add wave -noupdate -divider <NULL>
add wave -noupdate /dut_harness/i2c_vu_gen(3)/i2c_vu_inst/sequencer_p/data
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {3105910000 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 384
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ps} {5155678500 ps}
