// openscad_pvc_customizer.scad
// Customizer front-end for openscad_pvc.scad: open this file in OpenSCAD and use
// Window > Customizer to pick a part, schedule, size, and end types - no code needed.
// It only calls the library's existing part modules. It lives in its own file because
// openscad_pvc.scad is meant to be include<>'d, and include<> would also pull in any
// top-level geometry and Customizer variables, adding them to every project that uses it.
// Requires BOSL2 and object_common_functions.scad in your OpenSCAD library path, as the
// library itself does.

include <openscad_pvc.scad>

/* [Part] */

// Which PVC part to model
part = "elbow"; // [pipe, elbow, tee, wye, corner, side_outlet_tee, cross, six_way_joint, coupling, cap, plug, adapter, bushing, nipple, flange]

// PVC schedule (wall weight / pressure class)
schedule = 40; // [40, 80, 120]

// Nominal pipe size (schedule 120 starts at 1/2 in)
dn = "DN20"; // [DN8:1/8in, DN12:1/4in, DN10:3/8in, DN15:1/2in, DN20:3/4in, DN25:1in, DN32:1-1/4in, DN40:1-1/2in, DN50:2in, DN65:2-1/2in, DN80:3in, DN90:3-1/2in, DN100:4in, DN125:5in, DN150:6in, DN200:8in, DN250:10in, DN300:12in, DN350:14in, DN400:16in, DN450:18in, DN500:20in, DN600:24in]

/* [End Types] */
// "auto" uses the part's own default (sockets for fittings, spigots for pipe).
// Parts only use as many ends as they have: A-B for 2-ended parts, A-C for tee/wye/corner, A-D for cross/side-outlet tee, A-F for six-way. Nipples ignore these.
// Caps allow only socket/fipt; plugs only spigot/ispigot/mipt; bushings need A = socket/fipt (small side), B = spigot/mipt (large side).

// Which end is where varies by part - check the preview after changing one.

// End A (main run / the only end for caps and plugs)
end_A = "auto"; // [auto, socket, spigot, ispigot, mipt, fipt]
// End B (main run)
end_B = "auto"; // [auto, socket, spigot, ispigot, mipt, fipt]
// End C (first branch)
end_C = "auto"; // [auto, socket, spigot, ispigot, mipt, fipt]
// End D
end_D = "auto"; // [auto, socket, spigot, ispigot, mipt, fipt]
// End E
end_E = "auto"; // [auto, socket, spigot, ispigot, mipt, fipt]
// End F
end_F = "auto"; // [auto, socket, spigot, ispigot, mipt, fipt]

/* [Part Options] */

// Pipe length (pipe only, mm)
pipe_length = 50; // [5:1:1000]

// Bend angle (elbow only, degrees)
elbow_angle = 90; // [5:5:180]

// Bend radius from the pivot to the pipe centerline; -1 = library default (half the pipe OD), 0 = L-shaped elbow (elbow only, mm)
elbow_bend_radius = -1; // [-1:0.5:100]

// Extra straight length added to every arm of a fitting (elbow, tee, wye, corner, crosses, six-way, coupling, cap; mm)
arm_extension = 0; // [0:1:300]

// Number of bolt holes (flange only)
flange_mounts = 4; // [0:1:16]

// Bolt hole diameter, 0 = largest safe size (flange only, mm)
flange_mount_diam = 0; // [0:0.5:40]

/* [Second Size (adapter & bushing)] */

// Schedule of the second pipe
schedule2 = 40; // [40, 80, 120]

// Nominal size of the second pipe. Bushings need two sizes that nest (the small OD must fit inside the large ID).
dn2 = "DN10"; // [DN8:1/8in, DN12:1/4in, DN10:3/8in, DN15:1/2in, DN20:3/4in, DN25:1in, DN32:1-1/4in, DN40:1-1/2in, DN50:2in, DN65:2-1/2in, DN80:3in, DN90:3-1/2in, DN100:4in, DN125:5in, DN150:6in, DN200:8in, DN250:10in, DN300:12in, DN350:14in, DN400:16in, DN450:18in, DN500:20in, DN600:24in]

/* [Advanced] */

