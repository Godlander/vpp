# Using Animated Skin in v++

![image](https://user-images.githubusercontent.com/16228717/144769111-1c8a8a03-cba8-4181-90c2-124b877780e5.png)

### Only works in v++ 2.1 and up
- Top middle right pixel (32, 0) of skin is control pixel, alpha needs to be 234 to enable skin animation
- R and G values (out of 255) control duration in centiseconds (0.1 sec) of each frame, max is 25.5 seconds
- B value used to set interpolation. If not 0 the animation will be interpolated
- First frame is what would normally show as player skin
- Second frame is stored in what normally is unused space on the skin texture

[this tool](https://jsfiddle.net/Godlander/5sen7Lw1/137/) can be used to generate the control pixel with an input skin.
