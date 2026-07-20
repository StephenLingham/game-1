# Project verification notes

When adding or changing textures, fonts, generated artwork, visual effects, or nodes that own rendering resources:

- Do not rely only on headless import or parser checks.
- Run the project with the real GLES3 Compatibility renderer and verbose logging.
- Exercise the affected lifecycle, including spawning the visual, changing scenes or freeing its owner, and exiting the process normally.
- Check the complete shutdown log for leaked texture RIDs, CanvasItem RIDs, font RIDs, ObjectDB instances, orphan nodes, and resource-loading warnings.
- Load project images through Godot's imported resource system (`load()` or `preload()` as `Texture2D`). Avoid `Image.load_from_file()` plus `ImageTexture.create_from_image()` unless runtime texture creation is genuinely required and its ownership and cleanup are explicitly tested.
- For dynamically created visual nodes, verify that their parent owns them or that every timer/tween completion path frees them safely.
- Treat any shutdown leak warning as a failed verification, even when gameplay appears correct.
