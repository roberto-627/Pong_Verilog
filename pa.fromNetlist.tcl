
# PlanAhead Launch Script for Post-Synthesis floorplanning, created by Project Navigator

create_project -name TWO_PLAYER_PONG -dir "C:/Users/Elliot/Documents/Xilinx/TWO_PLAYER_PONG/planAhead_run_3" -part xc6slx9tqg144-3
set_property design_mode GateLvl [get_property srcset [current_run -impl]]
set_property edif_top_file "C:/Users/Elliot/Documents/Xilinx/TWO_PLAYER_PONG/Pong.ngc" [ get_property srcset [ current_run ] ]
add_files -norecurse { {C:/Users/Elliot/Documents/Xilinx/TWO_PLAYER_PONG} }
set_property target_constrs_file "mojoV3.ucf" [current_fileset -constrset]
add_files [list {mojoV3.ucf}] -fileset [get_property constrset [current_run]]
link_design
