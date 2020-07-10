/*
This script generates the motor-driven pieces for a 12-hour Ptolemaic clock utilizing an empty Prusament brand filament spool and box.

Clock license
    Prusament Ptolemaic Clock by Brandon Belvin is licensed under a Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.
    http://creativecommons.org/licenses/by-nc-sa/4.0/

Thanks to janssen86 on Thingiverse https://www.thingiverse.com/thing:1604369 and chrisspen on GitHub https://github.com/chrisspen/gears for the gear script and the English translation. It is included, in part, to generate the spur gears that drive this clock.

Gear Generator license
    Getriebe Bibliothek f&uuml;r OpenSCAD / Gears Library for OpenSCAD (https://www.thingiverse.com/thing:1604369) by janssen86 is licensed under the Creative Commons - Attribution - Non-Commercial - Share Alike license.
    http://creativecommons.org/licenses/by-nc-sa/3.0/
    
Clock Face Font
    MuseoModerno https://fonts.google.com/specimen/MuseoModerno
*/

// How many faces will be made for a circle
$fn = 400;

// General Variables
pi = 3.14159265359;
rad = 57.295779513;
clearance = 0.05;   // clearance between teeth

/*  Converts Radians to Degrees */
function grad(pressure_angle) = pressure_angle*rad;

/*  Converts Degrees to Radians */
function radian(pressure_angle) = pressure_angle/rad;

/*  Converts 2D Polar Coordinates to Cartesian
    Format: radius, phi; phi = Angle to x-Axis on xy-Plane */
function polar_to_cartesian(polvect) = [
    polvect[0]*cos(polvect[1]),  
    polvect[0]*sin(polvect[1])
];

/*  Circle Involutes-Function:
    Returns the Polar Coordinates of an Involute Circle
    r = Radius of the Base Circle
    rho = Rolling-angle in Degrees */
function ev(r,rho) = [
    r/cos(rho),
    grad(tan(rho)-radian(rho))
];

/*  Converts Spherical Coordinates to Cartesian
    Format: radius, theta, phi; theta = Angle to z-Axis, phi = Angle to x-Axis on xy-Plane */
function sphere_to_cartesian(vect) = [
    vect[0]*sin(vect[1])*cos(vect[2]),  
    vect[0]*sin(vect[1])*sin(vect[2]),
    vect[0]*cos(vect[1])
];


/*  Spur gear
    modul = Height of the Tooth Tip beyond the Pitch Circle
    tooth_number = Number of Gear Teeth
    width = tooth_width
    bore = Diameter of the Center Hole
    pressure_angle = Pressure Angle, Standard = 20° according to DIN 867. Should not exceed 45°.
    helix_angle = Helix Angle to the Axis of Rotation; 0° = Spur Teeth
    optimized = Create holes for Material-/Weight-Saving or Surface Enhancements where Geometry allows */
module spur_gear(modul, tooth_number, width, bore, pressure_angle = 20, helix_angle = 0, optimized = true) {

    // Dimension Calculations  
    d = modul * tooth_number;                                           // Pitch Circle Diameter
    r = d / 2;                                                      // Pitch Circle Radius
    alpha_spur = atan(tan(pressure_angle)/cos(helix_angle));// Helix Angle in Transverse Section
    db = d * cos(alpha_spur);                                      // Base Circle Diameter
    rb = db / 2;                                                    // Base Circle Radius
    da = (modul <1)? d + modul * 2.2 : d + modul * 2;               // Tip Diameter according to DIN 58400 or DIN 867
    ra = da / 2;                                                    // Tip Circle Radius
    c =  (tooth_number <3)? 0 : modul/6;                                // Tip Clearance
    df = d - 2 * (modul + c);                                       // Root Circle Diameter
    rf = df / 2;                                                    // Root Radius
    rho_ra = acos(rb/ra);                                           // Maximum Rolling Angle;
                                                                    // Involute begins on the Base Circle and ends at the Tip Circle
    rho_r = acos(rb/r);                                             // Rolling Angle at Pitch Circle;
                                                                    // Involute begins on the Base Circle and ends at the Tip Circle
    phi_r = grad(tan(rho_r)-radian(rho_r));                         // Angle to Point of Involute on Pitch Circle
    gamma = rad*width/(r*tan(90-helix_angle));               // Torsion Angle for Extrusion
    step = rho_ra/16;                                            // Involute is divided into 16 pieces
    tau = 360/tooth_number;                                             // Pitch Angle
    
