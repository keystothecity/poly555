include <values.scad>;

use <basic_shapes.scad>;
use <utils.scad>;

module keys(
    count,
    starting_natural_key_index = 0,

    natural_width,
    natural_length,
    natural_height,

    accidental_width,
    accidental_length,
    accidental_height,

    front_chamfer = 2,

    gutter = 1,

    undercarriage_height = 0,
    undercarriage_length = 0,

    cantilever_length = 0,
    cantilever_height = 0,

    include_natural = true,
    include_accidental = true,
    include_cantilevers = true
) {
    e = 0.04567;

    index_offset = [0,2,4,5,7,9,11][starting_natural_key_index];
    cantilver_width = min(
        accidental_width,
        natural_width - ((accidental_width - gutter) / 2) * 2 - gutter * 2
    );

    module _key_block(dimensions) {
        difference() {
            if (front_chamfer > 0) {
                width = dimensions[0];
                length = dimensions[1];
                height = dimensions[2];

                hull() {
                    for (position = [
                        [0, 0, 0],
                        [width - e, 0, 0],
                        [width - e, length - e, 0],
                        [0, length - e, 0],
                        [width - e, length - e, height - e],
                        [0, length - e, height - e],
                    ]) {
                        translate(position) {
                            cube([e, e, e]);
                        }
                    }

                    translate([0, front_chamfer, height - front_chamfer]) {
                        rotate([0, 90, 0]) {
                            cylinder(
                                r = front_chamfer,
                                h = width
                            );
                        }
                    }
                }
            } else {
                cube(dimensions);
            }

            /* TODO: DFM */
            if (undercarriage_height > 0 && undercarriage_length > 0) {
                translate([-e, -e, -e]) {
                    cube([
                        dimensions[0] + e * 2,
                        dimensions[1] - undercarriage_length + e,
                        undercarriage_height + e
                    ]);
                }
            }
        }

        if (include_cantilevers) {
             translate([
                 (dimensions[0] - cantilver_width) / 2,
                 dimensions[1] - e,
                 0
             ]) {
                 /* TODO: this is okay but could be more stable by widening
                 where it joins mounting rail */
                 cube([
                     cantilver_width,
                     cantilever_length + e * 2,
                     cantilever_height
                 ]);
             }
        }
    }

    module _cutout(right = true) {
        // Exact size doesn't matter. Just needs to be big and defined.
        width = max(natural_width, accidental_width);

        length = accidental_length + gutter + e;

        // TODO: derive
        front_clearance = (accidental_height - natural_height) / 2;

        translate([
            right
                ? natural_width - (accidental_width - gutter) / 2 - gutter
                : width * -1 + (accidental_width - gutter) / 2
                    + gutter,
            natural_length - accidental_length - gutter,
            -e
        ]) {
            flat_top_rectangular_pyramid(
                top_width = width,
                top_length = length + front_clearance,
                bottom_width = width,
                bottom_length = length,
                height = natural_height + (e * 2),
                top_weight_y = 1
            );
        }
    }

    module _natural(i, x, note_in_octave_index, natural_index) {
        cutLeft = (
            (note_in_octave_index != 0 && note_in_octave_index != 5) &&
            i != 0
        );
        cutRight = (
            (note_in_octave_index != 4 && note_in_octave_index != 11) &&
            i != count - 1
        );

        translate([x, 0, 0]) {
            difference() {
                _key_block([
                    natural_width,
                    natural_length,
                    natural_height
                ]);

                if (cutLeft) {
                    _cutout(right = false);
                }

                if (cutRight) {
                    _cutout(right = true);
                }
            }
        }
    }

    module _accidental(i, x, note_in_octave_index, natural_index) {
        y = natural_length - accidental_length;

        translate([x, y, 0]) {
            _key_block([
                accidental_width,
                accidental_length,
                accidental_height
            ]);
        }
    }

    for (i = [0 : count - 1]) {
        adjusted_i = (i + index_offset);
        note_in_octave_index = adjusted_i % 12;
        natural_index = round(adjusted_i * (7 / 12));
        is_natural = len(search(note_in_octave_index, [1,3,6,8,10])) == 0;
        is_accidental = !is_natural;

        if (is_natural && include_natural) {
            x = (natural_width + gutter) * (natural_index - starting_natural_key_index);
            _natural(i, x, note_in_octave_index, natural_index);
        }

        if (is_accidental && include_accidental) {
            x = (natural_index - starting_natural_key_index) * (natural_width + gutter)
                 - (gutter / 2) - (accidental_width / 2);
            _accidental(i, x, note_in_octave_index, natural_index);
        }
    }
}

module mounted_keys(
    count,
    starting_natural_key_index = 0,

    natural_width,
    natural_length,
    natural_height,

    accidental_width,
    accidental_length,
    accidental_height,

    front_chamfer = 2,

    gutter = 1,

    undercarriage_height = 0,
    undercarriage_length = 0,

    include_natural = true,
    include_accidental = true,
    include_cantilevers = true,

    mount_length = 0,
    mount_height = 1,
    mount_hole_xs = [],
    mount_hole_diameter = PCB_MOUNT_HOLE_DIAMETER,
    mount_screw_head_diameter = SCREW_HEAD_DIAMETER,

    cantilever_length = 0,
    cantilever_height = 0
) {
    $fn = 24;
    e = 0.0678;

    mount_width = get_keys_total_width(
        count = count,
        starting_note_index = get_starting_note_index(starting_natural_key_index),
        natural_width = natural_width,
        gutter = gutter
    );

    module _keys(naturals = true) {
        keys(
            count = count,
            starting_natural_key_index = starting_natural_key_index,

            natural_width = natural_width,
            natural_length = natural_length,
            natural_height = natural_height,

            accidental_width = accidental_width,
            accidental_length = accidental_length,
            accidental_height = accidental_height,

            front_chamfer = front_chamfer,

            gutter = gutter,

            undercarriage_height = undercarriage_height,
            undercarriage_length = undercarriage_length,

            include_natural = naturals,
            include_accidental = !naturals,
            include_cantilevers = include_cantilevers,

            cantilever_length = cantilever_length,
            cantilever_height = cantilever_height
        );
    }

    difference() {
        union() {
            if (include_natural) { _keys(true); }
            if (include_accidental) { _keys(false); }

            translate([0, natural_length + cantilever_length, 0]) {
                cube([mount_width, mount_length, mount_height]);
            }
        }

        hole_array(
            mount_hole_xs,
            mount_hole_diameter,
            accidental_height + e * 2,
            natural_length + cantilever_length + mount_length / 2,
            -e
        );
    }
}

mounted_keys(
    count = 13,
    starting_natural_key_index = 3,

    natural_length = 20,
    natural_width = 10,
    natural_height = 10,

    accidental_width = 7.5,
    accidental_length = 10,
    accidental_height = 15,

    front_chamfer = 2,

    gutter = 1,

    undercarriage_height = 5,
    undercarriage_length = 15,

    mount_length = 5,
    mount_height = 2,
    mount_hole_diameter = 2,
    mount_screw_head_diameter = 4,
    mount_hole_xs = [5, 30, 40, 65, 82],

    cantilever_length = 2,
    cantilever_height = 2
);
