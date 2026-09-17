# Campaign artwork generation

Mode: built-in `image_gen.imagegen`. No CLI fallback or runtime image creation.

The following common style text was prepended to each final generation prompt:

> PNG image. 2D hand-drawn illustrative game art with a strong, readable silhouette and stylised proportions. Soft painterly atmosphere with bold simplified shapes, expressive ink-like outlines varied in thickness. Cohesive limited palette, soft gradients and subtle watercolour texture combined with flat graphic colour blocking. Gentle atmospheric ethereal glow. Whimsical fantasy with playful cartoon exaggeration, rounded appealing forms, slight organic asymmetry, minimal expressive faces. Soft matte tactile surfaces. Minimal to moderate shading. Charm and subtle darkness, storybook dreamlike world. Clean gameplay readability. Avoid photorealism and overly complex detail.

## assets/campaign/crimson-creatures.png

Production game sprite atlas, 1536x1024, precisely 3 columns by 2 rows of equal 512px cells. Flat solid pure chroma green #00ff00 backdrop for runtime keying. NO gradients or shadows in background. Six isolated creatures, each wholly inside own cell with at least 40px margin. Row1: small red dragon hatchling; basalt fire golem; orange fire elemental. Row2: magma sentinel miniboss; elder scarlet drake miniboss; crowned inferno dragon boss. Front three-quarter view, red black orange and gold creatures, absolutely no green within creatures. No text, no grid lines. All six full bodies entirely visible. Preserve soft hand drawn storybook style.

The delivered PNG already contains transparency, which is preserved. No chroma-key shader is needed or applied.

## assets/campaign/obsidian-creatures.png

NEW image, NOT previous fire creature sheet. Production game sprite atlas for OBSIDIAN OBELISK space enemies. 1536x1024 canvas precisely 3 columns x 2 rows equal cells. Transparent background. Six separate full-body creatures, centered in their respective cells with 40px margins, no text. Row1 left: black shrouded ghost with little pale face and trailing ragged cloak; middle: dark violet will-o-wisp, luminous lilac eyes and trailing smoky flame; right: small black hooded grim reaper with curved crescent scythe. Row2 left: miniboss towering spectral knight, black plate armor and violet sword; middle: miniboss ghost queen with dark flowing veil and crown; right: final boss cosmic Death sovereign, black winged cloak, crescent scythe and floating obsidian obelisk behind its head. Black charcoal dark purple palette with fine lavender silver edge lights to remain readable against space. Isolated sprites, no scene or background scenery.

The generated sheet's actual row gutter is at y=450; Godot atlas regions account for this.

## assets/campaign/volcanic-rock.png

Asset type: seamless square repeating ground texture for top-down CRIMSON CITADEL volcanic arena. 1024x1024 PNG. Entire image is only flat overhead volcanic basalt rock, dark warm charcoal and muted oxblood stone with sparse thin ember-red cracks. Low contrast quiet gameplay floor. Perfectly tileable on all four edges, consistent scale and lighting across entire surface, no border, no vignette, no central focus, no horizon, no creatures, no objects, no text, no perspective. Simplified softly painterly rock surface.

## assets/campaign/starfield.png

Asset: seamless repeating square starfield floor texture for a top-down fantasy arena in deep outer space. Entire 1024x1024 image dark near-black midnight indigo with sparse tiny soft silver and violet stars and extremely subtle smoky nebula texture. Calm low contrast, evenly distributed tiny stars, no large stars, no bright flares, no planets, no objects, no horizon, no text, no central glow, no border or vignette. Perfectly tileable on all four sides. Soft painterly storybook atmosphere. The texture must stay dark so black creatures with lilac edges are visible.