    r_hole = (2*rf - bore)/8;                                    // Radius of Holes for Material-/Weight-Saving
    rm = bore/2+2*r_hole;                                        // Distance of the Axes of the Holes from the Main Axis
    z_hole = floor(2*pi*rm/(3*r_hole));                             // Number of Holes for Material-/Weight-Saving
    
    optimized = (optimized && r >= width*1.5 && d > 2*bore);    // is Optimization useful?

    // Drawing
    union(){
        rotate([0,0,-phi_r-90*(1-clearance)/tooth_number]){                     // Center Tooth on X-Axis;
                                                                        // Makes Alignment with other Gears easier

            linear_extrude(height = width, twist = gamma){
                difference(){
                    union(){
                        tooth_width = (180*(1-clearance))/tooth_number+2*phi_r;
                        circle(rf);                                     // Root Circle 
                        for (rot = [0:tau:360]){
                            rotate (rot){                               // Copy and Rotate "Number of Teeth"
                                polygon(concat(                         // Tooth
                                    [[0,0]],                            // Tooth Segment starts and ends at Origin
                                    [for (rho = [0:step:rho_ra])     // From zero Degrees (Base Circle)
                                                                        // To Maximum Involute Angle (Tip Circle)
                                        polar_to_cartesian(ev(rb,rho))],       // First Involute Flank

                                    [polar_to_cartesian(ev(rb,rho_ra))],       // Point of Involute on Tip Circle

                                    [for (rho = [rho_ra:-step:0])    // of Maximum Involute Angle (Tip Circle)
                                                                        // to zero Degrees (Base Circle)
                                        polar_to_cartesian([ev(rb,rho)[0], tooth_width-ev(rb,rho)[1]])]
                                                                        // Second Involute Flank
                                                                        // (180*(1-clearance)) instead of 180 Degrees,
                                                                        // to allow clearance of the Flanks
                                    )
                                );
                            }
                        }
                    }           
                    circle(r = rm+r_hole*1.49);                         // "bore"
                }
            }
        }
        // with Material Savings
        if (optimized) {
            linear_extrude(height = width){
                difference(){
                        circle(r = (bore+r_hole)/2);
                        circle(r = bore/2);                          // bore
                    }
                }
            linear_extrude(height = (width-r_hole/2 < width*2/3) ? width*2/3 : width-r_hole/2){
                difference(){
                    circle(r=rm+r_hole*1.51);
                    union(){
                        circle(r=(bore+r_hole)/2);
                        for (i = [0:1:z_hole]){
                            translate(sphere_to_cartesian([rm,90,i*360/z_hole]))
                                circle(r = r_hole);
                        }
                    }
                }
            }
        }
        // without Material Savings
        else {
            linear_extrude(height = width){
                difference(){
                    circle(r = rm+r_hole*1.51);
                    circle(r = bore/2);
                }
            }
        }
    }
}

// Begin Prusament Ptolemaic clock

module skate_bearing() {
    union() {
        color("silver") difference() {
            cylinder(7, 11, 11, center=false);
            translate([0,0,-1]) cylinder(9, 9.75, 9.75, center=false);
        }
        color("red") difference() {
            cylinder(7,9.75,9.75, center=false);
            translate([0,0,-1]) cylinder(9,5.5,5.5, center=false); 
        }
        color("silver") difference() {
            cylinder(7, 5.5, 5.5, center=false);
            translate([0,0,-1]) cylinder(9, 4, 4, center=false);
        }
    }
}


