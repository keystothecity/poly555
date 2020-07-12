include <lib/values.scad>;

use <lib/basic_shapes.scad>;
use <lib/battery.scad>;
use <lib/enclosure.scad>;
use <lib/keys.scad>;
use <lib/mount_stilt.scad>;
use <lib/mounting_rail.scad>;
use <lib/pcb.scad>;
use <lib/speaker.scad>;
use <lib/switch.scad>;
use <lib/utils.scad>;

module assembly(
    key_gutter = 1,
    natural_key_exposed_height = 2,
    accidental_key_extra_height = 2,

    enclosure_wall = 2.5,
    enclosure_inner_wall = 1.2,
    enclosure_to_component_gutter = 2,
    enclosure_to_component_z_clearance = 2,
    enclosure_chamfer = 2,
    enclosure_rounding = 24,

    bottom_component_clearance = 1,

    mount_length = 6,

    tolerance = .1,

    keys_count = 13,
    starting_natural_key_index = 3,

    pcb_color = "purple",
    natural_key_color = "white",
    accidental_key_color = "black",
    key_opacity = 0.75
) {
    e = 0.0145;
    plot = PCB_BUTTONS[1][0] - PCB_BUTTONS[0][0];

    natural_key_width = plot * 2 - key_gutter;
    natural_key_length = natural_key_width * 4;

    mount_width= get_keys_total_width(
        count = keys_count,
        starting_note_index =
            get_starting_note_index(starting_natural_key_index),
        natural_width = natural_key_width,
        gutter = key_gutter
    );
    mount_height = BUTTON_HEIGHT;

    key_mount_end_on_pcb = PCB_HOLES[2][1] + mount_length / 2;

    mount_hole_x_offset = (PCB_WIDTH / 15) - PCB_HOLES[2][0] - key_gutter / 2;
    mount_hole_xs = [
        PCB_HOLES[2][0] + mount_hole_x_offset,
        PCB_HOLES[3][0] + mount_hole_x_offset,
        PCB_HOLES[4][0] + mount_hole_x_offset,
    ];

    keys_y_over_pcb = natural_key_length - key_mount_end_on_pcb;

    keys_from_pcb_x_offset = PCB_BUTTONS[0][0] - plot + key_gutter / 2;

    pcb_x = enclosure_wall + enclosure_to_component_gutter -
        keys_from_pcb_x_offset;
    pcb_y = enclosure_wall + enclosure_to_component_gutter + keys_y_over_pcb;
    pcb_z = enclosure_wall + max(
        MOUNT_STILT_MINIMUM_HEIGHT,
        SPEAKER_HEIGHT + SPEAKER_CLEARANCE
    );
    pcb_stilt_height = pcb_z - enclosure_wall;

    enclosure_width = enclosure_wall * 2 + enclosure_to_component_gutter * 2
        + mount_width;
    enclosure_length = enclosure_wall * 2 + enclosure_to_component_gutter * 2
        + PCB_LENGTH + keys_y_over_pcb;
    enclosure_height = enclosure_wall * 2
        + pcb_stilt_height
        + PCB_HEIGHT + PCB_COMPONENTS_HEIGHT
        + enclosure_to_component_z_clearance;

    key_height = enclosure_height - pcb_stilt_height - enclosure_wall
        - PCB_HEIGHT - mount_height + natural_key_exposed_height;

    speaker_corner_gutter = 15;
    speaker_x = SPEAKER_DIAMETER / 2 + speaker_corner_gutter;
    speaker_y = enclosure_length - SPEAKER_DIAMETER / 2 - speaker_corner_gutter;
    speaker_z = enclosure_wall;

    switch_x = 15;
    switch_y = 15;
    switch_z = SWITCH_BASE_HEIGHT + SWITCH_ACTUATOR_HEIGHT
        + bottom_component_clearance;

    echo("Enclosure dimensions", [enclosure_width, enclosure_length, enclosure_height]);

    module _mounting_rail(y, height_difference = 0) {
        translate([keys_from_pcb_x_offset, y, PCB_HEIGHT]) {
            # mounting_rail(
                width = mount_width,
                length = mount_length,
                height = mount_height - height_difference,
                hole_xs = mount_hole_xs,
                hole_diameter = 2
            );
        }
    }

    module _mounted_keys(
        include_natural = false,
        include_accidental = false
    ) {
        translate([
            keys_from_pcb_x_offset,
            key_mount_end_on_pcb - natural_key_length,
            PCB_HEIGHT + BUTTON_HEIGHT
        ]) {
            mounted_keys(
                count = keys_count,
                starting_natural_key_index = starting_natural_key_index,

                natural_width = natural_key_width,
                natural_length = natural_key_length,
                natural_height = key_height,

                accidental_width = 7.5,
                accidental_length = natural_key_length / 2,
                accidental_height = key_height + accidental_key_extra_height,

                gutter = key_gutter,

                mount_length = mount_length,
                mount_hole_xs = mount_hole_xs,

                include_natural = include_natural,
                include_accidental = include_accidental
            );
        }
    }

    module _enclosure() {
        module _enclosure_half(is_top) {
            enclosure_half(
                width = enclosure_width,
                length = enclosure_length,
                total_height = enclosure_height,

                wall = enclosure_wall,
                floor_ceiling = undef,

                add_lip = !is_top,
                remove_lip = is_top,

                include_hinge = true,
                include_hinge_parts = true,

                hinge_count = 2,
                include_clasp = true,
                just_hinge_parts = false,
                radius = enclosure_chamfer,
                tolerance = tolerance,

                $fn = enclosure_rounding
            );
        }

        module _bottom() {
            difference() {
                union() {
                    _enclosure_half(false);

                    exposure_height = switch_z - SWITCH_BASE_HEIGHT;

                    // Walls around switch
                    translate([
                        switch_x - SWITCH_ORIGIN.x - enclosure_inner_wall,
                        switch_y - SWITCH_ORIGIN.y - enclosure_inner_wall,
                        exposure_height - e
                    ]) {
                        cube([
                            SWITCH_BASE_WIDTH + enclosure_inner_wall * 2,
                            SWITCH_BASE_LENGTH + enclosure_inner_wall * 2,
                            SWITCH_BASE_HEIGHT + e
                        ]);
                    }

                    _switch_exposure(
                        xy_bleed = enclosure_inner_wall,
                        include_switch_cavity = false,
                        z_bleed = -e
                    );
                }

                _switch_exposure(
                    xy_bleed = 0,
                    include_switch_cavity = true,
                    z_bleed = e
                );
            }
        }

        module _top(window_cavity_gutter = 2) {
            module _keys_cavity(gutter = key_gutter) {
                translate([
                    enclosure_wall + enclosure_to_component_gutter - gutter,
                    enclosure_wall + enclosure_to_component_gutter - gutter,
                    enclosure_height - enclosure_wall - e
                ]) {
                    cube([
                        mount_width + gutter * 2,
                        natural_key_length + gutter * 2,
                        enclosure_wall + e * 2
                    ]);
                }
            }

            module _pcb_window_cavity(
                width = PCB_WIDTH - window_cavity_gutter * 2,
                length = PCB_LENGTH - key_mount_end_on_pcb -
                    window_cavity_gutter * 2
            ) {
                translate([
                    pcb_x + window_cavity_gutter,
                    pcb_y + key_mount_end_on_pcb + window_cavity_gutter,
                    enclosure_height - enclosure_wall - e
                ]) {
                    cube([width, length, enclosure_wall + e * 2]);
                }
            }

            difference() {
                translate([enclosure_width + e, e, enclosure_height]) {
                    rotate([180, 0, 180]) {
                        _enclosure_half(true);
                    }
                }
                _keys_cavity();
                _pcb_window_cavity();
            }
        }

        # _top();
        # _bottom();

        translate([pcb_x, pcb_y, pcb_z - e]) {
            mount_stilts(
                positions = PCB_HOLES,
                height = pcb_stilt_height,
                z = -pcb_stilt_height
            );
        }
    }

    module _battery() {
        available_length = pcb_y - enclosure_wall;
        required_length = BATTERY_LENGTH + tolerance * 2;

        assert(
            available_length > required_length,
            "Battery doesn't have enough space under keys"
        );

        translate([
            enclosure_width - BATTERY_WIDTH - enclosure_wall,
            enclosure_wall + tolerance,
            enclosure_wall
        ]) {
            battery();
        }
    }

    module _speaker() {
        assert(pcb_stilt_height > SPEAKER_HEIGHT, "Speaker doesn't fit");

        translate([speaker_x, speaker_y, speaker_z]) {
            speaker();
        }
    }

    module _switch() {
        translate([switch_x, switch_y, switch_z]) {
            mirror([0, 0, 1]) {
                switch();
            }
        }
    }

    module _switch_exposure(
        xy_bleed = 0,
        include_switch_cavity = true,
        z_bleed = 0
    ) {
        exposure_height = switch_z - SWITCH_BASE_HEIGHT;
        width_extension = exposure_height / 2;
        length_extension = exposure_height / 2;

        translate([
            switch_x - SWITCH_ORIGIN.x - width_extension - xy_bleed,
            switch_y - SWITCH_ORIGIN.y - length_extension - xy_bleed,
            -z_bleed
        ]) {
            flat_top_rectangular_pyramid(
                top_width = SWITCH_BASE_WIDTH + xy_bleed * 2,
                top_length = SWITCH_BASE_LENGTH + xy_bleed * 2,

                bottom_width = SWITCH_BASE_WIDTH + xy_bleed * 2
                    + width_extension * 2,
                bottom_length = SWITCH_BASE_LENGTH + xy_bleed * 2
                    + length_extension * 2,

                height = exposure_height + z_bleed * 2
            );
        }

        if (include_switch_cavity) {
            translate([
                switch_x - SWITCH_ORIGIN.x - tolerance,
                switch_y - SWITCH_ORIGIN.y - tolerance,
                exposure_height - z_bleed
            ]) {
                cube([
                    SWITCH_BASE_WIDTH + tolerance * 2,
                    SWITCH_BASE_LENGTH + tolerance * 2,
                    SWITCH_BASE_HEIGHT + z_bleed * 2
                ]);
            }
        }
    }

    _enclosure();

    translate([pcb_x, pcb_y, pcb_z]) {
        color(pcb_color) pcb(visualize_non_button_components = true);

        _mounting_rail(key_mount_end_on_pcb - mount_length);
        _mounting_rail(PCB_HOLES[5][1] - mount_length / 2, 1);

        color(natural_key_color, key_opacity)
            _mounted_keys(include_natural = true);
        color(accidental_key_color, key_opacity)
            _mounted_keys(include_accidental = true);
    }

    _battery();
    _speaker();
    _switch();
}

intersection() {
    assembly();
    /* translate([-20, -20, -20]) cube([35, 300, 100]); // switch */
}
