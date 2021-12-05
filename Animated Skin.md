# Using Animated Skin in v++

![image](https://user-images.githubusercontent.com/16228717/144767048-5218a7b7-e24e-4878-8593-8330b4f874e3.png)

### Only works in v++ 2.1 and up
- Top left pixel of skin is control pixel, alpha needs to be 254 to enable skin animation
- R and G values (out of 255) control duration in centiseconds (0.1 sec) of each frame, max is 25.5 seconds
- B value used to set interpolation. If not 0 the animation will be interpolated
- First frame is what would normally show as player skin
- Second frame is stored in what normally is unused space on the skin texture
