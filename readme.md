

# Animated Voronoi Shader

A godot shader material that draws a [voronoi](https://en.wikipedia.org/wiki/Voronoi_diagram)
pattern on a surface using a fragment shader.

The code has two parts - voronoi.shader which runs on the GPU and voronoi_driver.gd, which runs
on the CPU.

Each frame, voronoi_driver updates the position of 100 points, encodes them in a texture, and
passes that texture the voronoi.shader as a uniform.

Voronoi.shader uses the set of points in a fragment shader to decide what color a given pixel should
be. If the pixel is on the edge between two points (within a margin of error), it draws the 'edge'
color. Otherwise, it draws the color of the nearest point to the pixel.
