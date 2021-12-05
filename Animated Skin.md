# Using Animated Skin in v++
![image](https://user-images.githubusercontent.com/16228717/144766353-6c211657-f893-440e-8341-ab87f7d414e7.png)
### Only works in v++ 2.1 and up
- Top left pixel of skin is control pixel, alpha doesn't actually need to be 255, but if it's not it may affect rgb values when saving to minecraft.net
- If control pixel has alpha of 0 skin is shown as normal without animation
- R and G values (out of 255) control duration in centiseconds (0.1 sec) of each frame, max is 25.5 seconds
- B value used to set interpolation. If not 0 the animation will be interpolated
- First frame is what would normally show as player skin
- Second frame is stored in what normally is unused space on the skin texture