// These colors help when visualizing the gears - which gears mate with each other
mateColor1 = "red";
mateColor2 = "blue";
mateColor3 = "yellow";

motorStemBore = 8;

minuteGearBore = 3.2;
minuteGearDepth = 3;

gear1Teeth = 12;
gear2Teeth = 24;
gear3Teeth = 16;
gear4Teeth = 32;
gear5Teeth = 19;
gear6Teeth = 57;

motorGearMod = 2.3;
midGearMod = 2.2;
clockGearMod = 1.9;

module base_plate() {
    // Mounting plate
    difference() {
        union() {
            difference() {
                cube([200,80,3], center=false);
                
                translate([-1,3,-1]) cube([36,90,5], center=false);
                
                translate([34,60,-1]) cube([20,30,5], center=false);
                
                translate([155,3,-1]) cube([100,90,5], center=false);
                
                translate([135,60,-1]) cube([21,30,5], center=false);
            }
            
            translate([55, 60, 0]) cylinder(3, 20, 20, center=false);
            translate([135, 60, 0]) cylinder(3, 20, 20, center=false);
        }
        
        // Clock motor hole
        translate([136.45,58.8,-1]) cylinder(10, 4, 4, center=false);
    }
    
    difference() {
        translate([31, 6, 0]) cube([4, 4, 3], center=false);
        translate([31, 10, -1]) cylinder(5, 4, 4, center=false);
    }
    
    difference() {
        translate([155, 6, 0]) cube([4, 4, 3], center=false);
        translate([159, 10, -1]) cylinder(5, 4, 4, center=false);
    }
    
    // Base
    difference() {
        union() {
            cube([200,6,40], center=false);
            
            // Keylock feet
            translate([135.1,0,40]) cube([14.8,3,8], center=false);
            translate([142.5,0,47.9]) rotate([-90,0,0]) cylinder(3,7.4,7.4, center=false);
        }
        
        // Keylock feet
        translate([50,-1,24]) cube([15,4,17], center=false);
        translate([57.5,-1,24]) rotate([-90,0,0]) cylinder(4,7.5,7.5, center=false);
    }
    
    // First post
    translate([97.75,73, 0]) {
        cylinder(12,5,5, center=false);
        difference() {
            union() {
                cylinder(26.5,3.8,3.8, center=false);
                difference() {
                    difference() {
                        translate([0,0,24.5]) cylinder(2,4.5,3.8, center=false);
                        translate([-5,1.5,24]) cube([10,10,10], center=false);
                    }
                    translate([-5,-11.5,24]) cube([10,10,10], center=false);
                }
            }
            translate([-0.5,-5,20]) cube([1,20,20], center = false);
        }
    }
    
    // Second post
    translate([51.3,48.4, 0]) {
        cylinder(20,5,5, center=false);
        difference() {
            union() {
                cylinder(42.5,3.8,3.8, center=false);
                difference() {
                    difference() {
                        translate([0,0,40.5]) cylinder(2,4.5,3.8, center=false);
                        translate([-5,1.5,38]) cube([10,10,10], center=false);
                    }
                    translate([-5,-11.5,38]) cube([10,10,10], center=false);
                }
            }
            translate([-0.5,-5,34]) cube([1,20,20], center = false);
        }
    }
}

module friction_reducer(hand = false) {
    // Base
    difference() {
        union() {
            cube([200,6,18], center=false);
            
            // Keylock feet
            translate([135.1,0,16]) cube([14.8,3,17], center=false);
            translate([142.5,0,33.9]) rotate([-90,0,0]) cylinder(3,7.4,7.4, center=false);
        }
        
        // Keylock feet
        translate([50,-1,10]) cube([15,4,9], center=false);
        translate([57.5,-1,10]) rotate([-90,0,0]) cylinder(4,7.5,7.5, center=false);
    }
    
