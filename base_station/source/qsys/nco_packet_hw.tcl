# _hw.tcl file for nco_packet
package require -exact qsys 14.0

# module properties
set_module_property NAME {nco_packet_export}
set_module_property DISPLAY_NAME {nco_packet_export_display}

# default module properties
set_module_property VERSION {1.0}
set_module_property GROUP {default group}
set_module_property DESCRIPTION {default description}
set_module_property AUTHOR {author}

set_module_property COMPOSITION_CALLBACK compose
set_module_property opaque_address_map false

proc compose { } {
    # Instances and instance parameters
    # (disabled instances are intentionally culled)
    add_instance FFtMagnitude_0 FFtMagnitude 1.0
    set_instance_parameter_value FFtMagnitude_0 {FFT_WIDTH} {16}
    set_instance_parameter_value FFtMagnitude_0 {PACKET_LEN} {8192}

    add_instance NcoController_0 NcoController 1.0
    set_instance_parameter_value NcoController_0 {CLK_FREQ} {50000000}
    set_instance_parameter_value NcoController_0 {FFT_WIDTH} {16}
    set_instance_parameter_value NcoController_0 {NCO_FREQ} {1000000}
    set_instance_parameter_value NcoController_0 {NCO_PHASE_WIDTH} {32}
    set_instance_parameter_value NcoController_0 {NCO_WIDTH} {16}
    set_instance_parameter_value NcoController_0 {PACKET_LEN} {8192}

    add_instance PacketDecimation_0 PacketDecimation 1.0
    set_instance_parameter_value PacketDecimation_0 {CLK_FREQ} {50000000}
    set_instance_parameter_value PacketDecimation_0 {DATA_WIDTH} {16}
    set_instance_parameter_value PacketDecimation_0 {FIX_ADDRESS_WIDTH} {16}
    set_instance_parameter_value PacketDecimation_0 {PACKET_LEN} {8192}
    set_instance_parameter_value PacketDecimation_0 {PACKET_RATE} {60}
    set_instance_parameter_value PacketDecimation_0 {USE_FIX_ADDRESS_WIDTH} {0}

    add_instance clk_0 clock_source 20.1
    set_instance_parameter_value clk_0 {clockFrequency} {50000000.0}
    set_instance_parameter_value clk_0 {clockFrequencyKnown} {1}
    set_instance_parameter_value clk_0 {resetSynchronousEdges} {NONE}

    add_instance fft_ii_0 altera_fft_ii 20.1
    set_instance_parameter_value fft_ii_0 {data_flow} {Variable Streaming}
    set_instance_parameter_value fft_ii_0 {data_rep} {Fixed Point}
    set_instance_parameter_value fft_ii_0 {direction} {Bi-directional}
    set_instance_parameter_value fft_ii_0 {dsp_resource_opt} {0}
    set_instance_parameter_value fft_ii_0 {engine_arch} {Quad Output}
    set_instance_parameter_value fft_ii_0 {hard_fp} {0}
    set_instance_parameter_value fft_ii_0 {hyper_opt} {0}
    set_instance_parameter_value fft_ii_0 {in_order} {Natural}
    set_instance_parameter_value fft_ii_0 {in_width} {16}
    set_instance_parameter_value fft_ii_0 {length} {8192}
    set_instance_parameter_value fft_ii_0 {num_engines} {1}
    set_instance_parameter_value fft_ii_0 {out_order} {Digit Reverse}
    set_instance_parameter_value fft_ii_0 {out_width} {16}
    set_instance_parameter_value fft_ii_0 {twid_width} {8}

    add_instance nco_ii_0 altera_nco_ii 20.1
    set_instance_parameter_value nco_ii_0 {apr} {32}
    set_instance_parameter_value nco_ii_0 {aprf} {32}
    set_instance_parameter_value nco_ii_0 {apri} {16}
    set_instance_parameter_value nco_ii_0 {aprp} {16}
    set_instance_parameter_value nco_ii_0 {arch} {large_rom}
    set_instance_parameter_value nco_ii_0 {cordic_arch} {parallel}
    set_instance_parameter_value nco_ii_0 {dpri} {5}
    set_instance_parameter_value nco_ii_0 {fmod_pipe} {1}
    set_instance_parameter_value nco_ii_0 {freq_out} {1.0}
    set_instance_parameter_value nco_ii_0 {fsamp} {50.0}
    set_instance_parameter_value nco_ii_0 {hyper_opt_select} {0}
    set_instance_parameter_value nco_ii_0 {mpr} {16}
    set_instance_parameter_value nco_ii_0 {numba} {1}
    set_instance_parameter_value nco_ii_0 {numch} {1}
    set_instance_parameter_value nco_ii_0 {pmod_pipe} {1}
    set_instance_parameter_value nco_ii_0 {trig_cycles_per_output} {1}
    set_instance_parameter_value nco_ii_0 {use_dedicated_multipliers} {1}
    set_instance_parameter_value nco_ii_0 {want_dither} {1}
    set_instance_parameter_value nco_ii_0 {want_freq_mod} {0}
    set_instance_parameter_value nco_ii_0 {want_phase_mod} {0}
    set_instance_parameter_value nco_ii_0 {want_sin_and_cos} {single_output}

    # connections and connection parameters
    add_connection FFtMagnitude_0.fftmagnitude PacketDecimation_0.fftin avalon_streaming

    add_connection NcoController_0.fftin fft_ii_0.sink avalon_streaming

    add_connection NcoController_0.ncoin nco_ii_0.in avalon_streaming

    add_connection clk_0.clk FFtMagnitude_0.clock clock

    add_connection clk_0.clk NcoController_0.clock clock

    add_connection clk_0.clk PacketDecimation_0.clock clock

    add_connection clk_0.clk fft_ii_0.clk clock

    add_connection clk_0.clk nco_ii_0.clk clock

    add_connection clk_0.clk_reset FFtMagnitude_0.reset reset

    add_connection clk_0.clk_reset NcoController_0.reset reset

    add_connection clk_0.clk_reset PacketDecimation_0.reset reset

    add_connection clk_0.clk_reset fft_ii_0.rst reset

    add_connection clk_0.clk_reset nco_ii_0.rst reset

    add_connection fft_ii_0.source FFtMagnitude_0.fftout avalon_streaming

    add_connection nco_ii_0.out NcoController_0.ncoout avalon_streaming

    # exported interfaces
    add_interface clk clock sink
    set_interface_property clk EXPORT_OF clk_0.clk_in
    add_interface packetdecimation_0_csr avalon slave
    set_interface_property packetdecimation_0_csr EXPORT_OF PacketDecimation_0.csr
    add_interface packetdecimation_0_mem avalon master
    set_interface_property packetdecimation_0_mem EXPORT_OF PacketDecimation_0.mem
    add_interface reset reset sink
    set_interface_property reset EXPORT_OF clk_0.clk_in_reset

    # interconnect requirements
    set_interconnect_requirement {$system} {qsys_mm.clockCrossingAdapter} {HANDSHAKE}
    set_interconnect_requirement {$system} {qsys_mm.enableEccProtection} {FALSE}
    set_interconnect_requirement {$system} {qsys_mm.insertDefaultSlave} {FALSE}
    set_interconnect_requirement {$system} {qsys_mm.maxAdditionalLatency} {1}
}
