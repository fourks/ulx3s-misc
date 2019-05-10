# Mouse from Minimig and Oberon

Toplevel parameter selects either minimig or oberon mouse core
at compile time. I don't know about compatibilty but oberon 
source is shorter, simpler and has slightly more reliable mouse
initialization.

After mouse re-plug, reset must be pressed for both cores to
get mouse working again.

Move mouse pointer (crosshair) over the screen.
Left click to draw random color block.
Right click to erase color block (to black).

Works correctly if compiled with diamond.

If compiled with trellis, it kinda works but
shows some some circuit-bending on screen.

Microsoft IntelliMouse Optical USB/PS2

    X/Y movement works.
    Left and Right mouse button clicks works.
    Other buttons don't work.

Logitech Wheel Mouse M-BT58 USB/PS2

    X/Y movement works.
    Left, Right button clicks and Wheel press (aka middle button) work.

Wheel rotation is not supported yet.

The initialization procedure is not very plug-n-play.
Here's a manual procedure that gets it working:

    0. plug mouse out
    1. upload this bitstream
    2. click btn0 to reset
    3. plug mouse in
    4. click btn0 to reset
    5. click mouse left/right buttons and move mouse, LEDs will show it