    // Mounting plate
    difference() {
        union() {
            translate([57,3,0]) cube([86,40,3], center=false);
            difference() {
                translate([100,101.25,0]) {
                    difference() {
                        cylinder(3,68.5,68.5, center=false);
                        translate([0,0,-1]) cylinder(5,52.34,52.34, center=false);
                    }
                }
                translate([75,41.25,-1]) cube([50,18,5], center=false);
            }
            
            translate([70,43.25,0]) cylinder(3,13,13,center=false);
            translate([130,43.25,0]) cylinder(3,13,13,center=false);
        }
            
        translate([83,40,-1]) cube([34,18,5], center=false);
        translate([100,40,-1]) cylinder(5,17,17,center=false);
    }
    
    // Base curves
    difference() {
        translate([53,6,0]) cube([4,4,3], center=false);
        translate([53,10,-1]) cylinder(5, 4, 4, center=false);
    }
    
    difference() {
        translate([143,6,0]) cube([4,4,3], center=false);
        translate([147,10,-1]) cylinder(5,4,4, center=false);
    }

    
    // Posts
    translate([70,49.45,3]) cylinder(8,4,4,center=false);
    translate([130,49.45,3]) cylinder(8,4,4,center=false);
    translate([52.5,138.45,3]) cylinder(8,4,4,center=false);
    translate([147.5,138.45,3]) cylinder(8,4,4,center=false);
    
    // Hand
    if (hand) {
        difference() {
            union() {
                translate([95,161,0]) cube([10,40,3], center=false);
                translate([95,201,0]) rotate([0,0,0]) linear_extrude(height=3, center=false) polygon([[0,0], [10,0], [5,12]]);
            }
            translate([99.5,199,-1]) cube([1,5,5], center=false);
        }
    }
}

module clock_motor_gear() {
    rotate([0,0,9.2]) color(mateColor1) spur_gear (modul=motorGearMod, tooth_number=gear1Teeth, width=minuteGearDepth, bore=minuteGearBore, pressure_angle=20, helix_angle=0, optimized=false);
}

module middle_gear() {
    rotate([0,0,32.7]) color(mateColor1) spur_gear (modul=motorGearMod, tooth_number=gear2Teeth, width=5, bore=8,
        pressure_angle=20, helix_angle=0, optimized=false);
    rotate([0,0,5]) color(mateColor2) translate([0,0,5]) {
        spur_gear (modul=midGearMod, tooth_number=gear3Teeth, width=7, bore=8,
            pressure_angle=20, helix_angle=0, optimized=false);
    }
}


module last_gear() {
    rotate([0,0,0]) color(mateColor2) spur_gear (modul=midGearMod, tooth_number=gear4Teeth, width=8, bore=8,
        pressure_angle=20, helix_angle=0, optimized=false);
    rotate([0,0,0.5]) color(mateColor3) translate([0,0,8]) {
        spur_gear (modul=clockGearMod, tooth_number=gear5Teeth, width=12, bore=8,
            pressure_angle=20, helix_angle=0, optimized=false);
    }
}


module spindle_gear(box = false) {
    rotate([0,0,0]) spur_gear (modul=clockGearMod, tooth_number=gear6Teeth, width=12, bore=94.6, pressure_angle=20, helix_angle=0, optimized=false);
    difference() {
        if (box) {
            cylinder(26.75,49,49, center=false);
        } else {
            cylinder(23.75,49,49, center=false);
        }
        translate([0,0,-1]) cylinder(30,47.3,47.3, center=false);
    }
}

faceDepth=1;
numberDepth=faceDepth - 0.4;

module clock_number(number, offset) {
    angle = (number % 12) * -30;
    
    rotate([0,0,angle]) translate([offset,75,numberDepth]) linear_extrude(height=faceDepth, center=false) text(text=str(number), size=15, font="MuseoModerno:style=Bold");
}

