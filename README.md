## Text based player portrait

A minecraft vanilla shader that lets you to create a 3d view of a player using the 1.21.9 `Player Object` text component type.

Credits to [JNNGL](https://github.com/JNNGL) and [Origin Realms](https://originrealms.com/) for the original portrait shader code inspiration. You can find JNNGL's shader [here](https://github.com/JNNGL/vanilla-shaders/tree/main/gui_player_models_base)

### Usage
`/title @s title {"type":"object","object":"player",player:{name:"cosrnic"},hat:true,color:"#010000",shadow_color:0}`

### Implementing
Copy the [assets/minecraft/shaders/include/portrait.glsl](./assets/minecraft/shaders/include/portrait.glsl) into your resource pack.
> [!IMPORTANT]
> This must be included after the Sampler0 is defined!
> You must also have `#moj_import <minecraft:globals.glsl>` for GameTime

Include it in your `.fsh` shader with `#moj_import <minecraft:portrait.glsl>`.
Detect it using any method you want and run inside of the if statement.
```glsl
fragColor = portraitRender(texCoord0, 68./70., GameTime);
if (fragColor.a < .1) discard;
fragColor.a = vertexColor.a; // keeps the transparency for when text fades
return;
```

To scale up the text, inside of your vsh shader, multiply the `corners2[gl_VertexID % 4]` by an amount

An example is in [assets/minecraft/shaders/core/](./assets/minecraft/shaders/core/)
