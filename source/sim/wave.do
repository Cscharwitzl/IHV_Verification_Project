onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider <NULL>
add wave -noupdate /dut_harness/avmm_trans_s
add wave -noupdate /dut_harness/avmm_pins_s
add wave -noupdate -expand -subitemconfig {/dut_harness/i2c_trans_s(3) -expand} /dut_harness/i2c_trans_s
add wave -noupdate /dut_harness/scl_s
add wave -noupdate -expand /dut_harness/sda_s
add wave -noupdate -divider <NULL>
add wave -noupdate /dut_harness/i2c_multi_bus_controller_inst/reg_ctrl_s
add wave -noupdate /dut_harness/i2c_multi_bus_controller_inst/reg_status_s
add wave -noupdate /dut_harness/i2c_multi_bus_controller_inst/reg_enable_s
add wave -noupdate /dut_harness/i2c_vu_gen(3)/i2c_vu_inst/sequencer_p/addr_ack
add wave -noupdate /dut_harness/i2c_vu_gen(3)/i2c_vu_inst/sequencer_p/reg_ack
add wave -noupdate /dut_harness/i2c_vu_gen(3)/i2c_vu_inst/sequencer_p/sec_addr_ack
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {330000 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 642
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
WaveRestoreZoom {0 ps} {4501069714 ps}