module clock_face() {
    difference() {
        union() {
            // Outer ring
            difference() {
                cylinder(faceDepth,98.5,98.5, center=false);
                translate([0,0,-1]) cylinder(5,94,94, center=false);
            }
            
            // Clock circles
            for (rot = [0:30:360]) {
                rotate([0,0,rot]) translate([0,82.5,0]) cylinder(faceDepth,15,15,center=false);
            }
        }
        
        // Clock ticks
        for (rot = [0:7.5:360]){
            rotate([0,0,rot]) translate([-0.4,96.2,numberDepth]) cube([0.8,9,faceDepth], center=false);
        }
        
        clock_number(12, -10.75);
        clock_number(1, -5);
        clock_number(2, -6);
        clock_number(3, -6);
        clock_number(4, -7);
        clock_number(5, -5.5);
        clock_number(6, -6.75);
        clock_number(7, -5.25);
        clock_number(8, -7);
        clock_number(9, -7);
        clock_number(10, -11.25);
        clock_number(11, -10);
    }
}

module hand() {
    cube([10,12,2], center=false);
    
    // Pointer
    cube([10,1,8], center=false);
    translate([0,1,8]) rotate([90,0,0]) linear_extrude(height=1, center=false) polygon([[0,0], [10,0], [5,9]]);
    
    // Spike
    translate([5,10,0]) cylinder(4,1.25,1.25, center=false);
    translate([5,10,4]) cylinder(2,1.25,0, center=false);
}
module clock_motor() {
    color("gray") cube([56,56,16], center=false);
    translate([28,28,16]) color("gold") cylinder(10, 4, 4, center=false);
    translate([28,28,26]) color("white") cylinder(3, 2.5, 2.5, center=false);
    translate([28,28,29]) color("white") cylinder(3, 1.6, 1.6, center=false);
}

module modeling(box = false, step = 0) {
    // Base plate
    color("orange") translate([0,0,16]) {
        base_plate();
    }
    
    // Clock gear friction reducer
    color("green") translate([200,0,74]) rotate([0,180,0]) {
        friction_reducer(hand = !box);
    }
    
    // Bottom Bearings
    translate([70,49.45,63.5]) skate_bearing();
    translate([130,49.45,63.5]) skate_bearing();
    
    // Top Bearings
    translate([52.5,138.45,63.5]) skate_bearing();
    translate([147.5,138.45,63.5]) skate_bearing();
    
    // Clock motor
    translate([108.45,30.8,0]) {
        clock_motor();
    }
    
    // First gear
    translate([136.45,58.8,29]) {
        rotate([0, 0, -6*step]) clock_motor_gear();
    }
    
    // Second gear
    translate([97.75,73,28]) {
        rotate([0, 0, 3*step]) middle_gear();
    }
    
    // Third gear
    translate([51.3,48.4,36]) {
        rotate([0, 0, -1.5*step]) last_gear();
    }
    
    // Clock gear
    color(mateColor3) translate([100,101.5,50.25]) {
        rotate([0, 0, 0.5*step]) spindle_gear(box);
    }
    
    // Clock face
    clockFaceDepth = box ? 87 : 84;
    translate([100,101.5,clockFaceDepth]) rotate([0, 0, 0.5*step]) clock_face();
    
    if (box) {        
        // Pointer hand
        translate([105,217,84]) rotate([90,180,0]) hand();
    }
}

module print(box = false) {
    base_plate();
    
    translate([0,100,0]) friction_reducer(hand = !box);
    
    translate([180,135,0]) clock_motor_gear();
    
    translate([220,200,0]) middle_gear();
    
    translate([285,160,0]) last_gear();
    
    translate([250,60,0]) spindle_gear(box);
    
    translate([420,100,0]) clock_face();
    
    if (box) {
        translate([315,20,0]) hand();
    }
}

module animate(time) {    
    modeling(box=true, step = time * 720);
}

// Animation
//$vpt = [102.73, 109.28, 70.94];
//$vpd = 760;
//$vpr = [355, -45 + 360 * $t, 0];
//animate($t);

//modeling(box=true);
//print(box=true);

modeling(box=false);
//print(box=false);