// Use each size's real thread length & pitch from the spec table. Off = library default (10mm thread length for every size).
use_spec_threads = false;

// Anchor the part's bottom at z=0 instead of centering it (approximate for elbow/corner: may dip ~1mm below)
place_on_bed = false;

// Circle resolution for final render (preview uses 1/4 of this)
render_fn = 96; // [24:8:240]

/* [Hidden] */

$fn = $preview ? render_fn / 4 : render_fn;

// Number of ends each part type takes
function cz_end_count(p) =
    in_list(p, ["cap", "plug"]) ? 1 :
    in_list(p, ["tee", "wye", "corner"]) ? 3 :
    in_list(p, ["cross", "side_outlet_tee"]) ? 4 :
    p == "six_way_joint" ? 6 :
    2;

// Raw spec table row for a schedule/DN pair, or undef if none
function cz_raw_row(sched, d) = let(rows = [for (r = _PVC_specs_raw) if (r[0] == sched && r[4] == d) r])
    len(rows) > 0 ? rows[0] : undef;

// Spec lookup with a friendly error, optionally pulling real thread length/pitch from the table
function cz_spec(sched, d) =
    let(row = cz_raw_row(sched, d))
    assert(!is_undef(row),
           str("Size ", d, " doesn't exist in schedule ", sched, ". Available: ",
               [for (r = _PVC_specs_raw) if (r[0] == sched) r[4]]))
    let(base = pvc_spec_lookup(sched, dn = d))
    (use_spec_threads && is_num(row[5]) && row[5] > 0 && is_num(row[6]) && row[6] > 0)
        ? PVC(["tl", row[5], "pitch", row[6]], mutate = base)
        : base;

pvc = cz_spec(schedule, dn);
pvc2 = in_list(part, ["adapter", "bushing"]) ? cz_spec(schedule2, dn2) : undef;

all_ends = [end_A, end_B, end_C, end_D, end_E, end_F];
ends = [for (i = [0:cz_end_count(part) - 1]) all_ends[i] == "auto" ? undef : all_ends[i]];

anchor = place_on_bed ? BOTTOM : CENTER;

echo(str("PART: ", part, "  schedule ", schedule, " ", pvc_name(pvc), "in (", dn, ")  OD=", pvc_od(pvc),
         "mm  wall=", pvc_wall(pvc), "mm  thread len=", pvc_tl(pvc), "mm  pitch=", pvc_pitch(pvc), "mm"));

if (part == "pipe")            pvc_pipe(pvc, pipe_length, ends = ends, anchor = anchor);
if (part == "elbow")           pvc_elbow(pvc, elbow_angle, ends = ends, anchor = anchor,
                                         bend_radius = elbow_bend_radius < 0 ? undef : elbow_bend_radius, extend = arm_extension);
if (part == "tee")             pvc_tee(pvc, ends = ends, anchor = anchor, extend = arm_extension);
if (part == "wye")             pvc_wye(pvc, ends = ends, anchor = anchor, extend = arm_extension);
if (part == "corner")          pvc_corner(pvc, ends = ends, anchor = anchor, extend = arm_extension);
if (part == "side_outlet_tee") pvc_side_outlet_tee(pvc, ends = ends, anchor = anchor, extend = arm_extension);
if (part == "cross")           pvc_cross(pvc, ends = ends, anchor = anchor, extend = arm_extension);
if (part == "six_way_joint")   pvc_six_way_joint(pvc, ends = ends, anchor = anchor, extend = arm_extension);
if (part == "coupling")        pvc_coupling(pvc, ends = ends, anchor = anchor, extend = arm_extension);
if (part == "cap")             pvc_cap(pvc, ends = ends, anchor = anchor, extend = arm_extension);
if (part == "plug")            pvc_plug(pvc, ends = ends, anchor = anchor);
if (part == "adapter")         pvc_adapter(pvc, pvc2, ends = ends, anchor = anchor);
if (part == "bushing")         pvc_bushing(pvc, pvc2, ends = ends, anchor = anchor);
if (part == "nipple")          pvc_nipple(pvc, anchor = anchor);
if (part == "flange")          pvc_flange(pvc, ends = ends, mounts = flange_mounts, mount_diam = flange_mount_diam,
                                          anchor = anchor);
